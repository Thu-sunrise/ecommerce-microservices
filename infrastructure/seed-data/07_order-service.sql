-- =============================================================
-- 07_order-service.sql
-- Database: orderservice
-- Mô tả: Seed carts + orders
-- Lưu ý:
--   - cart.user_id tham chiếu logical tới user_id từ auth-service (user 1,2,3)
--   - order.product_id tham chiếu logical tới product-service (product_id 1–10)
--   - order_id hardcode để payment-service, shipping-service tham chiếu
-- =============================================================

-- -------------------------------------
-- CARTS (1 cart / user)
-- user_id: truyền qua biến môi trường (USER_ID_1, USER_ID_2, USER_ID_3)
-- -------------------------------------
INSERT INTO carts (cart_id, user_id, created_at, updated_at)
VALUES
    (1, :USER_ID_1, NOW(), NOW()),
    (2, :USER_ID_2, NOW(), NOW()),
    (3, :USER_ID_3, NOW(), NOW())
ON CONFLICT (cart_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('carts', 'cart_id'), 3, true);

-- -------------------------------------
-- ORDERS (2 orders / cart = 6 orders tổng)
-- order_date: trải đều trong tháng 7/2024
-- product_id tham chiếu logical tới product-service
-- -------------------------------------
INSERT INTO orders (order_id, order_date, order_desc, order_fee, product_id, cart_id, created_at, updated_at)
VALUES
    -- Cart 1 (user_id=1: Nguyễn Văn An)
    (1, '2024-07-05 10:30:00', 'Đặt hàng iPhone 15 Pro Max',    30000000.0, 1, 1, NOW(), NOW()),
    (2, '2024-07-12 14:00:00', 'Đặt hàng Sony WH-1000XM5',       8000000.0, 7, 1, NOW(), NOW()),

    -- Cart 2 (user_id=2: Trần Thị Bích)
    (3, '2024-07-08 09:15:00', 'Đặt hàng MacBook Pro 14 M3',    40000000.0, 3, 2, NOW(), NOW()),
    (4, '2024-07-15 16:45:00', 'Đặt hàng Apple Watch Series 9', 10000000.0, 5, 2, NOW(), NOW()),

    -- Cart 3 (user_id=3: Lê Minh Cường)
    (5, '2024-07-10 11:00:00', 'Đặt hàng AirPods Pro 2',         6000000.0, 8, 3, NOW(), NOW()),
    (6, '2024-07-18 13:30:00', 'Đặt hàng Samsung Galaxy S24',   28000000.0, 2, 3, NOW(), NOW())
ON CONFLICT (order_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('orders', 'order_id'), 6, true);
