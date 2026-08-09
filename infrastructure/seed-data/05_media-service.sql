-- =============================================================
-- 05_media-service.sql
-- Database: mediaservice
-- Mô tả: Seed media records — ảnh Unsplash cho từng sản phẩm
-- Lưu ý: media-service không có FK cứng tới product-service,
--        liên kết qua file_name theo quy ước "product-{product_id}"
-- =============================================================

INSERT INTO media (id, caption, file_name, file_path, media_type)
VALUES
    (1,  'iPhone 15 Pro Max 256GB',   'product-1.jpg',  'https://images.unsplash.com/photo-1696446701796-da61225697cc?q=80&w=800&auto=format&fit=crop', 'IMAGE'),
    (2,  'Samsung Galaxy S24 Ultra',  'product-2.jpg',  'https://images.unsplash.com/photo-1610945265064-3234eb3bf363?q=80&w=800&auto=format&fit=crop', 'IMAGE'),
    (3,  'MacBook Pro 14 M3',         'product-3.jpg',  'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?q=80&w=800&auto=format&fit=crop', 'IMAGE'),
    (4,  'Dell XPS 15 9530',          'product-4.jpg',  'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?q=80&w=800&auto=format&fit=crop', 'IMAGE'),
    (5,  'Apple Watch Series 9',      'product-5.jpg',  'https://images.unsplash.com/photo-1434493789847-2902a524c14c?q=80&w=800&auto=format&fit=crop', 'IMAGE'),
    (6,  'Garmin Fenix 7',            'product-6.jpg',  'https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?q=80&w=800&auto=format&fit=crop', 'IMAGE'),
    (7,  'Sony WH-1000XM5',           'product-7.jpg',  'https://images.unsplash.com/photo-1618366712010-f4ae9c647dcb?q=80&w=800&auto=format&fit=crop', 'IMAGE'),
    (8,  'AirPods Pro 2',             'product-8.jpg',  'https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?q=80&w=800&auto=format&fit=crop', 'IMAGE'),
    (9,  'Sony Alpha A7 IV',          'product-9.jpg',  'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?q=80&w=800&auto=format&fit=crop', 'IMAGE'),
    (10, 'Canon EOS R6 Mark II',      'product-10.jpg', 'https://images.unsplash.com/photo-1502920917128-1aa500764cbd?q=80&w=800&auto=format&fit=crop', 'IMAGE'),
    -- Banner / hero images
    (11, 'Homepage Banner - Tech',    'banner-1.jpg',   'https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=1920&auto=format&fit=crop', 'IMAGE'),
    (12, 'Homepage Banner - Mobile',  'banner-2.jpg',   'https://images.unsplash.com/photo-1526406915894-7bcd65f60845?q=80&w=1920&auto=format&fit=crop', 'IMAGE')
ON CONFLICT (id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('media', 'id'), 12, true);
