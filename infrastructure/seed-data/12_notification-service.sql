-- =============================================================
-- 12_notification-service.sql
-- Database: notificationservice (nếu service dùng PostgreSQL)
-- Mô tả: Seed payments mirror + notifications
-- Lưu ý:
--   - Bảng payments ở đây là bản mirror từ payment-service (Kafka consumer)
--   - Bảng notifications: recipientId = user_id (string), tham chiếu logical auth-service
--   - Nếu notification-service dùng H2/in-memory thì bỏ qua file này
-- =============================================================

-- -------------------------------------
-- PAYMENTS (mirror từ payment-service, nhận qua Kafka event)
-- -------------------------------------
INSERT INTO payments (id, payment_id, is_payed, payment_status, order_id, user_id)
VALUES
    (1, 1, true,  'COMPLETED',   1, 1),
    (2, 2, true,  'COMPLETED',   3, 2),
    (3, 3, true,  'COMPLETED',   5, 3),
    (4, 4, false, 'IN_PROGRESS', 2, 1),
    (5, 5, false, 'NOT_STARTED', 4, 2),
    (6, 6, false, 'NOT_STARTED', 6, 3)
ON CONFLICT (id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('payments', 'id'), 6, true);

-- -------------------------------------
-- NOTIFICATIONS
-- notificationType: ORDER_CONFIRMED | PAYMENT_SUCCESS | SHIPPING_UPDATE
-- recipientId = user_id (as string)
-- link: deep link vào order detail
-- -------------------------------------
INSERT INTO notifications (id, content, recipient_id, read, timestamp, notification_type, link)
VALUES
    (1,
     'Đơn hàng #1 của bạn đã được xác nhận. iPhone 15 Pro Max 256GB đang được chuẩn bị.',
     '1', false, '2024-07-05 10:35:00', 'ORDER_CONFIRMED', '/orders/1'),

    (2,
     'Thanh toán đơn hàng #1 thành công! Số tiền: 30,000,000đ.',
     '1', true, '2024-07-05 10:40:00', 'PAYMENT_SUCCESS', '/payments/1'),

    (3,
     'Đơn hàng #3 của bạn đã được xác nhận. MacBook Pro 14 M3 đang được chuẩn bị.',
     '2', false, '2024-07-08 09:20:00', 'ORDER_CONFIRMED', '/orders/3'),

    (4,
     'Thanh toán đơn hàng #3 thành công! Số tiền: 40,000,000đ.',
     '2', true, '2024-07-08 09:25:00', 'PAYMENT_SUCCESS', '/payments/2'),

    (5,
     'Đơn hàng #5 của bạn đã được xác nhận. AirPods Pro 2 đang được chuẩn bị.',
     '3', false, '2024-07-10 11:05:00', 'ORDER_CONFIRMED', '/orders/5'),

    (6,
     'Thanh toán đơn hàng #5 thành công! Số tiền: 12,000,000đ.',
     '3', false, '2024-07-10 11:10:00', 'PAYMENT_SUCCESS', '/payments/3')
ON CONFLICT (id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('notifications', 'id'), 6, true);
