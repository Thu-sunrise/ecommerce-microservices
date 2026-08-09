-- =============================================================
-- 06_promotion-service.sql
-- Database: promotionservice
-- Mô tả: Seed promotion + promotion_apply
-- Lưu ý:
--   - promotion_apply.category_id tham chiếu logical tới product-service
--   - promotion_apply.product_id   tham chiếu logical tới product-service
--   - promotion_usage seed riêng trong file 13 (cần order_id từ order-service)
-- =============================================================

-- -------------------------------------
-- PROMOTION
-- Enum discount_type: PERCENTAGE | FIXED_AMOUNT
-- Enum usage_type:    UNLIMITED | LIMITED
-- Enum apply_to:      ALL | CATEGORY | PRODUCT
-- -------------------------------------
INSERT INTO promotion (
    id, name, slug, description, coupon_code,
    discount_type, discount_percentage, discount_amount,
    is_active, usage_type, usage_limit, usage_count,
    apply_to, minimum_order_purchase_amount,
    start_date, end_date,
    created_by, created_on, last_modified_by, last_modified_on
)
VALUES
    (
        1,
        'Summer Sale 2024 - Giảm 10% Điện Thoại',
        'summer-sale-2024-dien-thoai',
        'Giảm 10% cho tất cả sản phẩm danh mục Điện Thoại trong mùa hè 2024',
        'SUMMER10',
        'PERCENTAGE', 10, 0,
        true, 'LIMITED', 100, 0,
        'CATEGORY', 5000000,
        '2024-06-01 00:00:00+07', '2024-08-31 23:59:59+07',
        'admin_em', NOW(), 'admin_em', NOW()
    ),
    (
        2,
        'Flash Deal - Giảm 500K Laptop',
        'flash-deal-giam-500k-laptop',
        'Giảm ngay 500.000đ khi mua Laptop, áp dụng đơn từ 30 triệu',
        'FLASH500',
        'FIXED_AMOUNT', 0, 500000,
        true, 'LIMITED', 50, 0,
        'CATEGORY', 30000000,
        '2024-07-01 00:00:00+07', '2024-07-31 23:59:59+07',
        'admin_em', NOW(), 'admin_em', NOW()
    ),
    (
        3,
        'VIP Member - Giảm 5% Tất Cả',
        'vip-member-giam-5-phan-tram',
        'Ưu đãi đặc biệt cho thành viên VIP, giảm 5% không giới hạn đơn hàng',
        'VIP5ALL',
        'PERCENTAGE', 5, 0,
        true, 'UNLIMITED', 0, 0,
        'ALL', 0,
        '2024-01-01 00:00:00+07', '2024-12-31 23:59:59+07',
        'admin_em', NOW(), 'admin_em', NOW()
    )
ON CONFLICT (id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('promotion', 'id'), 3, true);

-- -------------------------------------
-- PROMOTION_APPLY
-- Promotion 1 → áp dụng category_id = 1 (Điện thoại)
-- Promotion 2 → áp dụng category_id = 2 (Laptop)
-- Promotion 3 → apply_to = ALL, không cần promotion_apply record
-- -------------------------------------
INSERT INTO promotion_apply (
    id, promotion_id, category_id, product_id, brand_id,
    created_by, created_on, last_modified_by, last_modified_on
)
VALUES
    (1, 1, 1, NULL, NULL, 'admin_em', NOW(), 'admin_em', NOW()),
    (2, 2, 2, NULL, NULL, 'admin_em', NOW(), 'admin_em', NOW()),
    -- Promotion 1 cũng áp dụng cho sản phẩm iPhone cụ thể (product_id=1)
    (3, 1, NULL, 1,  NULL, 'admin_em', NOW(), 'admin_em', NOW())
ON CONFLICT (id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('promotion_apply', 'id'), 3, true);
