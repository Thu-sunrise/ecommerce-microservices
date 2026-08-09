-- =============================================================
-- 13_promotion-service-usage.sql
-- Database: promotionservice
-- Mô tả: Seed promotion_usage — lịch sử dùng mã khuyến mãi
-- Lưu ý:
--   - promotion_id tham chiếu FK cứng tới bảng promotion (cùng DB)
--   - order_id     tham chiếu logical tới order-service
--   - user_id      tham chiếu logical tới auth-service (lưu dạng VARCHAR)
--   - Phải chạy SAU file 06 (promotion) VÀ 07 (order)
-- =============================================================

INSERT INTO promotion_usage (
    id, promotion_id, user_id, order_id, product_id,
    created_by, created_on, last_modified_by, last_modified_on
)
VALUES
    -- user 1 (Nguyễn Văn An) dùng SUMMER10 cho đơn #1 (iPhone — category Điện Thoại)
    (1, 1, '1', 1, 1, 'user_an', NOW(), 'user_an', NOW()),

    -- user 3 (Lê Minh Cường) dùng VIP5ALL cho đơn #5 (AirPods)
    (2, 3, '3', 5, 8, 'user_cuong', NOW(), 'user_cuong', NOW())
ON CONFLICT (id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('promotion_usage', 'id'), 2, true);
