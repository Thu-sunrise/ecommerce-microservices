#!/bin/bash
# k8s/hpa/tests/k6/run-hpa-test.sh
# Chạy k6 đồng thời monitor HPA từ máy ngoài (cần kubectl access)

set -e

SERVICE=${1:-product}   # product | payment
NAMESPACE=ecommerce

echo "=========================================="
echo " HPA Autoscale Test: $SERVICE-service"
echo "=========================================="

# 1. Port-forward service ra localhost
echo "[1] Port-forwarding $SERVICE-service..."
if [ "$SERVICE" = "product" ]; then
  # product-service: chỉ expose port 8086 qua Service (port 9000/actuator chỉ có ở Pod level)
  kubectl port-forward svc/product-service 8086:8086 -n $NAMESPACE &
  PF_PID=$!
  LOCAL_URL="http://localhost:8086"
  TEST_FILE="product-load.js"
elif [ "$SERVICE" = "payment" ]; then
  kubectl port-forward svc/payment-service 8085:8085 -n $NAMESPACE &
  PF_PID=$!
  LOCAL_URL="http://localhost:8085"
  TEST_FILE="payment-load.js"
fi

sleep 3
echo "[1] Port-forward PID: $PF_PID"

# 2. Monitor HPA trong background
echo "[2] Bắt đầu monitor HPA replicas..."
(
  while true; do
    echo "--- $(date '+%H:%M:%S') ---"
    kubectl get hpa ${SERVICE}-service-hpa -n $NAMESPACE \
      --no-headers \
      -o custom-columns=\
'NAME:.metadata.name,CURRENT:.status.currentReplicas,DESIRED:.spec.minReplicas,MIN:.spec.minReplicas,MAX:.spec.maxReplicas,CPU:.status.currentMetrics[0].resource.current.averageUtilization'
    kubectl get pods -n $NAMESPACE -l app=${SERVICE}-service \
      --no-headers | awk '{print "  Pod:", $1, "Status:", $3}'
    sleep 15
  done
) &
MONITOR_PID=$!

# 3. Chạy k6 test
echo "[3] Chạy k6 load test..."
PRODUCT_URL=$LOCAL_URL PAYMENT_URL=$LOCAL_URL \
  k6 run \
    --out json=hpa-test-result-${SERVICE}.json \
    $(dirname "$0")/$TEST_FILE

# 4. Cleanup
echo "[4] Dọn dẹp..."
kill $MONITOR_PID 2>/dev/null || true
kill $PF_PID     2>/dev/null || true

echo ""
echo "✅ Test hoàn thành! Kết quả: hpa-test-result-${SERVICE}.json"
