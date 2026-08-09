#!/usr/bin/env bash
# =============================================================
# run-all.sh — Chạy toàn bộ seed data theo thứ tự dependency
# =============================================================
# Cách dùng:
#   ./seed-data/run-all.sh
#   PG_HOST=myhost PG_PASS=secret ./seed-data/run-all.sh
#
# Biến môi trường (có thể override):
#   PG_HOST  - host PostgreSQL (default: localhost)
#   PG_PORT  - port PostgreSQL (default: 5432)
#   PG_USER  - postgres user  (default: postgres)
#   PG_PASS  - postgres pass  (default: postgres)
# =============================================================

set -euo pipefail

PG_HOST="${PG_HOST:-ep-spring-shape-aomh8696.c-2.ap-southeast-1.aws.neon.tech}"
PG_PORT="${PG_PORT:-5432}"
PG_USER="${PG_USER:-neondb_owner}"
PG_PASS="${PG_PASS:-npg_g7y3uIFWsNAQ}"

# Bật SSL mode cho kết nối Neon DB
export PGSSLMODE="require"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Màu sắc output
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

log_info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
log_ok()      { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*"; }
log_section() { echo -e "\n${BLUE}══════════════════════════════════════${NC}"; echo -e "${BLUE} $*${NC}"; echo -e "${BLUE}══════════════════════════════════════${NC}"; }

# -------------------------------------
# Hàm chạy một file seed vào database
# -------------------------------------
run_seed() {
    local db="$1"
    local file="$2"
    local label="$3"

    if [ ! -f "$SCRIPT_DIR/$file" ]; then
        log_warn "File không tồn tại, bỏ qua: $file"
        return 0
    fi

    log_info "▶ Seeding [$label] → database: $db"

    if PGPASSWORD="$PG_PASS" psql \
        -h "$PG_HOST" \
        -p "$PG_PORT" \
        -U "$PG_USER" \
        -d "$db" \
        -f "$SCRIPT_DIR/$file" \
        --set ON_ERROR_STOP=1 \
        -q 2>&1; then
        log_ok "  ✓ $file"
    else
        log_error "  ✗ Lỗi khi chạy: $file (database: $db)"
        exit 1
    fi
}

# -------------------------------------
# Kiểm tra kết nối postgres
# -------------------------------------
check_connection() {
    log_section "Kiểm tra kết nối PostgreSQL"
    log_info "Host: $PG_HOST:$PG_PORT | User: $PG_USER"

    if ! PGPASSWORD="$PG_PASS" psql \
        -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" \
        -d "neondb" -c "SELECT 1;" -q > /dev/null 2>&1; then
        log_error "Không thể kết nối PostgreSQL tại $PG_HOST:$PG_PORT"
        log_error "Hãy chắc chắn PostgreSQL đang chạy (docker-compose up postgres)"
        exit 1
    fi
    log_ok "Kết nối thành công!"
}

# =============================================
# MAIN
# =============================================
log_section "🌱 Ecommerce Microservices — Seed Data Runner"
log_info "Bắt đầu lúc: $(date '+%Y-%m-%d %H:%M:%S')"

check_connection

log_section "Bước 1 — Dữ liệu nền tảng"
run_seed "auth_service"     "01_auth-service.sql"    "auth-service (roles + users)"

log_section "Bước 2 — Sản phẩm & Danh mục"
run_seed "product_service"  "02_product-service.sql" "product-service (categories + products)"

log_section "Bước 3 — Kho hàng, Thuế, Media"
run_seed "inventory_service" "03_inventory-service.sql" "inventory-service"
run_seed "tax_service"       "04_tax-service.sql"       "tax-service (tax_class + tax_rate)"
run_seed "media_service"     "05_media-service.sql"     "media-service (media records)"

log_section "Bước 4 — Khuyến mãi"
run_seed "promotion_service" "06_promotion-service.sql" "promotion-service (promotions + apply)"

log_section "Bước 5 — Đơn hàng"
run_seed "order_service"    "07_order-service.sql"   "order-service (carts + orders)"

log_section "Bước 6 — Thanh toán & Vận chuyển"
run_seed "payment_service"  "08_payment-service.sql" "payment-service (payments)"
run_seed "shipping_service" "09_shipping-service.sql" "shipping-service (order_items)"

log_section "Bước 7 — Tương tác người dùng"
run_seed "favourite_service" "10_favourite-service.sql" "favourite-service (favourites)"
run_seed "rating_service"    "11_rating-service.sql"    "rating-service (ratings)"

log_section "Bước 8 — Thông báo & Lịch sử khuyến mãi"
run_seed "notification_service" "12_notification-service.sql"    "notification-service (nếu có DB)"
run_seed "promotion_service"    "13_promotion-service-usage.sql" "promotion-service (usage history)"

log_section "✅ Hoàn thành!"
echo ""
log_ok "Seed data đã được nạp thành công vào tất cả databases."
log_info "Kết thúc lúc: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
log_info "💡 Để xác minh, chạy:"
echo "   PGPASSWORD=\$PG_PASS psql -h \$PG_HOST -U \$PG_USER -d product_service -c 'SELECT count(*) FROM products;'"
echo "   PGPASSWORD=\$PG_PASS psql -h \$PG_HOST -U \$PG_USER -d auth_service    -c 'SELECT user_name, email FROM users;'"
echo ""
