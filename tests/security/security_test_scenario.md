# Kịch bản Kiểm thử Bảo mật và mTLS (Mutual TLS)

Thư mục này chứa các kịch bản kiểm thử nhằm đảm bảo tính năng bảo mật của Istio, đặc biệt là mã hóa đường truyền mTLS đã được bật thành công và bảo vệ các Microservices khỏi các truy cập trái phép hoặc không được mã hóa.

## Danh sách Kịch bản

### Kịch bản 1: Kiểm tra mTLS STRICT Mode
Xác minh xem các dịch vụ trong không gian mạng (namespace) `ecommerce` có bắt buộc phải kết nối bằng mTLS hay không. Cấu hình nằm tại `infrastructure/k8s/istio/peer-authentication.yaml`.

- **Tập tin chạy:** `01-test-mtls.sh`
- **Cách hoạt động:** Script sẽ tạo hai Pod curl giả lập. 
  - Pod thứ nhất được chạy trong namespace `ecommerce` (đã được tiêm Istio Sidecar, nằm trong Mesh). Pod này đóng vai trò là một dịch vụ hợp lệ trong mạng.
  - Pod thứ hai được chạy ở namespace `default` (không có Istio Sidecar, nằm ngoài Mesh). Pod này đóng vai trò là một kẻ tấn công hoặc một dịch vụ bên ngoài cố gắng gọi trực tiếp IP nội bộ (ClusterIP) bằng HTTP thuần.
- **Kỳ vọng:** 
  - Pod nằm trong Mesh sẽ nhận được phản hồi HTTP 200 vì Envoy Proxy của cả 2 bên tự động bắt tay và mã hóa dữ liệu.
  - Pod nằm ngoài Mesh sẽ bị ngắt kết nối (Connection reset by peer) vì `product-service` đã được cấu hình từ chối mọi kết nối HTTP không mã hóa.
