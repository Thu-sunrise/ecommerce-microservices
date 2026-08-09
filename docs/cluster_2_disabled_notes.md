# Ghi chú: Vô hiệu hóa Cụm K8s số 2 (Cluster 2)

**Ngày thực hiện:** Hôm nay
**Lý do:** Giới hạn tài nguyên vCPU trên AWS chưa được duyệt, tạm thời chỉ chạy 1 cụm để tiết kiệm chi phí và tài nguyên luyện tập.

Theo yêu cầu, **không có bất kỳ dòng code nào bị xóa**, toàn bộ chỉ được bọc trong comment.

---

## 1. File: `infrastructure/terraform/compute.tf`
Đã sử dụng block comment `/* ... */` và `#` để vô hiệu hóa:

- **Dòng 52-69**: Vô hiệu hóa Resource tạo Master Node cho cụm 2 (`aws_instance.cluster_2_master_node`).
- **Dòng 72-90**: Vô hiệu hóa Resource tạo Worker Node cho cụm 2 (`aws_instance.cluster_2_worker_node`).
- **Dòng 114-121**: Vô hiệu hóa các biến truyền IP của cụm 2 vào file cấu hình HAProxy. Đã thay thế các biến này bằng chuỗi rỗng (`""`) để hàm `templatefile` không bị lỗi.

*Cách khôi phục:*
Xóa các dấu `/*` và `*/` ở các block tạo máy ảo. Xóa các dòng gán chuỗi rỗng và mở comment (`#`) cho các biến truyền IP.

---

## 2. File: `infrastructure/terraform/haproxy.cfg.tftpl`
Đã sử dụng ký tự `#` để vô hiệu hóa HAProxy trỏ traffic về cụm 2:

- **Dòng 66-69**: Trong `backend k8s_http_backend`, vô hiệu hóa các server của cụm 2.
- **Dòng 81-84**: Trong `backend k8s_https_backend`, vô hiệu hóa các server của cụm 2.

*Cách khôi phục:*
Chỉ cần xóa dấu `#` ở đầu các dòng `server c2-...`

---

## 3. File: `scripts/deploy-k3s-cluster.sh`
Đã sử dụng ký tự `#` để vô hiệu hóa việc triển khai K8s lên Cụm 2:

- **Dòng 15**: Vô hiệu hóa việc lấy `MASTER_IP_2` từ Terraform output.
- **Dòng 24-27**: Vô hiệu hóa lệnh kiểm tra biến `$MASTER_IP_2`.
- **Dòng 35**: Vô hiệu hóa dòng in ra địa chỉ IP của cụm 2.
- **Dòng 139-140**: Vô hiệu hóa lệnh gọi hàm `deploy_to_cluster` cho cụm 2.

*Cách khôi phục:*
Xóa dấu `#` ở đầu các dòng tương ứng để script tiếp tục triển khai lên Cụm 2.

---

> **Lưu ý:** Subnet của cụm 2 (`cluster_subnet_2`) trong `network.tf` vẫn được giữ nguyên vì nó không tốn vCPU và giúp giữ nguyên cấu trúc mạng. Mọi thứ đã sẵn sàng, bạn chỉ cần gõ `terraform apply` để áp dụng thay đổi.
