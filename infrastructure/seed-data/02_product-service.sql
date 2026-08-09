-- =============================================================
-- 02_product-service.sql
-- Database: productservice
-- Mô tả: Seed categories + products
-- Lưu ý: category_id và product_id hardcode để các service khác
--        (order, favourite, rating, promotion, inventory) tham chiếu
-- =============================================================

-- -------------------------------------
-- CATEGORIES (5 danh mục cha)
-- -------------------------------------
INSERT INTO categories (category_id, category_title, image_url, parent_category_id, created_at, updated_at)
VALUES
    (1, 'Điện thoại', 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?q=80&w=300&auto=format&fit=crop', NULL, NOW(), NOW()),
    (2, 'Laptop',     'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?q=80&w=300&auto=format&fit=crop', NULL, NOW(), NOW()),
    (3, 'Đồng hồ',    'https://images.unsplash.com/photo-1524805444758-089113d48a6d?q=80&w=300&auto=format&fit=crop', NULL, NOW(), NOW()),
    (4, 'Tai nghe',   'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=300&auto=format&fit=crop', NULL, NOW(), NOW()),
    (5, 'Máy ảnh',    'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?q=80&w=300&auto=format&fit=crop', NULL, NOW(), NOW())
ON CONFLICT (category_id) DO NOTHING;

-- Reset sequence
SELECT setval(pg_get_serial_sequence('categories', 'category_id'), 5, true);

-- -------------------------------------
-- PRODUCTS (10 sản phẩm điện tử)
-- product_id: 1–10, hardcode
-- category_id tham chiếu bảng categories bên trên
-- -------------------------------------
INSERT INTO products (product_id, product_title, image_url, sku, price_unit, quantity, category_id, created_at, updated_at)
VALUES
    -- Điện thoại (category_id = 1)
    (1,  'iPhone 15 Pro Max 256GB',   'https://images.unsplash.com/photo-1696446701796-da61225697cc?q=80&w=500&auto=format&fit=crop', 'IP15PM256',   30000000.0, 50, 1, NOW(), NOW()),
    (2,  'Samsung Galaxy S24 Ultra',  'https://images.unsplash.com/photo-1610945265064-3234eb3bf363?q=80&w=500&auto=format&fit=crop', 'S24ULTRA',    28000000.0, 30, 1, NOW(), NOW()),

    -- Laptop (category_id = 2)
    (3,  'MacBook Pro 14 M3',         'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?q=80&w=500&auto=format&fit=crop', 'MBP14M3',     40000000.0, 20, 2, NOW(), NOW()),
    (4,  'Dell XPS 15 9530',          'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?q=80&w=500&auto=format&fit=crop', 'XPS159530',   38000000.0, 15, 2, NOW(), NOW()),

    -- Đồng hồ (category_id = 3)
    (5,  'Apple Watch Series 9',      'https://images.unsplash.com/photo-1434493789847-2902a524c14c?q=80&w=500&auto=format&fit=crop', 'AW9',         10000000.0,100, 3, NOW(), NOW()),
    (6,  'Garmin Fenix 7',            'https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?q=80&w=500&auto=format&fit=crop', 'GARMINF7',    15000000.0, 40, 3, NOW(), NOW()),

    -- Tai nghe (category_id = 4)
    (7,  'Sony WH-1000XM5',           'https://images.unsplash.com/photo-1618366712010-f4ae9c647dcb?q=80&w=500&auto=format&fit=crop', 'SONYXM5',      8000000.0, 80, 4, NOW(), NOW()),
    (8,  'AirPods Pro 2',             'https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?q=80&w=500&auto=format&fit=crop', 'APRO2',        6000000.0,150, 4, NOW(), NOW()),

    -- Máy ảnh (category_id = 5)
    (9,  'Sony Alpha A7 IV',          'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?q=80&w=500&auto=format&fit=crop', 'SONYA74',     60000000.0, 10, 5, NOW(), NOW()),
    (10, 'Canon EOS R6 Mark II',      'https://images.unsplash.com/photo-1502920917128-1aa500764cbd?q=80&w=500&auto=format&fit=crop', 'CANONR6M2',   55000000.0, 12, 5, NOW(), NOW())
ON CONFLICT (product_id) DO NOTHING;

-- Reset sequence
SELECT setval(pg_get_serial_sequence('products', 'product_id'), 10, true);
