# Hướng dẫn Kiểm thử HPA (Horizontal Pod Autoscaler)

Thư mục này chứa các kịch bản kiểm thử hiệu năng và tự động mở rộng (Load Test & Autoscaling Test) sử dụng công cụ **k6**.

Mục tiêu là bắn một lượng lớn Request (tải giả lập) vào các Microservice để ép CPU của các Pod tăng cao, từ đó kích hoạt cơ chế HPA tự động đẻ thêm Pod mới nhằm gánh tải.

---

## Cơ chế hoạt động của Script

Khi bạn chạy file script `run-hpa-test.sh`, hệ thống sẽ tự động thực hiện 4 bước sau:
1. **Port-forward:** Tự động mở đường ống `kubectl port-forward` để đưa cổng nội bộ của Kubernetes (ví dụ `8086` của product-service) ra máy tính Local của bạn.
2. **Background Monitor:** Chạy ngầm một trình theo dõi (cứ 15 giây 1 lần). Trình này sẽ liên tục gọi API của Kubernetes để in ra màn hình:
   - Phần trăm CPU Utilization hiện tại.
   - Số lượng Pod đang chạy (Current Replicas) so với mức Max Replicas.
   - Trạng thái của từng Pod (Running, Pending).
3. **Bắn tải k6:** Gọi công cụ `k6 run` để thực thi các file code Javascript (`product-load.js` hoặc `payment-load.js`), tạo ra hàng ngàn request bắn liên tục vào cổng localhost vừa mở.
4. **Cleanup:** Sau khi k6 hoàn thành quá trình bắn tải, script sẽ tự động tắt Port-forward và trình Monitor, đồng thời lưu kết quả k6 ra file JSON.

---

## Cách chạy bài Test

### Yêu cầu (Prerequisites)
Bạn cần phải cài đặt sẵn công cụ **k6** trên máy tính đang chạy script này. 
- Nếu dùng Ubuntu: `sudo apt install k6`
- Nếu dùng MacOS: `brew install k6`

### 1. Kịch bản test HPA cho Product Service
Chạy lệnh sau tại thư mục chứa script:
```bash
./k6/run-hpa-test.sh product
```
**Kết quả kỳ vọng:** Bạn sẽ thấy mức sử dụng CPU của `product-service-hpa` tăng dần (vd: từ 5% lên 150%). Khi CPU vượt qua ngưỡng Target (thường là 50% hoặc 80% do bạn cài đặt), số lượng Pod sẽ nhảy từ 1 lên 2, 3, v.v.

### 2. Kịch bản test HPA cho Payment Service
Chạy lệnh sau:
```bash
./k6/run-hpa-test.sh payment
```
**Kết quả kỳ vọng:** Tương tự, HPA của `payment-service` sẽ bắt được tín hiệu CPU tăng vọt và tự động Scale Out thêm Pod mới.

---

## Phân tích kết quả
Sau khi kịch bản chạy xong, file kết quả chi tiết của k6 sẽ được lưu lại dưới dạng `hpa-test-result-product.json` hoặc `hpa-test-result-payment.json`. Bạn có thể đọc file này để xem các chỉ số:
- **http_req_duration:** Thời gian phản hồi trung bình (khi bị quá tải, thời gian này thường sẽ tăng lên cho đến khi Pod mới được tạo xong).
- **http_req_failed:** Tỷ lệ Request bị lỗi (lý tưởng là 0%).
