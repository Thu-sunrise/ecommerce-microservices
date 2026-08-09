#!/usr/bin/env bash
# =============================================================
# run-deployed.sh — Chạy seed data CHỈ cho các service được deploy
# =============================================================
# Services được deploy:
#   - product-service   → productservice DB
#   - order-service     → orderservice DB
#   - payment-service   → paymentservice DB
#   - inventory-service → inventoryservice DB
#   - shipping-service  → shippingservice DB
#
# Lưu ý: auth-service KHÔNG seed vì users được quản lý bởi Keycloak.
#   user_id trong các file seed (07, 08, 09) là placeholder — cần cập nhật
#   lại theo user_id thật sau khi Keycloak sync về authservice.
#
# Cách dùng:
#   ./seed-data/run-deployed.sh
#   PG_HOST=myhost PG_PASS=secret ./seed-data/run-deployed.sh
# =============================================================

set -euo pipefail

PG_HOST="${PG_HOST:-ep-spring-shape-aomh8696.c-2.ap-southeast-1.aws.neon.tech}"
PG_PORT="${PG_PORT:-5432}"
PG_USER="${PG_USER:-neondb_owner}"
PG_PASS="${PG_PASS:-npg_g7y3uIFWsNAQ}"

# Bật SSL mode cho kết nối Neon DB
export PGSSLMODE="require"

# ID của user thật (Sau khi đồng bộ Keycloak về)
# Truyền biến môi trường khi chạy script nếu ID khác 1,2,3
USER_ID_1="${USER_ID_1:-1}"
USER_ID_2="${USER_ID_2:-2}"
USER_ID_3="${USER_ID_3:-3}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Màu sắc
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

log_info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
log_ok()      { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*"; }
log_section() { echo -e "\n${BLUE}══════════════════════════════════════${NC}"; echo -e "${BLUE} $*${NC}"; echo -e "${BLUE}══════════════════════════════════════${NC}"; }

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
        -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$db" \
        -v USER_ID_1="$USER_ID_1" \
        -v USER_ID_2="$USER_ID_2" \
        -v USER_ID_3="$USER_ID_3" \
        -f "$SCRIPT_DIR/$file" \
        --set ON_ERROR_STOP=1 -q 2>&1; then
        log_ok "  ✓ $file"
    else
        log_error "  ✗ Lỗi khi chạy: $file (database: $db)"
        exit 1
    fi
}

check_connection() {
    log_section "Kiểm tra kết nối PostgreSQL"
    log_info "Host: $PG_HOST:$PG_PORT | User: $PG_USER"
    if ! PGPASSWORD="$PG_PASS" psql \
        -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" \
        -d "neondb" -c "SELECT 1;" -q > /dev/null 2>&1; then
        log_error "Không thể kết nối PostgreSQL. Kiểm tra lại host/credentials."
        exit 1
    fi
    log_ok "Kết nối thành công!"
}

# =============================================
# MAIN
# =============================================
log_section "🌱 Seed Data — Deployed Services Only"
log_info "Services: product · inventory · order · payment · shipping"
log_warn "auth-service bị bỏ qua — users do Keycloak quản lý"
log_info "Bắt đầu lúc: $(date '+%Y-%m-%d %H:%M:%S')"

check_connection

# Thứ tự: product → inventory → order → payment → shipping
log_section "1/5 — product-service"
run_seed "product_service"   "02_product-service.sql" "categories + products"

log_section "2/5 — inventory-service"
run_seed "inventory_service" "03_inventory-service.sql" "inventory (10 records)"

log_section "3/5 — order-service"
run_seed "order_service"     "07_order-service.sql"   "carts + orders"

log_section "4/5 — payment-service"
run_seed "payment_service"   "08_payment-service.sql" "payments"

log_section "5/5 — shipping-service"
run_seed "shipping_service"  "09_shipping-service.sql" "order_items"

log_section "✅ Hoàn thành!"
log_ok "Seed data đã được nạp vào 5 databases."
log_warn "Nhớ truyền đúng USER_ID_1, USER_ID_2, USER_ID_3 nếu user IDs của bạn khác 1, 2, 3!"
log_info "Kết thúc lúc: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
log_info "💡 Xác minh nhanh:"
echo "   PGPASSWORD=\$PG_PASS psql -h \$PG_HOST -U \$PG_USER -d product_service  -c 'SELECT product_id, product_title FROM products;'"
echo "   PGPASSWORD=\$PG_PASS psql -h \$PG_HOST -U \$PG_USER -d inventory_service -c 'SELECT id, \"productName\", quantity FROM inventory;'"
echo "   PGPASSWORD=\$PG_PASS psql -h \$PG_HOST -U \$PG_USER -d order_service    -c 'SELECT order_id, order_fee FROM orders;'"
echo ""
