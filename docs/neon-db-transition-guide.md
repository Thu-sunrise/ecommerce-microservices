# Hướng Dẫn Từ A Đến Z: Chuyển Đổi Database Sang Neon Cloud DB

Tài liệu này hướng dẫn chi tiết từng bước để chuyển đổi toàn bộ cơ sở dữ liệu (PostgreSQL) từ chạy local trong cụm Kubernetes sang dịch vụ đám mây **Neon DB (Cloud)**. Lợi ích là giúp giảm tải RAM/CPU cho cụm K3s trên AWS và tận dụng khả năng tự động sao lưu, mở rộng của đám mây.

---

## 📋 TỔNG QUAN CÁC BƯỚC THỰC HIỆN

1.  **Bước 1:** Tạo các Cơ sở dữ liệu (Databases) trên trang quản trị Neon.tech.
2.  **Bước 2:** Cấu hình thông tin kết nối mới trong `configmap.yaml` và `secrets.yaml`.
3.  **Bước 3:** Chỉnh sửa cấu hình Keycloak (`k8s/infra/keycloak.yaml`).
4.  **Bước 4:** Chỉnh sửa cấu hình các Backend Microservices (`k8s/backend/`).
5.  **Bước 5:** Triển khai (Deploy) và xác minh hoạt động.

---

## BƯỚC 1: TẠO CÁC CSDL TRÊN NEON.TECH

Theo chuẩn thiết kế Microservices, mỗi dịch vụ nên sở hữu một CSDL độc lập để tránh phụ thuộc lẫn nhau.

