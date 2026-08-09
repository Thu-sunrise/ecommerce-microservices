#!/bin/bash
set -e

NAMESPACE="ecommerce"
SERVICE_URL="http://product-service:8086/api/products"

echo "================================================="
echo " BÀI TEST 2: ADVANCED ROUTING (VIP/PREMIUM USER)"
echo "================================================="

# Đảm bảo Pod v2 đã được khởi tạo
echo "Đang chuẩn bị môi trường (Deploy V2)..."
kubectl apply -f ../../infrastructure/k8s/backend/product-service-v2.yaml > /dev/null
kubectl wait --for=condition=ready pod -l app=product-service,version=v2 -n $NAMESPACE --timeout=60s > /dev/null

# Đếm số lượng log hiện tại để làm cơ sở so sánh (baseline)
V1_BASE=$(kubectl logs -l app=product-service,version=v1 -n $NAMESPACE -c istio-proxy --tail=500 | grep "/api/products" | wc -l || echo 0)
V2_BASE=$(kubectl logs -l app=product-service,version=v2 -n $NAMESPACE -c istio-proxy --tail=500 | grep "/api/products" | wc -l || echo 0)

echo "Đang khởi tạo Pod tạm thời để bắn requests (có thể mất 1-2 phút tải image)..."
kubectl run curl-premium -n $NAMESPACE --image=curlimages/curl --restart=Never -- sleep 3600 > /dev/null
kubectl wait --for=condition=ready pod/curl-premium -n $NAMESPACE --timeout=180s > /dev/null

echo "Đang bắn 20 requests với header 'x-user-role: premium'..."
kubectl exec curl-premium -n $NAMESPACE -c curl-premium -- sh -c "for i in \$(seq 1 20); do curl -s -H 'x-user-role: premium' $SERVICE_URL > /dev/null; done"

echo "Đã bắn xong 20 requests Premium! Đang tính toán sự chênh lệch..."
sleep 2

# Đếm lại log sau khi bắn request
V1_NEW=$(kubectl logs -l app=product-service,version=v1 -n $NAMESPACE -c istio-proxy --tail=500 | grep "/api/products" | wc -l || echo 0)
V2_NEW=$(kubectl logs -l app=product-service,version=v2 -n $NAMESPACE -c istio-proxy --tail=500 | grep "/api/products" | wc -l || echo 0)

# Tính ra đúng số lượng log vừa sinh ra
DIFF_V1=$((V1_NEW - V1_BASE))
DIFF_V2=$((V2_NEW - V2_BASE))

echo "=> Số request Premium lọt vào V1 (Kỳ vọng 0): $DIFF_V1"
echo "=> Số request Premium lọt vào V2 (Kỳ vọng 20): $DIFF_V2"
echo "================================================="

# Dọn dẹp
kubectl delete pod curl-premium -n $NAMESPACE --ignore-not-found > /dev/null 2>&1
