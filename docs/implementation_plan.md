# Kế hoạch triển khai HAProxy cho 2 cụm Kubernetes (Mô hình 2 Subnet / Đa vùng mạng)

Kế hoạch này hướng dẫn các bước chi tiết để thiết lập một máy chủ HAProxy đóng vai trò Load Balancer đứng trước 2 cụm Kubernetes được đặt ở **2 Subnet khác nhau**. 
Thiết kế này đại diện cho "chuẩn doanh nghiệp", giúp tăng cường bảo mật (cô lập mạng) và mô phỏng môi trường phân tán thực tế. Kế hoạch này chỉ cung cấp hướng dẫn và cấu hình mẫu, không can thiệp vào source code của dự án hiện tại.

## User Review Required
> [!IMPORTANT]
> Vui lòng xem xét các IP và cấu hình Firewall giả định trong tài liệu này và điều chỉnh lại cho khớp với dải mạng VPC thực tế trong bài Lab/Môi trường của bạn.

## Các giả định về Mạng & Môi trường (Network Topology)

Để thiết lập mô hình 2 Subnet an toàn, chúng ta giả định VPC được chia làm 3 Subnet:

1. **HAProxy Server**: `10.0.0.100` nằm ở **Subnet 0 (Public/DMZ)**: `10.0.0.0/24`. (Nơi tiếp nhận traffic từ ngoài Internet).
2. **K8s Cluster 1**: `10.0.1.10` nằm ở **Subnet 1 (Private)**: `10.0.1.0/24` (Mở NodePort 30080).
3. **K8s Cluster 2**: `10.0.2.10` nằm ở **Subnet 2 (Private)**: `10.0.2.0/24` (Mở NodePort 30080).

## Chi tiết các bước triển khai

---

### Bước 1: Chuẩn bị Định tuyến (Routing) và Tường lửa (Firewall)
> [!CAUTION]
> Khác với mô hình 1 Subnet, bạn phải cấu hình hạ tầng mạng bên dưới để HAProxy có thể "nhìn thấy" 2 cụm K8s.

1. **Routing:** Đảm bảo Router ảo của VPC cho phép gói tin (packet) đi từ Subnet 0 sang Subnet 1 và Subnet 2. (Thường các Cloud VPC cấu hình sẵn điều này).
2. **Firewall / Security Group:**
   - Trên Cụm 1: Mở Inbound port `30080` (và `30443`) cho phép duy nhất dải IP `10.0.0.0/24` (của HAProxy) truy cập.
   - Trên Cụm 2: Mở Inbound port `30080` (và `30443`) cho phép duy nhất dải IP `10.0.0.0/24` truy cập.

---

### Bước 2: Chuẩn bị Ingress trên 2 cụm Kubernetes

Để HAProxy đẩy traffic vào K8s, Ingress Controller (Nginx, Istio, v.v) của cả 2 cụm phải expose qua `NodePort`.

1. Kiểm tra Service Ingress trên cả 2 cụm đạt trạng thái `NodePort` (Ví dụ: port `30080`).
2. Từ máy chủ HAProxy (`10.0.0.100`), chạy lệnh kiểm tra thông mạng qua 2 subnet:
   - `curl -I http://10.0.1.10:30080` (Kiểm tra vào Cụm 1).
   - `curl -I http://10.0.2.10:30080` (Kiểm tra vào Cụm 2).

---

### Bước 3: Cài đặt HAProxy

Trên máy chủ được chỉ định làm Load Balancer (`10.0.0.100`), thực hiện cài đặt:
- **Ubuntu/Debian:** `sudo apt update && sudo apt install haproxy -y`
- **CentOS/RHEL:** `sudo yum install haproxy -y`

---

### Bước 4: Cấu hình HAProxy (File haproxy.cfg)

Tạo file cấu hình tại `/etc/haproxy/haproxy.cfg`. HAProxy sẽ đứng ở giữa và điều hướng vào 2 subnet nội bộ.

```haproxy
global
    log /dev/log    local0
    log /dev/log    local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000

# Giao diện thống kê (Dashboard)
frontend stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats admin if LOCALHOST

# Tiếp nhận traffic HTTP từ người dùng (Cổng 80)
frontend k8s_http_frontend
    bind *:80
    mode http
    
    # Chèn header IP thật của User để K8s Ingress phân tích log
    option forwardfor
    
    default_backend k8s_backend_clusters

# Định tuyến vào 2 cụm K8s ở 2 Subnet khác nhau
backend k8s_backend_clusters
    mode http
    balance roundrobin
    
    # Định nghĩa Cụm 1 (Subnet 1): Kiểm tra ping liên tục mỗi 2s
    server cluster-1 10.0.1.10:30080 check inter 2000 rise 2 fall 3

    # Định nghĩa Cụm 2 (Subnet 2): Kiểm tra ping liên tục mỗi 2s
    server cluster-2 10.0.2.10:30080 check inter 2000 rise 2 fall 3
```

