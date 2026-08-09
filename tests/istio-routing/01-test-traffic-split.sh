#!/bin/bash
set -e

NAMESPACE="ecommerce"
SERVICE_URL="http://product-service:8086/api/products"

echo "================================================================="
echo " BÀI TEST 1: TRAFFIC SPLITTING (90% v1 - 10% v2)"
echo "================================================================="

# Đảm bảo Pod v2 đã được khởi tạo
echo "Đang chuẩn bị môi trường (Deploy V2)..."
kubectl apply -f ../../infrastructure/k8s/backend/product-service-v2.yaml > /dev/null
kubectl wait --for=condition=ready pod -l app=product-service,version=v2 -n $NAMESPACE --timeout=60s > /dev/null
# tạo pod mồi (Dummy Pod) đóng vai User
echo "Đang khởi tạo Pod tạm thời để bắn requests (có thể mất 1-2 phút tải image)..."
kubectl run curl-test-split -n $NAMESPACE --image=curlimages/curl --restart=Never -- sleep 3600 > /dev/null
kubectl wait --for=condition=ready pod/curl-test-split -n $NAMESPACE --timeout=180s > /dev/null

# Đếm số lượng log hiện tại để làm cơ sở (baseline)
V1_BASE=$(kubectl logs -l app=product-service,version=v1 -n $NAMESPACE -c istio-proxy --tail=1000 | grep "/api/products" | wc -l || echo 0)
V2_BASE=$(kubectl logs -l app=product-service,version=v2 -n $NAMESPACE -c istio-proxy --tail=1000 | grep "/api/products" | wc -l || echo 0)

echo "Đang bắn 100 requests bình thường (không có header)..."
kubectl exec curl-test-split -n $NAMESPACE -c curl-test-split -- sh -c "for i in \$(seq 1 100); do curl -s $SERVICE_URL > /dev/null; done"

echo "Đã bắn xong 100 requests! Đang tính toán tỷ lệ từ Envoy Proxy..."
sleep 2

# Lấy log mới nhất
V1_NEW=$(kubectl logs -l app=product-service,version=v1 -n $NAMESPACE -c istio-proxy --tail=1000 | grep "/api/products" | wc -l || echo 0)
V2_NEW=$(kubectl logs -l app=product-service,version=v2 -n $NAMESPACE -c istio-proxy --tail=1000 | grep "/api/products" | wc -l || echo 0)

# Tính toán số lượng vừa được sinh ra
V1_COUNT=$((V1_NEW - V1_BASE))
V2_COUNT=$((V2_NEW - V2_BASE))
echo "=> Số request lọt vào V1 (Kỳ vọng ~90): $V1_COUNT"
echo "=> Số request lọt vào V2 (Kỳ vọng ~10): $V2_COUNT"
echo "================================================="

# Dọn dẹp
kubectl delete pod curl-test-split -n $NAMESPACE --ignore-not-found > /dev/null 2>&1