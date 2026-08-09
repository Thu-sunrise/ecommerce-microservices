#!/bin/bash

# Default host
HOST_HEADER="frontend.hubsunrise.me"

# Parse arguments
PROTOCOL="http"
HAPROXY_IP=""

for arg in "$@"; do
  if [ "$arg" == "--https" ]; then
    PROTOCOL="https"
  else
    HAPROXY_IP="$arg"
  fi
done

# Try to get IP from Terraform if not provided
if [ -z "$HAPROXY_IP" ]; then
    echo "Đang thử lấy IP của HAProxy từ Terraform output..."
    # Go to terraform dir to get output
    CURRENT_DIR=$(pwd)
    cd ../../infrastructure/terraform || exit
    HAPROXY_IP=$(terraform output -raw haproxy_public_ip 2>/dev/null || echo "")
    cd "$CURRENT_DIR" || exit
fi

if [ -z "$HAPROXY_IP" ] || [ "$HAPROXY_IP" == "No outputs found" ]; then
    echo "❌ Không tìm thấy IP tự động."
    echo "Sử dụng: $0 [HAPROXY_PUBLIC_IP] [--https]"
    echo "Ví dụ 1: $0"
    echo "Ví dụ 2: $0 --https"
    echo "Ví dụ 3: $0 1.2.3.4 --https"
    exit 1
fi

echo "================================================="
echo " BẮT ĐẦU BẮN TRAFFIC VÀO HAPROXY"
echo " Target IP: $HAPROXY_IP"
echo " Host Header: $HOST_HEADER"
echo " Protocol: $PROTOCOL"
echo " Nhấn Ctrl+C để dừng"
echo "================================================="

while true; do
  if [ "$PROTOCOL" == "https" ]; then
    # Use --resolve to force curl to connect to HAProxy IP but verify against the Host Header
    HTTP_STATUS=$(curl -k -s -m 2 -o /dev/null -w "%{http_code}" --resolve "$HOST_HEADER:443:$HAPROXY_IP" "https://$HOST_HEADER")
  else
    HTTP_STATUS=$(curl -s -m 2 -o /dev/null -w "%{http_code}" -H "Host: $HOST_HEADER" "http://$HAPROXY_IP")
  fi
  
  TIMESTAMP=$(date '+%H:%M:%S')
  if [ "$HTTP_STATUS" == "200" ]; then
    echo "[$TIMESTAMP] Request SUCCESS - Status: $HTTP_STATUS"
  else
    echo "[$TIMESTAMP] Request FAILED - Status: $HTTP_STATUS"
  fi
  sleep 0.5
done