> [!TIP]
> - **Mô hình Blue/Green:** Thay vì `balance roundrobin`, bạn có thể chỉ định `weight` (ví dụ: `weight 100` cho Cụm 1, và `weight 0` cho cụm 2). Khi cần chuyển đổi, bạn lật ngược trọng số này lại và reload HAProxy.
> - **Mô hình DR:** Thêm chữ `backup` vào cuối dòng `server cluster-2`. Cụm ở Subnet 2 sẽ đứng im làm lốp dự phòng.

Khởi động lại HAProxy để áp dụng:
```bash
haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl restart haproxy
sudo systemctl enable haproxy
```

---

### Bước 5: Cấu hình Traffic Splitting cấp độ Ứng dụng (Istio Service Mesh)

Khi traffic đã đi qua HAProxy và lọt vào cụm K8s, chúng ta sẽ sử dụng sức mạnh của **Istio VirtualService** và **DestinationRule** để điều khiển luồng đi chi tiết giữa các phiên bản của Microservice.

Dựa trên source code của bạn, service `product-service` đã có 2 bản triển khai là `v1` (file `product-service.yaml`) và `v2` (file `product-service-v2.yaml`), đồng thời `DestinationRule` (`destination-rule-product.yaml`) đã định nghĩa sẵn 2 subset `v1` và `v2`.

#### Kịch bản 1: Phân bổ Traffic theo Trọng số (Weight-based Routing / Canary)
*Yêu cầu: 90% traffic vào v1, 10% vào v2.*

Tạo file `virtual-service-product-weight.yaml` với nội dung sau để thay thế cấu hình mặc định:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: product-service-vs
  namespace: ecommerce
spec:
  hosts:
    - product-service
  http:
    - route:
        - destination:
            host: product-service
            subset: v1
          weight: 90
        - destination:
            host: product-service
            subset: v2
          weight: 10
```

**Kiểm thử và Quan sát (Output):**
1. Apply file cấu hình: `kubectl apply -f virtual-service-product-weight.yaml`
2. Chạy giả lập 100 request: `for i in {1..100}; do curl -s http://<IP_HAProxy>/products | grep version; done`
3. **Mở Kiali Dashboard** (Công cụ quan sát đồ thị mạng của Istio): Tại mục Graph, bạn sẽ nhìn thấy biểu đồ Traffic trực quan thể hiện dòng chảy rõ rệt. Mũi tên xanh chỉ vào `product-service-v1` sẽ dày hơn (chiếm ~90% RPS) và mũi tên chỉ vào `product-service-v2` sẽ mỏng hơn (chiếm ~10% RPS).

#### Kịch bản 2: Định tuyến Nâng cao dựa trên HTTP Header (SaaS Specific / Premium User)
*Yêu cầu: Khách hàng Premium (có header `x-user-role: premium`) được trải nghiệm bản `v2` (Canary), khách hàng thường mặc định vào bản `v1`.*

Tạo file `virtual-service-product-header.yaml` với nội dung sau (Lưu ý: Istio ưu tiên xét rule từ trên xuống dưới):

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: product-service-vs
  namespace: ecommerce
spec:
  hosts:
    - product-service
  http:
    # Rule 1: Ưu tiên bắt Header Premium trước
    - match:
        - headers:
            x-user-role:
              exact: premium
      route:
        - destination:
            host: product-service
            subset: v2
            
    # Rule 2: Các request còn lại (Default/Khách thường)
    - route:
        - destination:
            host: product-service
            subset: v1
```

**Kịch bản kiểm thử (Output):**
1. Apply cấu hình mới: `kubectl apply -f virtual-service-product-header.yaml`
2. Đóng vai **User Thường** (Không có header VIP): 
   `curl -s http://<IP_HAProxy>/products`
   👉 Kết quả: Luôn luôn trả về dữ liệu xử lý từ `product-service` bản `v1`.
3. Đóng vai **User Premium**: 
   `curl -H "x-user-role: premium" -s http://<IP_HAProxy>/products`
   👉 Kết quả: Request được Istio bẻ lái 100% sang `product-service` bản `v2`. Trên Kiali Dashboard, bạn sẽ thấy luồng traffic tách biệt hoàn toàn dựa trên header khi thực hiện trace request.

## Kế hoạch kiểm thử Tổng thể (HAProxy + Istio)

### 1. Test chia tải xuyên Subnet (Lớp 4 - HAProxy)
- **Cách làm:** Từ bên ngoài, chạy lệnh: `while true; do curl http://10.0.0.100; sleep 1; done`
- **Kỳ vọng:** HAProxy luân phiên móc nối sang Cụm 1 và Cụm 2. 

### 2. Test chuyển đổi dự phòng (Failover)
- **Cách làm:** Vào Cụm 1, ngắt mạng Node.
- **Kỳ vọng:** Tại `http://10.0.0.100:8404/stats`, `cluster-1` báo Đỏ. Traffic dồn 100% sang Cụm 2. Trong nội bộ Cụm 2, Istio vẫn tiếp tục chia traffic 90/10 hoặc theo Header như đã cấu hình ở Bước 5.
