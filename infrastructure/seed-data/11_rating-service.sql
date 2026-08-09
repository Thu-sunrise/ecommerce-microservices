-- =============================================================
-- 11_rating-service.sql
-- Database: ratingservice
-- Mô tả: Seed rating (đánh giá sản phẩm)
-- Lưu ý:
--   - product_id   tham chiếu logical tới product-service
--   - created_by   là username từ auth-service
--   - rating_star: 1–5
-- =============================================================

INSERT INTO rating (
    id, created_by, created_on, last_modified_by, last_modified_on,
    content, first_name, last_name, product_id, product_name, rating_star
)
VALUES
    -- user 1 (Nguyễn Văn An) đánh giá iPhone 15 Pro Max
    (1, 'user_an', '2024-07-10 10:00:00', 'user_an', '2024-07-10 10:00:00',
     'Máy rất mượt, camera xuất sắc! Pin trâu hơn mình nghĩ.', 'An', 'Nguyễn Văn',
     1, 'iPhone 15 Pro Max 256GB', 5),

    -- user 2 (Trần Thị Bích) đánh giá MacBook Pro M3
    (2, 'user_bich', '2024-07-12 14:00:00', 'user_bich', '2024-07-12 14:00:00',
     'Hiệu năng cực mạnh, màn hình đẹp. Hơi nóng khi load nặng.', 'Bích', 'Trần Thị',
     3, 'MacBook Pro 14 M3', 4),

    -- user 3 (Lê Minh Cường) đánh giá AirPods Pro 2
    (3, 'user_cuong', '2024-07-14 09:30:00', 'user_cuong', '2024-07-14 09:30:00',
     'Chống ồn tốt lắm, âm thanh hay. Đáng tiền!', 'Cường', 'Lê Minh',
     8, 'AirPods Pro 2', 5),

    -- user 1 đánh giá Sony WH-1000XM5
    (4, 'user_an', '2024-07-15 16:00:00', 'user_an', '2024-07-15 16:00:00',
     'Chống ồn hơi kém hơn kỳ vọng, nhưng âm thanh bass rất hay.', 'An', 'Nguyễn Văn',
     7, 'Sony WH-1000XM5', 4),

    -- user 2 đánh giá Apple Watch Series 9
    (5, 'user_bich', '2024-07-17 11:00:00', 'user_bich', '2024-07-17 11:00:00',
     'Đồng hồ đẹp, nhiều tính năng sức khỏe hữu ích. Hài lòng!', 'Bích', 'Trần Thị',
     5, 'Apple Watch Series 9', 5),

    -- user 3 đánh giá Samsung Galaxy S24 Ultra
    (6, 'user_cuong', '2024-07-20 10:00:00', 'user_cuong', '2024-07-20 10:00:00',
     'Bút S-Pen rất tiện. Camera zoom 100x ấn tượng. Máy hơi to.', 'Cường', 'Lê Minh',
     2, 'Samsung Galaxy S24 Ultra', 4)
ON CONFLICT (id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('rating', 'id'), 6, true);
