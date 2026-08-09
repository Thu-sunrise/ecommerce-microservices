# Kịch bản Kiểm thử Độ bền bỉ (Resilience & Chaos Engineering) với Istio

Thư mục này chứa các kịch bản kiểm thử giả lập lỗi mạng (Fault Injection) sử dụng khả năng của Istio Service Mesh, nhằm đảm bảo hệ thống và các Microservices có khả năng chống chịu hoặc báo lỗi đúng cách khi có một thành phần bị trục trặc.

## Danh sách Kịch bản

### Kịch bản 1: Tiêm trễ mạng (Delay Injection)
Giả lập tình trạng mạng chậm hoặc service `product-service` bị quá tải, phản hồi rất chậm.
- **Tập tin chạy:** `01-test-delay.sh`
- **Cách hoạt động:** Script sẽ ghi đè cấu hình `VirtualService` của `product-service`, thêm một độ trễ (delay) cố định là 5 giây cho 100% các request.

**Cách thực hiện chi tiết:**
1. Đảm bảo bạn đã export biến môi trường `KUBECONFIG` (chọn cụm 1 hoặc 2 đều được).
2. Mở Terminal, di chuyển vào thư mục bài test: `cd tests/istio-chaos`.
3. Chạy lệnh: `./01-test-delay.sh`.
4. Quan sát kết quả trên Terminal và ngay lập tức mở Trình duyệt, thử bấm vào tải danh sách sản phẩm.

**Kỳ vọng (Kết quả Tốt / Xấu):**
- **Trường hợp Tốt 🟢:** Terminal sẽ báo cáo thời gian phản hồi (Response Time) bị treo đúng 5 giây (Ví dụ: `5.02s`) trước khi trả về kết quả 200. Trên Trình duyệt, Frontend hiển thị vòng xoay (Loading Spinner) hoặc một hiệu ứng chờ đẹp mắt thay vì bị đứng hình, sau 5 giây dữ liệu vẫn hiện ra.
- **Trường hợp Xấu 🔴:** Trình duyệt bị vỡ giao diện, báo lỗi 504 Gateway Timeout bằng trang báo lỗi trắng trơn của trình duyệt, hoặc ứng dụng bị đơ không phản hồi. Điều này cảnh báo lập trình viên Frontend chưa cấu hình Time-out hoặc chưa xử lý UX cho trường hợp mạng lag.

---

### Kịch bản 2: Tiêm lỗi (Abort Injection)
Giả lập tình trạng `product-service` bị lỗi nghiêm trọng, luôn trả về HTTP 500.
- **Tập tin chạy:** `02-test-abort.sh`
- **Cách hoạt động:** Script ghi đè `VirtualService`, ép buộc 100% các request phải bị từ chối với mã lỗi HTTP 500.

**Cách thực hiện chi tiết:**
1. Tương tự, tại Terminal thư mục `tests/istio-chaos`, chạy lệnh: `./02-test-abort.sh`.
2. Quan sát kết quả CURL trên Terminal.
3. Mở Trình duyệt, thử tải lại trang hoặc bấm mua sản phẩm xem ứng dụng sẽ phản ứng ra sao khi Backend bỗng dưng bốc hơi.

**Kỳ vọng (Kết quả Tốt / Xấu):**
- **Trường hợp Tốt 🟢:** Terminal báo lỗi `HTTP 500 Internal Server Error`. Trên Trình duyệt, ứng dụng bắt được lỗi và hiển thị một thông báo thân thiện (Ví dụ: "Hệ thống đang quá tải, vui lòng quay lại sau") thay vì đổ sập. Nếu bạn có cấu hình Retry (Tự động thử lại) hoặc Circuit Breaker (Ngắt mạch) trên Istio, nó phải được kích hoạt và chặn đứng bão request.
- **Trường hợp Xấu 🔴:** Frontend vỡ nát, phun thẳng một đống mã code JSON raw thô thiển (chứa cả stack trace) cho người dùng thấy. Đây là lỗi bảo mật và trải nghiệm người dùng cực kỳ tồi tệ.

## Lưu ý an toàn
- Các script này chạy tự động và sẽ tự **khôi phục lại cấu hình gốc** (`infrastructure/k8s/istio/virtual-service-product.yaml`) sau khi test xong.
- Đừng dùng kịch bản này trên môi trường Production khi đang có khách hàng truy cập.
