-- =============================================================
-- 10_favourite-service.sql
-- Database: favouriteservice
-- Mô tả: Seed favourites (composite PK: user_id + product_id + like_date)
-- Lưu ý:
--   - user_id    tham chiếu logical tới auth-service
--   - product_id tham chiếu logical tới product-service
--   - like_date là phần của composite PK
-- =============================================================

INSERT INTO favourites (user_id, product_id, like_date, created_at, updated_at)
VALUES
    -- user 1 (Nguyễn Văn An): thích 3 sản phẩm
    (1, 1,  '2024-07-05 10:00:00', NOW(), NOW()),  -- iPhone 15 Pro Max
    (1, 3,  '2024-07-06 15:30:00', NOW(), NOW()),  -- MacBook Pro M3
    (1, 7,  '2024-07-07 09:00:00', NOW(), NOW()),  -- Sony WH-1000XM5

    -- user 2 (Trần Thị Bích): thích 2 sản phẩm
    (2, 5,  '2024-07-08 11:00:00', NOW(), NOW()),  -- Apple Watch Series 9
    (2, 8,  '2024-07-09 14:00:00', NOW(), NOW()),  -- AirPods Pro 2

    -- user 3 (Lê Minh Cường): thích 2 sản phẩm
    (3, 2,  '2024-07-10 16:00:00', NOW(), NOW()),  -- Samsung Galaxy S24 Ultra
    (3, 9,  '2024-07-11 10:30:00', NOW(), NOW())   -- Sony Alpha A7 IV
ON CONFLICT (user_id, product_id, like_date) DO NOTHING;
