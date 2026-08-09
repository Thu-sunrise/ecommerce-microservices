#!/bin/bash
set -e
NAMESPACE="ecommerce"

echo "================================================="
echo " BAI TEST 1: DELAY INJECTION (TRE 5 GIAY)"
echo "================================================="

echo "1. Dang ap dung cau hinh VirtualService (Delay 5s)..."
kubectl apply -f virtual-service-delay.yaml > /dev/null
sleep 2

echo "2. Dang ban request tu mot Pod khac vao product-service..."
START_TIME=$(date +%s)
kubectl run curl-chaos -n $NAMESPACE -i --rm --image=curlimages/curl --restart=Never -- sh -c "curl -s -o /dev/null -w 'Status: %{http_code}\n' http://product-service:8086/api/products"
END_TIME=$(date +%s)

DURATION=$((END_TIME - START_TIME))
echo "=> Thoi gian hoan thanh request: ${DURATION} giay"
echo "=> Ky vong: Thoi gian hoan thanh phai lon hon 5 giay (do Istio da giu lai)."

echo "3. Khoi phuc lai cau hinh goc..."
kubectl apply -f ../../infrastructure/k8s/istio/virtual-service-product.yaml > /dev/null
