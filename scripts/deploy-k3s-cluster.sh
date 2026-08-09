#!/bin/bash
set -e

# Lấy đường dẫn tuyệt đối của thư mục chứa script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Cấu hình sau khi cài đặt k3s
PEM_FILE="/home/ichi/demoDevOps/ecommerce-microservices/infrastructure/terraform/ecommerce-ssh-key"
ISTIO_DIR="/home/ichi/demoDevOps/ecommerce-microservices/infrastructure/istio-1.23.0"

# Lấy thông tin
echo "======================================================="
echo "LẤY THÔNG TIN MASTER NODE TỪ TERRAFORM"
echo "======================================================="

cd "$SCRIPT_DIR/../infrastructure/terraform"
MASTER_IP_1=$(terraform output -raw cluster_1_master_public_ip)
MASTER_IP_2=$(terraform output -raw cluster_2_master_public_ip)
HAPROXY_IP=$(terraform output -raw haproxy_public_ip)
cd "$SCRIPT_DIR"

if [ -z "$MASTER_IP_1" ]; then
    echo "LỖI: Không tìm thấy Master Node Public IP 1 (cluster 1), kiểm tra lại terraform output"
    exit 1
fi

if [ -z "$MASTER_IP_2" ]; then
    echo "LỖI: Không tìm thấy Master Node Public IP 2 (cluster 2), kiểm tra lại terraform output"
    exit 1
fi

if [ -z "$HAPROXY_IP" ]; then
    echo "lỖI: Không tìm thấy HAProxy Public IP, kiểm tra lại terraform output"
    exit 1
fi

echo "- Cluster 1 Master IP: $MASTER_IP_1"
echo "- Cluster 2 Master IP: $MASTER_IP_2"
echo "- HAProxy Public IP: $HAPROXY_IP"


