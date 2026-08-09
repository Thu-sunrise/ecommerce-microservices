-- =============================================================
-- 01_auth-service.sql
-- Database: authservice
-- Mô tả: Seed roles + users + user_role
-- Lưu ý: user_id hardcode để các service khác tham chiếu được
-- =============================================================

-- -------------------------------------
-- ROLES (đã có trong Liquibase, idempotent)
-- -------------------------------------
INSERT INTO roles (id, role_name) VALUES (1, 'USER')  ON CONFLICT (id) DO NOTHING;
INSERT INTO roles (id, role_name) VALUES (2, 'PM')    ON CONFLICT (id) DO NOTHING;
INSERT INTO roles (id, role_name) VALUES (3, 'ADMIN') ON CONFLICT (id) DO NOTHING;

-- Reset sequence
SELECT setval(pg_get_serial_sequence('roles', 'id'), 3, true);

-- -------------------------------------
-- USERS (5 users: 3 customer, 1 PM, 1 Admin)
-- keycloak_user_id: placeholder UUID
-- -------------------------------------
INSERT INTO users (user_id, full_name, user_name, email, gender, phone_number, image_url, keycloak_user_id)
VALUES
    (1, 'Nguyễn Văn An',   'user_an',    'an.nguyen@example.com',    'MALE',   '0901234501', 'https://i.pravatar.cc/150?img=1',  'aaaaaaaa-0001-4000-a000-000000000001'),
    (2, 'Trần Thị Bích',   'user_bich',  'bich.tran@example.com',    'FEMALE', '0901234502', 'https://i.pravatar.cc/150?img=2',  'aaaaaaaa-0001-4000-a000-000000000002'),
    (3, 'Lê Minh Cường',   'user_cuong', 'cuong.le@example.com',      'MALE',   '0901234503', 'https://i.pravatar.cc/150?img=3',  'aaaaaaaa-0001-4000-a000-000000000003'),
    (4, 'Phạm Thanh Dung', 'pm_dung',    'dung.pham.pm@example.com',  'FEMALE', '0901234504', 'https://i.pravatar.cc/150?img=4',  'aaaaaaaa-0001-4000-a000-000000000004'),
    (5, 'Hoàng Văn Em',    'admin_em',   'em.hoang.admin@example.com','MALE',   '0901234505', 'https://i.pravatar.cc/150?img=5',  'aaaaaaaa-0001-4000-a000-000000000005')
ON CONFLICT (user_id) DO NOTHING;

-- Reset sequence
SELECT setval(pg_get_serial_sequence('users', 'user_id'), 5, true);

-- -------------------------------------
-- USER_ROLE
-- user 1,2,3 → ROLE USER
-- user 4     → ROLE PM
-- user 5     → ROLE ADMIN
-- -------------------------------------
INSERT INTO user_role (user_id, role_id) VALUES (1, 1) ON CONFLICT DO NOTHING;
INSERT INTO user_role (user_id, role_id) VALUES (2, 1) ON CONFLICT DO NOTHING;
INSERT INTO user_role (user_id, role_id) VALUES (3, 1) ON CONFLICT DO NOTHING;
INSERT INTO user_role (user_id, role_id) VALUES (4, 2) ON CONFLICT DO NOTHING;
INSERT INTO user_role (user_id, role_id) VALUES (5, 3) ON CONFLICT DO NOTHING;
