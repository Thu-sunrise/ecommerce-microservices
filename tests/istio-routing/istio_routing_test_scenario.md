# Hướng dẫn Kiểm thử Istio Routing (Traffic Splitting & Advanced Routing)

Thư mục này chứa các kịch bản kiểm thử (Test Scripts) tự động để xác minh tính năng định tuyến nâng cao của Istio Service Mesh đối với `product-service`.

## Cơ chế hoạt động

Các script trong thư mục này được thiết kế để không can thiệp vào mã nguồn gốc của bạn. Khi chạy, chúng sẽ tự động:
1. Đảm bảo file cấu hình `product-service-v2.yaml` đã được Apply lên cụm K8s.
2. Tạo nhanh một Pod tạm thời tên là `curl-...` (chứa image curl) để đóng vai trò làm client. Pod này sẽ giả lập hành vi người dùng truy cập từ bên trong mạng lưới (Mesh) của Kubernetes.
3. Thu thập và đếm trực tiếp **Access Logs** từ Envoy Proxy (sidecar `istio-proxy`) ở cả 2 phiên bản v1 và v2 để đối chiếu.

---

## Danh sách bài Test

### 1. Traffic Splitting (Canary Release 90/10)
Xác minh xem khi truy cập bình thường (không có điều kiện đặc biệt), Istio có chia tải **90%** lượng request vào `v1` và **10%** vào `v2` đúng như file `virtual-service-product.yaml` quy định hay không.

**Cách thực hiện chi tiết:**
1. Đảm bảo bạn đã `export KUBECONFIG` để kết nối tới cụm K8s.
2. Mở Terminal, di chuyển vào thư mục bài test: `cd tests/istio-routing`.
3. Chạy lệnh: `./01-test-traffic-split.sh`.
4. Quan sát số liệu log được script thống kê tự động trên màn hình Terminal.

**Kỳ vọng (Kết quả Tốt / Xấu):**
- **Trường hợp Tốt 🟢:** Script tự động bắn 100 request người dùng vô danh (không có header VIP). Kết quả đếm log từ proxy trả về tỷ lệ xấp xỉ 90/10 (Ví dụ: `V1: 88 requests` và `V2: 12 requests`). Việc chênh lệch vài số là bình thường trong cơ chế thống kê của thuật toán, miễn là V1 áp đảo hoàn toàn đúng như kỳ vọng.
- **Trường hợp Xấu 🔴:** Kết quả báo về 100% request đều lọt vào V1, hoặc chia đều 50/50. Điều này báo động lỗi cấu hình `VirtualService` hoặc `DestinationRule`, Istio không thể nhận diện được các tập con (subset) nên đành chia tải mù quáng.
### 2. Advanced Routing (Premium User VIP)
Xác minh xem nếu có header đặc biệt `x-user-role: premium`, Istio có ép buộc 100% người dùng đó vào `v2` (bỏ qua rule 90/10) hay không.

**Cách thực hiện chi tiết:**
1. Tại Terminal đang mở, tiếp tục chạy lệnh: `./02-test-premium-routing.sh`.
2. Chờ script mô phỏng 20 người dùng VIP (có gắn kèm HTTP Header `x-user-role: premium` vào từng cú click) và theo dõi kết quả.

**Kỳ vọng (Kết quả Tốt / Xấu):**
- **Trường hợp Tốt 🟢:** Cả 20 requests VIP đều bị Istio "tóm cổ" và điều phối chính xác 100% sang bản nâng cấp V2. Trên màn hình sẽ báo log của `V2` tăng thêm 20, trong khi `V1` nhận được `0` request nào. Điều này chứng minh luật ưu tiên (Match Header) hoạt động hoàn hảo, đè bẹp cả luật 90/10 ở Kịch bản 1.
- **Trường hợp Xấu 🔴:** User VIP nhưng lại bị đẩy vào bản cũ V1, hoặc bị quay mòng mòng (timeout). Đây là lỗi nghiêm trọng ảnh hưởng đến khách hàng trả phí, lỗi này thường do viết sai chính tả tên Header trong file `.yaml`.

---

## Kiểm chứng trực quan bằng Kiali Dashboard

Bên cạnh việc nhìn kết quả text ở Terminal, cách tốt nhất để chứng minh Istio đang hoạt động là xem biểu đồ luồng dữ liệu (Traffic Graph) trên giao diện.

1. Hãy mở một tab Terminal mới (chưa chạy script) và gõ lệnh:
   ```bash
   istioctl dashboard kiali
   ```
2. Giao diện Kiali sẽ được bật lên ở trình duyệt (thường là `http://localhost:20001`).
3. Truy cập mục **Graph** ở cột menu trái, chọn Namespace là `ecommerce`.
4. Bật chế độ hiển thị **Traffic Distribution / Percentage** ở phần Display.
5. Bây giờ, hãy chạy 2 script bash ở tab Terminal kia, bạn sẽ thấy biểu đồ Kiali vẽ luồng mũi tên tách ra thành 2 nhánh (v1 và v2) với thông số % nhảy trực tiếp trên màn hình cực kỳ sống động!
