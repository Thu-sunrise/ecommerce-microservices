-- =============================================================
-- 04_tax-service.sql
-- Database: taxservice
-- Mô tả: Seed tax_class + tax_rate
-- Lưu ý: Đây là bản tập trung hoá từ Liquibase changeset đã có,
--        thêm các tax rate bổ sung cho nhiều vùng
-- =============================================================

-- -------------------------------------
-- TAX CLASS
-- -------------------------------------
INSERT INTO tax_class (id, name, created_by, created_on, last_modified_by, last_modified_on)
VALUES
    (1, 'Value Added Tax (VAT)',   '00000000-0000-0000-0000-000000000001', NOW(), '00000000-0000-0000-0000-000000000001', NOW()),
    (2, 'Import Duty Tax',        '00000000-0000-0000-0000-000000000001', NOW(), '00000000-0000-0000-0000-000000000001', NOW()),
    (3, 'Special Consumption Tax','00000000-0000-0000-0000-000000000001', NOW(), '00000000-0000-0000-0000-000000000001', NOW())
ON CONFLICT (id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('tax_class', 'id'), 3, true);

-- -------------------------------------
-- TAX RATE
-- Liên kết tới tax_class qua tax_class_id
-- -------------------------------------
INSERT INTO tax_rate (id, rate, zip_code, tax_class_id, created_by, created_on, last_modified_by, last_modified_on)
VALUES
    (1, 8.0,  '70000', 1, '00000000-0000-0000-0000-000000000001', NOW(), '00000000-0000-0000-0000-000000000001', NOW()),
    (2, 8.0,  '10000', 1, '00000000-0000-0000-0000-000000000001', NOW(), '00000000-0000-0000-0000-000000000001', NOW()),
    (3, 10.0, '50000', 1, '00000000-0000-0000-0000-000000000001', NOW(), '00000000-0000-0000-0000-000000000001', NOW()),
    (4, 5.0,  '70000', 2, '00000000-0000-0000-0000-000000000001', NOW(), '00000000-0000-0000-0000-000000000001', NOW()),
    (5, 20.0, '70000', 3, '00000000-0000-0000-0000-000000000001', NOW(), '00000000-0000-0000-0000-000000000001', NOW())
ON CONFLICT (id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('tax_rate', 'id'), 5, true);
