#!/bin/bash
set -e
NAMESPACE="ecommerce"

echo "================================================="
echo " BAI TEST 2: ABORT INJECTION (LOI 500)"
echo "================================================="

echo "1. Dang ap dung cau hinh VirtualService (Abort 500)..."
kubectl apply -f virtual-service-abort.yaml > /dev/null
sleep 2

echo "2. Dang ban request tu mot Pod khac vao product-service..."
kubectl run curl-chaos -n $NAMESPACE -i --rm --image=curlimages/curl --restart=Never -- sh -c "curl -s -w 'Status: %{http_code}\n' http://product-service:8086/api/products"

echo "=> Ky vong: Istio Gateway se tra ve HTTP Status 500."

echo "3. Khoi phuc lai cau hinh goc..."
kubectl apply -f ../../infrastructure/k8s/istio/virtual-service-product.yaml > /dev/null
