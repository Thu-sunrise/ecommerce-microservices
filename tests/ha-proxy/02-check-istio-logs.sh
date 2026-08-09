#!/bin/bash

HOST_HEADER="frontend.hubsunrise.me"

echo "================================================="
echo " ĐẾM SỐ LƯỢNG REQUEST TỚI ISTIO INGRESS GATEWAY"
echo " (1000 dòng log gần nhất)"
echo "================================================="

# Kiểm tra xem kubectl có truy cập được cụm không
if ! kubectl get namespace istio-system >/dev/null 2>&1; then
    echo "Lỗi: Không thể kết nối tới Kubernetes cluster hoặc namespace istio-system không tồn tại."
    exit 1
fi

COUNT=$(kubectl logs -n istio-system -l app=istio-ingressgateway --tail=1000 | grep "$HOST_HEADER" | wc -l || echo 0)

echo "=> Số lượng request (match host $HOST_HEADER): $COUNT"
echo "Ghi chú: Nếu hệ thống chạy đúng kịch bản cân bằng tải (Round Robin), số lượng này ở 2 Cụm K8s phải xấp xỉ nhau."
