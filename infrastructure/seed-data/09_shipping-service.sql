-- =============================================================
-- 09_shipping-service.sql
-- Database: shippingservice
-- Mô tả: Seed order_items (OrderItem entity có composite PK: product_id + order_id)
-- Lưu ý:
--   - product_id tham chiếu logical tới product-service
--   - order_id   tham chiếu logical tới order-service
--   - PRIMARY KEY là composite (product_id, order_id)
-- =============================================================

INSERT INTO order_items (product_id, order_id, ordered_quantity, created_at, updated_at)
VALUES
    -- order 1 (user 1) → iPhone 15 Pro Max (product_id=1)
    (1, 1, 1, NOW(), NOW()),

    -- order 2 (user 1) → Sony WH-1000XM5 (product_id=7)
    (7, 2, 1, NOW(), NOW()),

    -- order 3 (user 2) → MacBook Pro 14 M3 (product_id=3)
    (3, 3, 1, NOW(), NOW()),

    -- order 4 (user 2) → Apple Watch Series 9 (product_id=5)
    (5, 4, 1, NOW(), NOW()),

    -- order 5 (user 3) → AirPods Pro 2 (product_id=8)
    (8, 5, 2, NOW(), NOW()),  -- mua 2 cái AirPods

    -- order 6 (user 3) → Samsung Galaxy S24 Ultra (product_id=2)
    (2, 6, 1, NOW(), NOW())
ON CONFLICT (product_id, order_id) DO NOTHING;
