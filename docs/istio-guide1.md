# Giới thiệu & Triển khai Istio

## 1. Istio là gì?

**Istio** là một **Service Mesh** mã nguồn mở — một lớp hạ tầng nằm giữa các microservice, xử lý toàn bộ network traffic mà **không cần sửa code**.

```
Không có Istio:                    Có Istio:
┌──────────┐                      ┌─────────────────────┐
│ Service A│──────────────────────►│ Envoy │ Service B   │
│          │                      │ Proxy │             │
└──────────┘                      └─────────────────────┘
   Code tự lo retry, TLS,          Envoy lo hết: TLS, retry,
   circuit breaker...              timeout, metrics, tracing
```

### Istio giải quyết vấn đề gì?

| Vấn đề | Giải pháp Istio |
|---|---|
| Service-to-service TLS | **mTLS tự động** giữa tất cả services |
| Retry & circuit breaker | Cấu hình qua YAML, không sửa code |
| Load balancing nâng cao | Round-robin, least-conn, consistent hash |
| Canary / Blue-Green deploy | Traffic splitting theo tỉ lệ % |
| Observability | Metrics, distributed tracing, access log |
| Rate limiting | Giới hạn request per service |

---

## 2. Kiến trúc Istio

```
┌─────────────────────────────────────────────────────────────┐
│                    CONTROL PLANE                            │
│                                                             │
│   ┌──────────────────────────────────────────────────────┐  │
│   │                    istiod                            │  │
│   │  • Pilot      — cấu hình Envoy proxy                │  │
│   │  • Citadel    — quản lý certificate/mTLS            │  │
│   │  • Galley     — validate config                     │  │
│   └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                          │ xPDS API
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                     DATA PLANE                              │
│                                                             │
│  ┌────────────────┐    ┌────────────────┐                   │
│  │ [Envoy]        │    │ [Envoy]        │                   │
│  │ product-service│───►│ payment-service│                   │
│  │ (sidecar)      │    │ (sidecar)      │                   │
│  └────────────────┘    └────────────────┘                   │
│                                                             │
│  Envoy sidecar được inject tự động vào mỗi Pod             │
└─────────────────────────────────────────────────────────────┘
```

### Các Custom Resource quan trọng

| CRD | Chức năng | Ví dụ |
|---|---|---|
| **VirtualService** | Điều hướng traffic, retry, timeout | Route 10% traffic sang v2 |
| **DestinationRule** | Load balancing, circuit breaker, mTLS | `ROUND_ROBIN`, `LEAST_CONN` |
| **Gateway** | Ingress traffic vào mesh | Thay thế NGINX Ingress |
| **PeerAuthentication** | Bật/tắt mTLS | `STRICT` mode |
| **AuthorizationPolicy** | RBAC cho service-to-service | Chỉ cho product-service gọi inventory |
| **ServiceEntry** | Đăng ký external service | Neon DB, Kafka |

---

## 3. Lưu ý khi cài trên k3d

> [!WARNING]
> k3d/k3s dùng **CNI flannel** và **klipper-lb** — có thể xung đột với Istio. Cần thêm flag đặc biệt khi cài.

```yaml
# k3d-config.yaml — đã có --disable=traefik ✅
# Istio cần thêm: --disable=servicelb (tùy chọn)
options:
  k3s:
    extraArgs:
      - arg: --disable=traefik         # ✅ đã có
        nodeFilters: ["server:*"]
```

Cluster của bạn đã disable Traefik — tốt cho Istio.

---

## 4. Cài đặt Istio — từng bước

### Bước 1: Cài istioctl

```bash
# Download Istio (phiên bản ổn định nhất)
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.23.0 sh -

# Thêm vào PATH
export PATH="$HOME/istio-1.23.0/bin:$PATH"
echo 'export PATH="$HOME/istio-1.23.0/bin:$PATH"' >> ~/.bashrc

# Kiểm tra
istioctl version
```

### Bước 2: Kiểm tra cluster tương thích

```bash
istioctl x precheck
# Nếu tất cả ✅ → tiến hành cài
```

### Bước 3: Cài Istio với profile `demo`

```bash
# Profile 'demo' — đầy đủ tính năng, phù hợp dev/test
istioctl install --set profile=demo \
  --set values.pilot.traceSampling=100.0 \
  -y

# Kiểm tra
kubectl get pods -n istio-system
# Cần thấy: istiod, istio-ingressgateway, istio-egressgateway
```