1.  Truy cập vào [Neon Console](https://console.neon.tech/) của bạn.
2.  Chọn project của bạn (ví dụ: `ecommerce-k3s`).
3.  Vào mục **Databases** ở thanh menu bên trái.
4.  Mặc định sẽ có một database tên là `neondb`. Hãy bấm nút **Create Database** để tạo thêm 4 database mới sau:
    *   `auth_service` (Lưu thông tin tài khoản, cấu hình của Keycloak)
    *   `product_service` (Lưu thông tin sản phẩm của product-service)
    *   `order_service` (Lưu thông tin đơn hàng của order-service)
    *   `inventory_service` (Lưu thông tin kho của inventory-service)
    *   `payment_service` (Lưu thông tin thanh toán của payment-service)
5.  Lấy địa chỉ **Host** từ chuỗi kết nối (Connection String) hiển thị trên màn hình:
    *   *Ví dụ:* `ep-spring-shape-aomh8696.c-2.ap-southeast-1.aws.neon.tech`

---

## BƯỚC 2: CẬP NHẬT CONFIGMAP & SECRETS K8S

### 1. Sửa file [k8s/configmap.yaml](file:///home/ichi/demoDevOps/ecommerce-microservices/k8s/configmap.yaml)
Thay đổi host CSDL nội bộ thành host của Neon DB:

```yaml
data:
  # PostgresSQL
  POSTGRES_HOST: "ep-spring-shape-aomh8696.c-2.ap-southeast-1.aws.neon.tech" # Điền host Neon của bạn
  POSTGRES_PORT: "5432"
  POSTGRES_DB: "neondb" # Database mặc định
```

### 2. Sửa file [k8s/secrets.yaml](file:///home/ichi/demoDevOps/ecommerce-microservices/k8s/secrets.yaml)
Mã hóa tài khoản và mật khẩu kết nối Neon DB sang định dạng Base64 và cập nhật vào file:

1.  **Lấy chuỗi Base64 bằng lệnh Terminal:**
    ```bash
    echo -n "neondb_owner" | base64
    # Kết quả: bmVvbmRiX293bmVy

    echo -n "mat_khau_cua_ban" | base64
    # Kết quả: <chuỗi_base64_mật_khẩu>
    ```
2.  **Cập nhật vào `k8s/secrets.yaml`:**
    ```yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: postgres-secret
      namespace: ecommerce
    type: Opaque
    data:
      POSTGRES_USER: bmVvbmRiX293bmVy
      POSTGRES_PASSWORD: <chuỗi_base64_mật_khẩu>
    ```

---

## BƯỚC 3: CẬP NHẬT CẤU HÌNH KEYCLOAK (k8s/infra/keycloak.yaml)

Mở tệp [keycloak.yaml](file:///home/ichi/demoDevOps/ecommerce-microservices/k8s/infra/keycloak.yaml) và thực hiện hai điều chỉnh sau:

1.  **Vô hiệu hóa `initContainers` kiểm tra postgres:**
    Comment out (hoặc xóa) toàn bộ block `initContainers` vì host `postgres` nội bộ không còn chạy:
    ```yaml
    #  initContainers:
    #    - name: wait-for-postgres
    #      image: busybox
    #      command:
    #        - sh
    #        - -c
    #        - |
    #          until nc -z postgres 5432; do
    #            echo "Waiting for postgres..."; sleep 3
    #          done
    ```
2.  **Cập nhật host kết nối:**
    Sửa giá trị của `KC_DB_URL_HOST` để đọc từ ConfigMap đã cập nhật ở Bước 2:
    ```yaml
                - name: KC_DB_URL_HOST
                  valueFrom:
                    configMapKeyRef:
                      name: ecommerce-config
                      key: POSTGRES_HOST
    ```
3.  **Cập nhật tên CSDL:**
    Sửa giá trị của `KC_DB_URL_DATABASE` thành `auth_service` (thay vì `keycloak` mặc định):
    ```yaml
                - name: KC_DB_URL_DATABASE
                  value: auth_service
    ```

---

## BƯỚC 4: CẬP NHẬT CẤU HÌNH CÁC MICROSERVICES BACKEND (k8s/backend/)

Bạn cần thực hiện sửa đổi này cho 4 core services sử dụng CSDL: `product-service`, `order-service`, `inventory-service`, và `payment-service`.

Ví dụ thực hiện cho [order-service.yaml](file:///home/ichi/demoDevOps/ecommerce-microservices/k8s/backend/order-service.yaml):

1.  **Comment out đoạn `wait-for-postgres` trong `initContainers`:**
    ```yaml
          initContainers:
            # - name: wait-for-postgres
            #   image: busybox
            #   command: ["sh", "-c", "until nc -z postgres 5432; do sleep 3; done"]
            #   securityContext:
            #     runAsUser: 65534
            #     allowPrivilegeEscalation: false
            #     capabilities:
            #       drop: ["ALL"]
    ```
2.  **Sửa biến môi trường `SPRING_DATASOURCE_URL`:**
    Thay thế địa chỉ host cũ `postgres` bằng host của Neon DB, sử dụng chính xác tên CSDL có dấu gạch dưới:
    ```yaml
              env:
                - name: SPRING_DATASOURCE_URL
                  value: jdbc:postgresql://$(POSTGRES_HOST):$(POSTGRES_PORT)/order_service?sslmode=require
    ```
    *(Tương tự, sửa cho `product-service` với db `product_service`, `inventory-service` với db `inventory_service`, `payment-service` với db `payment_service`)*.

---

## BƯỚC 5: DEPLOY VÀ XÁC MINH HOẠT ĐỘNG

Sau khi đã hoàn tất các chỉnh sửa ở trên, bạn tiến hành áp dụng các thay đổi lên cụm K3s bằng lệnh:

```bash
# 0. Khởi tạo Namespace (Nếu chưa có)
kubectl apply -f k8s/namespace.yaml

# 1. Apply ConfigMap & Secret mới
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secrets.yaml

# 2. Deploy Keycloak lên Cloud DB
kubectl apply -f k8s/infra/keycloak.yaml

# 3. Deploy các Microservices
kubectl apply -f k8s/backend/product-service.yaml
kubectl apply -f k8s/backend/order-service.yaml
kubectl apply -f k8s/backend/inventory-service.yaml
kubectl apply -f k8s/backend/payment-service.yaml
```

### Cách kiểm tra hoạt động:
1.  **Kiểm tra logs của Pod:**
    ```bash
    kubectl logs -n ecommerce deployment/order-service -f
    ```
    Nếu ứng dụng in ra log khởi chạy thành công (Spring Boot started) và bắt đầu quá trình đồng bộ schema ddl-auto mà không vấp phải lỗi kết nối database, quá trình cài đặt đã hoàn tất.
2.  **Kiểm tra bảng dữ liệu trên Neon Console:**
    Vào lại Neon Console, chọn tab **Tables**, chọn database tương ứng. Bạn sẽ thấy các bảng dữ liệu (ví dụ: bảng `orders` của order-service) được tự động tạo ra bởi Hibernate DDL Auto.
