# 🌱 Seed Data

Thư mục này chứa toàn bộ dữ liệu mẫu (seed data) cho hệ thống **Ecommerce Microservices**.
Mỗi file SQL tương ứng một service và phải chạy **đúng thứ tự** do ràng buộc phụ thuộc dữ liệu.

---

## Cấu trúc file

| File | Database | Nội dung |
|------|----------|----------|
| `01_auth-service.sql` | `authservice` | 3 roles, 5 users, user_role |
| `02_product-service.sql` | `productservice` | 5 categories, 10 products |
| `03_inventory-service.sql` | `inventoryservice` | 10 inventory records |
| `04_tax-service.sql` | `taxservice` | 3 tax classes, 5 tax rates |
| `05_media-service.sql` | `mediaservice` | 10 product images + 2 banners |
| `06_promotion-service.sql` | `promotionservice` | 3 promotions, 3 promotion_apply |
| `07_order-service.sql` | `orderservice` | 3 carts, 6 orders |
| `08_payment-service.sql` | `paymentservice` | 6 payments |
| `09_shipping-service.sql` | `shippingservice` | 6 order_items |
| `10_favourite-service.sql` | `favouriteservice` | 7 favourites |
| `11_rating-service.sql` | `ratingservice` | 6 ratings |
| `12_notification-service.sql` | `notificationservice` | 6 payments (mirror) + 6 notifications |
| `13_promotion-service-usage.sql` | `promotionservice` | 2 promotion_usage |

---

## Dữ liệu mẫu — Bảng tóm tắt

### Users (auth-service)

| user_id | Tên | username | Role |
|---------|-----|----------|------|
| 1 | Nguyễn Văn An | `user_an` | USER |
| 2 | Trần Thị Bích | `user_bich` | USER |
| 3 | Lê Minh Cường | `user_cuong` | USER |
| 4 | Phạm Thanh Dung | `pm_dung` | PM |
| 5 | Hoàng Văn Em | `admin_em` | ADMIN |

### Products (product-service)

| product_id | Sản phẩm | Danh mục | Giá |
|------------|----------|----------|-----|
| 1 | iPhone 15 Pro Max 256GB | Điện thoại | 30,000,000đ |
| 2 | Samsung Galaxy S24 Ultra | Điện thoại | 28,000,000đ |
| 3 | MacBook Pro 14 M3 | Laptop | 40,000,000đ |
| 4 | Dell XPS 15 9530 | Laptop | 38,000,000đ |
| 5 | Apple Watch Series 9 | Đồng hồ | 10,000,000đ |
| 6 | Garmin Fenix 7 | Đồng hồ | 15,000,000đ |
| 7 | Sony WH-1000XM5 | Tai nghe | 8,000,000đ |
| 8 | AirPods Pro 2 | Tai nghe | 6,000,000đ |
| 9 | Sony Alpha A7 IV | Máy ảnh | 60,000,000đ |
| 10 | Canon EOS R6 Mark II | Máy ảnh | 55,000,000đ |

### Mối quan hệ Orders → Payments

| order_id | user | product | payment_status |
|----------|------|---------|----------------|
| 1 | user_an | iPhone 15 Pro Max | COMPLETED |
| 2 | user_an | Sony WH-1000XM5 | IN_PROGRESS |
| 3 | user_bich | MacBook Pro M3 | COMPLETED |
| 4 | user_bich | Apple Watch S9 | NOT_STARTED |
| 5 | user_cuong | AirPods Pro 2 | COMPLETED |
| 6 | user_cuong | Samsung S24 Ultra | NOT_STARTED |

---

## Cách chạy

### Yêu cầu

- PostgreSQL đang chạy (local hoặc Docker)
- Tất cả databases đã được tạo (chạy `docker/postgres/init/create-all-databases.sql` trước)
- Liquibase đã chạy migrations cho từng service (tables phải tồn tại)

### Chạy toàn bộ (khuyến nghị)

```bash
# Mặc định kết nối localhost:5432, user=postgres, pass=postgres
chmod +x seed-data/run-all.sh
./seed-data/run-all.sh

# Custom host/credentials
PG_HOST=localhost PG_PORT=5432 PG_USER=postgres PG_PASS=mypassword \
  ./seed-data/run-all.sh
```

### Chạy từng file riêng lẻ

```bash
PGPASSWORD=postgres psql -h localhost -U postgres -d productservice \
  -f seed-data/02_product-service.sql
```

### Chạy với Docker Compose

```bash
# Nếu PostgreSQL đang chạy trong docker container tên "postgres"
docker exec -i postgres psql -U postgres -d authservice \
  < seed-data/01_auth-service.sql
```

---

## Lưu ý quan trọng

> ⚠️ **Thứ tự chạy**: Phải chạy đúng thứ tự số file (01 → 13) vì các service sau tham chiếu `user_id`, `product_id`, `order_id` từ service trước.

> ⚠️ **Idempotent**: Tất cả file dùng `ON CONFLICT DO NOTHING` — chạy lại an toàn, không tạo duplicate.

> ℹ️ **Keycloak**: `keycloak_user_id` trong bảng `users` được seed với UUID placeholder dạng `aaaaaaaa-0001-4000-a000-00000000000X`. Cần cập nhật sau khi sync với Keycloak thật.

> ℹ️ **Microservice independence**: Các service không có FK database cứng cross-service (đây là thiết kế đúng của microservice). Mối quan hệ chỉ là **logical** qua ID.

> ℹ️ **notification-service**: File `12_notification-service.sql` có thể bỏ qua nếu service dùng H2 in-memory thay vì PostgreSQL.

---

## Sơ đồ phụ thuộc dữ liệu

```
auth-service (users)
    │
    ├──► order-service (carts.user_id, orders)
    │         │
    │         ├──► payment-service (payments.order_id)
    │         │         │
    │         │         └──► notification-service (mirror)
    │         │
    │         └──► shipping-service (order_items.order_id)
    │
    ├──► favourite-service (favourites.user_id)
    ├──► rating-service (rating.created_by)
    └──► promotion-service (promotion_usage.user_id)

product-service (categories, products)
    │
    ├──► inventory-service (logical: productName)
    ├──► media-service (logical: file_name convention)
    ├──► order-service (orders.product_id)
    ├──► favourite-service (favourites.product_id)
    ├──► rating-service (rating.product_id)
    └──► promotion-service (promotion_apply.product_id / category_id)

tax-service (tax_class, tax_rate) — độc lập
```