### Bước 4: Bật sidecar injection cho namespace `ecommerce`

```bash
kubectl label namespace ecommerce istio-injection=enabled

# Kiểm tra label đã có chưa
kubectl get namespace ecommerce --show-labels
```

### Bước 5: Restart tất cả pod để inject sidecar

```bash
# Bắt buộc phải restart — sidecar chỉ inject khi pod khởi động
kubectl rollout restart deployment -n ecommerce

# Kiểm tra: mỗi pod giờ phải có 2/2 containers (app + envoy)
kubectl get pods -n ecommerce
# READY phải là 2/2, không phải 1/1
```

---

## 5. Manifest Istio cho project

### `k8s/istio/gateway.yaml` — Thay thế NGINX Ingress

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: ecommerce-gateway
  namespace: ecommerce
spec:
  selector:
    istio: ingressgateway
  servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
        - "*.hubsunrise.me"
        - "frontend.hubsunrise.me"
```

### `k8s/istio/virtual-service-product.yaml` — Routing + Retry

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
    - timeout: 30s           # timeout cho mọi request
      retries:
        attempts: 3          # retry tối đa 3 lần
        perTryTimeout: 10s   # mỗi lần retry chờ 10s
        retryOn: 5xx,gateway-error,connect-failure
      route:
        - destination:
            host: product-service
            port:
              number: 8086
```

### `k8s/istio/destination-rule-product.yaml` — Circuit Breaker

```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: product-service-dr
  namespace: ecommerce
spec:
  host: product-service
  trafficPolicy:
    loadBalancer:
      simple: LEAST_CONN     # chia tải theo số request đang xử lý
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 100
        http2MaxRequests: 1000
    outlierDetection:        # circuit breaker
      consecutive5xxErrors: 5       # sau 5 lỗi 5xx liên tiếp
      interval: 30s                 # trong vòng 30s
      baseEjectionTime: 30s         # eject pod lỗi trong 30s
      maxEjectionPercent: 50        # tối đa eject 50% pods
```

### `k8s/istio/peer-authentication.yaml` — Bật mTLS

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default-mtls
  namespace: ecommerce
spec:
  mtls:
    mode: STRICT    # bắt buộc mTLS giữa tất cả services
```

---

## 6. Apply các manifest

```bash
# Apply tất cả manifest Istio
kubectl apply -f k8s/istio/

# Kiểm tra
kubectl get virtualservices -n ecommerce
kubectl get destinationrules -n ecommerce
kubectl get gateway -n ecommerce
```

---

## 7. Cài Addons (Kiali, Grafana, Jaeger)

```bash
# Kiali — dashboard quan sát service mesh
kubectl apply -f ~/istio-1.23.0/samples/addons/kiali.yaml
kubectl apply -f ~/istio-1.23.0/samples/addons/prometheus.yaml
kubectl apply -f ~/istio-1.23.0/samples/addons/grafana.yaml
kubectl apply -f ~/istio-1.23.0/samples/addons/jaeger.yaml

# Truy cập Kiali dashboard
istioctl dashboard kiali
# Mở browser: http://localhost:20001
```

---

## 8. Kết hợp Istio + HPA

Istio và HPA hoạt động **độc lập nhưng bổ trợ nhau**:

```
k6 load test
    │
    ▼
Istio Gateway → VirtualService → routing, retry, circuit breaker
    │
    ▼
product-service Pod (có Envoy sidecar)
    │
    ├─ CPU tăng → HPA scale-up → thêm pod
    │
    └─ Istio tự động load balance sang pod mới (LEAST_CONN)
```

| Tính năng | HPA | Istio |
|---|---|---|
| Scale số pod | ✅ | ❌ |
| Retry request lỗi | ❌ | ✅ |
| Circuit breaker | ❌ | ✅ |
| Observability | ❌ | ✅ (Kiali/Jaeger) |
| mTLS giữa services | ❌ | ✅ |

---

## 9. Thứ tự triển khai khuyến nghị

```
1. istioctl install --set profile=demo -y
2. kubectl label namespace ecommerce istio-injection=enabled
3. kubectl rollout restart deployment -n ecommerce
4. kubectl apply -f k8s/istio/
5. kubectl apply -f ~/istio-1.23.0/samples/addons/
6. istioctl dashboard kiali  ← quan sát service mesh
7. PRODUCT_URL=http://localhost:8086 k6 run product-load.js  ← test tải
8. Xem traffic flow trên Kiali trong khi k6 chạy
```
