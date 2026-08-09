#!/bin/bash
set -e
NAMESPACE="ecommerce"

echo "================================================="
echo " BAI TEST: KIEM TRA mTLS STRICT MODE"
echo "================================================="

echo "1. Ban request tu mot Pod NAM TRONG Istio Mesh (co sidecar)..."
# Dung annotions/labels thong thuong de vao mesh, vi default namespace 'ecommerce' da enable istio-injection
kubectl run curl-in-mesh -n $NAMESPACE -i --rm --image=curlimages/curl --restart=Never -- sh -c "curl -s -o /dev/null -w 'Status: %{http_code}\n' http://product-service:8086/api/products"

echo "=> Ky vong: HTTP 200 (Thanh cong vi ket noi duoc ma hoa mTLS)."
echo ""
sleep 2

echo "2. Ban request tu mot Pod NAM NGOAI Istio Mesh (khong co sidecar)..."
# Chay tren namespace default (khong enable istio)
kubectl run curl-out-mesh -n default -i --rm --image=curlimages/curl --labels="sidecar.istio.io/inject=false" --restart=Never -- sh -c "curl -s -v --max-time 5 http://product-service.$NAMESPACE.svc.cluster.local:8086/api/products || echo '=> Ket noi bi tu choi!'"

echo "=> Ky vong: Ket noi bi tu choi (Connection reset by peer / Recv failure). Do Istio chan cac ket noi HTTP thuong."
echo "================================================="
