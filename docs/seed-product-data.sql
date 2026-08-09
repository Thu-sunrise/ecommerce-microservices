-- Xóa dữ liệu cũ nếu có (bỏ qua foreign key checks)
TRUNCATE TABLE products CASCADE;
TRUNCATE TABLE categories CASCADE;

-- Tạo danh mục
INSERT INTO categories (category_id, category_title, image_url, created_at, updated_at) VALUES 
(1, 'Điện thoại', 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?q=80&w=300&auto=format&fit=crop', NOW(), NOW()),
(2, 'Laptop', 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?q=80&w=300&auto=format&fit=crop', NOW(), NOW()),
(3, 'Đồng hồ', 'https://images.unsplash.com/photo-1524805444758-089113d48a6d?q=80&w=300&auto=format&fit=crop', NOW(), NOW()),
(4, 'Tai nghe', 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=300&auto=format&fit=crop', NOW(), NOW()),
(5, 'Máy ảnh', 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?q=80&w=300&auto=format&fit=crop', NOW(), NOW());

-- Tạo sản phẩm mẫu
INSERT INTO products (product_title, image_url, sku, price_unit, quantity, category_id, created_at, updated_at) VALUES 
('iPhone 15 Pro Max 256GB', 'https://images.unsplash.com/photo-1696446701796-da61225697cc?q=80&w=500&auto=format&fit=crop', 'IP15PM256', 30000000.0, 50, 1, NOW(), NOW()),
('Samsung Galaxy S24 Ultra', 'https://images.unsplash.com/photo-1610945265064-3234eb3bf363?q=80&w=500&auto=format&fit=crop', 'S24ULTRA', 28000000.0, 30, 1, NOW(), NOW()),
('MacBook Pro 14 M3', 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?q=80&w=500&auto=format&fit=crop', 'MBP14M3', 40000000.0, 20, 2, NOW(), NOW()),
('Dell XPS 15 9530', 'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?q=80&w=500&auto=format&fit=crop', 'XPS159530', 38000000.0, 15, 2, NOW(), NOW()),
('Apple Watch Series 9', 'https://images.unsplash.com/photo-1434493789847-2902a524c14c?q=80&w=500&auto=format&fit=crop', 'AW9', 10000000.0, 100, 3, NOW(), NOW()),
('Garmin Fenix 7', 'https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?q=80&w=500&auto=format&fit=crop', 'GARMINF7', 15000000.0, 40, 3, NOW(), NOW()),
('Sony WH-1000XM5', 'https://images.unsplash.com/photo-1618366712010-f4ae9c647dcb?q=80&w=500&auto=format&fit=crop', 'SONYXM5', 8000000.0, 80, 4, NOW(), NOW()),
('AirPods Pro 2', 'https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?q=80&w=500&auto=format&fit=crop', 'APRO2', 6000000.0, 150, 4, NOW(), NOW()),
('Sony Alpha A7 IV', 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?q=80&w=500&auto=format&fit=crop', 'SONYA74', 60000000.0, 10, 5, NOW(), NOW()),
('Canon EOS R6', 'https://images.unsplash.com/photo-1502920917128-1aa500764cbd?q=80&w=500&auto=format&fit=crop', 'CANONR6', 55000000.0, 12, 5, NOW(), NOW());

-- Reset sequence for categories if needed
SELECT setval(pg_get_serial_sequence('categories', 'category_id'), coalesce(max(category_id), 1), max(category_id) IS NOT null) FROM categories;