# Định nghĩa hàm triển khai chuẩn cho 1 cụm K8s
deploy_to_cluster() {
  local CLUSTER_NAME=$1
  local MASTER_IP=$2

  echo "======================================================="
  echo "BẮT ĐẦU TRIỂN KHAI HỆ THỐNG LÊN: $CLUSTER_NAME ($MASTER_IP)"
  echo "======================================================="

  echo "[1/3] Lấy file cấu hình kubeconfig..."
  mkdir -p ./kube
  KUBE_CONFIG_FILE="$SCRIPT_DIR/kube/${CLUSTER_NAME}-config"
  ssh -o StrictHostKeyChecking=no -i $PEM_FILE ubuntu@$MASTER_IP "sudo cat /etc/rancher/k3s/k3s.yaml" > $KUBE_CONFIG_FILE
  sed -i "s/127.0.0.1/$MASTER_IP/g" $KUBE_CONFIG_FILE
  chmod 600 $KUBE_CONFIG_FILE
  export KUBECONFIG=$KUBE_CONFIG_FILE


  echo "[2/3] Cài đặt Istio Service Mesh..."
  export PATH="$PATH:$ISTIO_DIR/bin:$PATH"

  if ! command -v istioctl &> /dev/null; then 
      echo "Lỗi: Không tìm thấy istioctl. Vui lòng kiểm tra lại đường dẫn ISTIO_DIR."
      exit 1
  fi

  istioctl install --set profile=demo --set values.pilot.traceSampling=100.0 -y

  echo " - Cố định cổng Istio IngressGateway ở 30081 (HTTP) và 30082 (HTTPS)..."
  kubectl patch svc istio-ingressgateway -n istio-system -p '{"spec": {"ports": [{"port": 80, "nodePort": 30081}, {"port": 443, "nodePort": 30082}]}}'

  echo " - Đánh dấu namespace 'ecommerce' để tự động nhúng Envoy sidecar..."
  kubectl create namespace ecommerce --dry-run=client -o yaml | kubectl apply -f -
  kubectl label namespace ecommerce istio-injection=enabled --overwrite

  echo " - Cài đặt các Addons (Kiali, Prometheus, Grafana, Jaeger)..."
  kubectl apply -f "$ISTIO_DIR/samples/addons/kiali.yaml"
  kubectl apply -f "$ISTIO_DIR/samples/addons/prometheus.yaml"
  kubectl apply -f "$ISTIO_DIR/samples/addons/grafana.yaml"
  kubectl apply -f "$ISTIO_DIR/samples/addons/jaeger.yaml"


  echo "[3/3] Triển khai toàn bộ ứng dụng (Infra + Microservices)..."
  echo " - Cài đặt cấu hình nền tảng (ConfigMap, Secret)..."
  kubectl apply -f ../infrastructure/k8s/configmap.yaml
  kubectl apply -f ../infrastructure/k8s/secrets.yaml

  echo " - Tạo các ConfigMap động từ file (Keycloak, Postgres, Apisix)..."
  NAMESPACE="ecommerce"
  kubectl create configmap keycloak-realm        -n "$NAMESPACE" \
    --from-file=ecommerce-realm.json=../infrastructure/docker/keycloak/import/ecommerce-realm.json \
    --dry-run=client -o yaml | kubectl apply -f -

  kubectl create configmap postgres-init-scripts -n "$NAMESPACE" \
    --from-file=create-all-databases.sql=../infrastructure/docker/postgres/init/create-all-databases.sql \
    --dry-run=client -o yaml | kubectl apply -f -

  kubectl create configmap apisix-config         -n "$NAMESPACE" \
    --from-file=config.yaml=../infrastructure/deploy/apisix/config.yaml \
    --dry-run=client -o yaml | kubectl apply -f -

  kubectl create configmap apisix-routes         -n "$NAMESPACE" \
    --from-file=apisix.yaml=../infrastructure/deploy/apisix/apisix.yaml \
    --dry-run=client -o yaml | kubectl apply -f -

  echo " - Cài đặt Infra (apisix, kafka, keycloak, redis)..."
  kubectl apply -f ../infrastructure/k8s/infra/apisix.yaml
  kubectl apply -f ../infrastructure/k8s/infra/kafka.yaml
  kubectl apply -f ../infrastructure/k8s/infra/keycloak.yaml
  kubectl apply -f ../infrastructure/k8s/infra/redis.yaml

  echo " - Cài đặt các Microservices (Product, Order, Inventory, v.v.)..."
  kubectl apply -f ../infrastructure/k8s/backend/auth-service.yaml
  kubectl apply -f ../infrastructure/k8s/backend/inventory-service.yaml
  kubectl apply -f ../infrastructure/k8s/backend/order-service.yaml
  kubectl apply -f ../infrastructure/k8s/backend/payment-service.yaml
  kubectl apply -f ../infrastructure/k8s/backend/product-service-v1.yaml
  kubectl apply -f ../infrastructure/k8s/backend/product-service-v2.yaml
  kubectl apply -f ../infrastructure/k8s/backend/shipping-service.yaml
  kubectl apply -f ../infrastructure/k8s/frontend/admin.yaml
  kubectl apply -f ../infrastructure/k8s/frontend/frontend.yaml

  echo " - Nạp chứng chỉ TLS (Cloudflare) vào Istio Gateway..."
  kubectl create secret tls ecommerce-credential \
    -n istio-system \
    --cert=../infrastructure/tls-cert/tls.crt \
    --key=../infrastructure/tls-cert/tls.key \
    --dry-run=client -o yaml | kubectl apply -f -

  echo " - Cài đặt cấu hình Istio (destination rule, gateway, peer auth, virtual service)..."
  kubectl apply -f ../infrastructure/k8s/istio/

  echo " - Cài đặt cấu hình hpa..."
  kubectl apply -f ../infrastructure/k8s/hpa/payment-hpa.yaml
  kubectl apply -f ../infrastructure/k8s/hpa/product-hpa.yaml

  echo " - Khởi động lại các Pod để bắt đầu áp dụng Envoy Sidecar (nếu có Pod đã chạy)..."
  kubectl rollout restart deployment -n ecommerce || true

  echo "HOÀN TẤT TRÊN $CLUSTER_NAME"
  echo ""
}

# Thực thi triển khai lần lượt trên cả 2 cụm
echo "Bắt đầu triển khai trên cluster 1..."
deploy_to_cluster "cluster-1" "$MASTER_IP_1"

echo "Bắt đầu triển khai trên cluster 2..."
deploy_to_cluster "cluster-2" "$MASTER_IP_2"

# In thông tin kết thúc
echo "=========================================================="
echo "CHÚC MỪNG! HỆ THỐNG ĐÃ ĐƯỢC DEPLOY LÊN CẢ 2 CLUSTER"
echo "LƯU Ý: Để quản trị 2 cụm độc lập ở tab terminal mới, hãy dùng 1 trong 2 lệnh:"
echo "  Quản trị Cluster 1: export KUBECONFIG=$SCRIPT_DIR/kube/cluster-1-config"
echo "  Quản trị Cluster 2: export KUBECONFIG=$SCRIPT_DIR/kube/cluster-2-config"
echo "----------------------------------------------------------"
echo "Bạn có thể truy cập hệ thống tại: http://$HAPROXY_IP"
echo "Bạn hãy kiểm tra trạng thái các Pod bằng lệnh:"
echo "  kubectl get pods -n ecommerce"
echo "Để mở Kiali Dashboard, hãy chạy:"
echo " istioctl dashboard kiali"
echo "=========================================================="









    

