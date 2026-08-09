-- =============================================================
-- 03_inventory-service.sql
-- Database: inventoryservice
-- Mô tả: Seed inventory tương ứng 10 sản phẩm từ product-service
-- Lưu ý: inventory-service không có FK cứng tới product-service
--        (microservice độc lập), chỉ liên kết logical qua product_name
-- =============================================================

INSERT INTO inventory (id, product_name, quantity)
VALUES
    (1, 'Iphone 15 Pro Max 256GB', 12),
    (2, 'Samsung Galaxy S24 Ultra', 4),
    (3, 'MacBook Pro 14 M3', 15),
    (4, 'Dell XPS 15 9530', 8),
    (5, 'Apple Watch Series 9', 20),
    (6, 'Garmin Fenix 7', 5),
    (7, 'Sony WH-1000XM5', 30),
    (8, 'AirPods Pro 2', 50),
    (9, 'Sony Alpha A7 IV', 2),
    (10, 'Canon EOS R6 Mark II', 3)
ON CONFLICT (id) DO NOTHING;

-- Reset sequence
SELECT setval(pg_get_serial_sequence('inventory', 'id'), 10, true);
