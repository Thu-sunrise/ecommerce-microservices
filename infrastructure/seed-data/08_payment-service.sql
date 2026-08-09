-- =============================================================
-- 08_payment-service.sql
-- Database: paymentservice
-- Mô tả: Seed payments tương ứng với orders từ order-service
-- Lưu ý:
--   - order_id tham chiếu logical tới order-service
--   - user_id  tham chiếu logical tới auth-service
--   - payment_status enum: NOT_STARTED | IN_PROGRESS | COMPLETED
--   - payment_id hardcode để notification-service tham chiếu
-- =============================================================

INSERT INTO payments (payment_id, order_id, user_id, is_payed, payment_status)
VALUES
    -- user 1 — order 1 (iPhone): COMPLETED
    (1, 1, :USER_ID_1, true,  'COMPLETED'),

    -- user 2 — order 3 (MacBook): COMPLETED
    (2, 3, :USER_ID_2, true,  'COMPLETED'),

    -- user 3 — order 5 (AirPods): COMPLETED
    (3, 5, :USER_ID_3, true,  'COMPLETED'),

    -- user 1 — order 2 (Sony headphones): IN_PROGRESS
    (4, 2, :USER_ID_1, false, 'IN_PROGRESS'),

    -- user 2 — order 4 (Apple Watch): NOT_STARTED
    (5, 4, :USER_ID_2, false, 'NOT_STARTED'),

    -- user 3 — order 6 (Samsung S24): NOT_STARTED
    (6, 6, :USER_ID_3, false, 'NOT_STARTED')
ON CONFLICT (payment_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('payments', 'payment_id'), 6, true);
