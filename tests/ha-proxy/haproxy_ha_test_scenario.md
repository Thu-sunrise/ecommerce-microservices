# Kịch bản Chi tiết Kiểm thử HAProxy High Availability (Multi-Cluster K8s)

Tài liệu này cung cấp kịch bản kiểm thử chi tiết dựa trên mã nguồn kiến trúc hạ tầng AWS, Terraform, HAProxy và cấu hình Istio Ingress Gateway của dự án `ecommerce-microservices`.

---

## 1. Tổng quan Kiến trúc hiện tại

Theo cấu trúc mã nguồn, request luân chuyển theo đường đi (Traffic Flow) như sau:
1. **User** -> truy cập vào `HAProxy Public IP` (Port 80/443).
2. **HAProxy** -> cân bằng tải (Round-Robin) đẩy vào 1 trong 6 K8s Nodes của **2 Cụm K8s** (Port 30081/30082).
3. **K8s Node (NodePort)** -> chuyển tiếp traffic vào **Istio Ingress Gateway**.
4. **Istio VirtualService** -> dựa vào header Host (VD: `frontend.hubsunrise.me`) để định tuyến vào service `frontend` hoặc `product-service`.

### Thông số cấu hình HAProxy cốt lõi:
- **Thuật toán:** `balance roundrobin` (chia đều 1-1).
- **Khám sức khỏe (Health Check):** `check inter 2000 rise 2 fall 3`
  - Ping K8s nodes mỗi 2s.
  - Sau 3 lần thất bại liên tiếp (6 giây) -> Đánh dấu Node DOWN (cắt luồng).
  - Sau 2 lần thành công liên tiếp (4 giây) -> Đánh dấu Node UP (mở luồng).
- **Trang giám sát (Stats):** Cổng `8404`, đường dẫn `/stats`.

---

## 2. Công tác Chuẩn bị (Pre-requisites)

### Lấy thông tin IP
Mở terminal ở thư mục `infrastructure/terraform` và chạy lệnh lấy IP của HAProxy:
```bash
cd infrastructure/terraform
terraform output haproxy_public_ip
```
*(Giả sử kết quả là `X.X.X.X`)*

### Mở trang giám sát HAProxy (Stats Dashboard)
- Truy cập trình duyệt: `http://X.X.X.X:8404/stats`
- Bạn sẽ thấy 2 khối chính là `k8s_http_backend` và `k8s_https_backend`, mỗi khối gồm 6 server (c1-master, c1-worker1... và c2-master...). Tất cả phải đang màu **Xanh (UP)**.

### Chuẩn bị chạy Script tạo Traffic liên tục
Thay vì phải copy code thủ công, dự án đã cung cấp sẵn script tự động hóa hoàn toàn việc bắn traffic.
Mở một Terminal, di chuyển vào thư mục chứa script và chạy để mô phỏng người dùng liên tục truy cập Frontend.

```bash
cd tests/ha-proxy
./01-simulate-traffic.sh
```

**Cách đọc kết quả:**
- Script tự động kết nối vào Terraform để lấy IP của HAProxy.
- Cứ mỗi 0.5s nó sẽ bắn 1 request (có đính kèm Header `Host: frontend.hubsunrise.me` để qua cổng Istio).
- Cứ để Terminal này chạy liên tục trong suốt quá trình test. Nếu HAProxy phân tải tốt, bạn sẽ thấy kết quả trả về toàn là `[HH:MM:SS] Request SUCCESS - Status: 200`.

---

## 3. Kịch bản Kiểm thử

### Kịch bản 1: Cân bằng tải xoay vòng giữa các Cụm (Load Balancing)
**Mục đích:** Đảm bảo HAProxy đang chia đều số lượng request vào cả 2 Cụm K8s khi hệ thống bình thường.
**Cách thực hiện chi tiết:**
1. **Terminal 1:** Mở script `01-simulate-traffic.sh` và để chạy liên tục (Mô phỏng User).
2. **Trình duyệt:** Truy cập trang `http://<HAPROXY_IP>:8404/stats`.
3. **Terminal 2:** Chạy script `02-check-istio-logs.sh` (Đếm log nội bộ Istio).
**Kỳ vọng (Kết quả Tốt):**
- **Terminal 1:** Chỉ hiển thị toàn `Request SUCCESS - Status: 200`.
- **Terminal 2:** Trả về kết quả chia đều (Ví dụ: `Cluster 1: 45 requests, Cluster 2: 47 requests`).
- **Trình duyệt:** Cột **Sessions (Total)** của tất cả 6 servers (`c1-*` và `c2-*`) tăng đều nhau.

---

### Kịch bản 2: Chịu lỗi khi rớt 1 Worker Node (Single Node Failure)
**Mục đích:** Kiểm tra khả năng tự động ngắt kết nối khi 1 node vật lý chết, không làm sập toàn bộ hệ thống.
**Cách thực hiện chi tiết:**
1. Đăng nhập vào AWS Console, mở dịch vụ **EC2**.
2. Đảm bảo **Terminal 1** (`01-simulate-traffic.sh`) đang chạy liên tục.
3. Trên giao diện EC2, tìm máy ảo `c1-worker-1` (thuộc Cụm 1) -> Chọn **Instance state** -> Bấm **Stop instance**.
4. Lập tức quay lại nhìn Terminal 1 và Trình duyệt (HAProxy Stats).
**Kỳ vọng (Kết quả Tốt):**
- **Terminal 1:** Trong 6 giây đầu tiên, bạn có thể thấy xuất hiện một vài dòng `Request FAILED - Status: 502/503/000`. Nhưng từ giây thứ 7 trở đi, nó tự động phục hồi quay lại `Request SUCCESS - Status: 200` hoàn toàn.
- **Trình duyệt:** Sau tối đa 6 giây, dòng `c1-worker-1-ip` tự động nhận diện lỗi và chuyển sang **Màu Đỏ (DOWN)**, chia tải đều cho 5 node còn lại.

---

### Kịch bản 3: Chịu lỗi khi sập toàn bộ Cụm 1 (Multi-Cluster Disaster Recovery)
**Mục đích:** Kịch bản nghiêm trọng nhất (Thảm họa). Cụm K8s 1 bị đứt mạng hoặc Data Center chứa Cụm 1 bị mất điện hoàn toàn.
**Cách thực hiện chi tiết:**
1. Ở AWS EC2 Console, tick chọn TẤT CẢ các instances của Cụm 1 (`c1-master`, `c1-worker-1`, `c1-worker-2`).
2. Chọn **Instance state** -> Bấm **Stop instance** để "rút phích cắm" toàn bộ cụm.
3. Quan sát **Terminal 1**, **Trình duyệt**, và đặc biệt là chạy lại **Terminal 2** (`02-check-istio-logs.sh`).
**Kỳ vọng (Kết quả Tốt - Đạt chuẩn DR):**
- **Trình duyệt:** Toàn bộ nhóm `c1-*` trên HAProxy Stats đồng loạt chuyển sang **Màu Đỏ (DOWN)**.
- **Terminal 1:** Giao dịch bị gián đoạn ngắn gọn khoảng 6 giây. Sau đó tự động phục hồi về mã `200 SUCCESS`.
- **Terminal 2:** Khi chạy lệnh đếm log, bạn sẽ thấy kết quả `Cluster 1: 0 requests, Cluster 2: 92 requests`. Điều này chứng tỏ 100% traffic đã tự động dồn về Cụm 2 để gánh tải.

---

### Kịch bản 4: Tự động phục hồi khi có Node/Cụm sống lại (Auto Failback)
**Mục đích:** Kiểm tra cơ chế tự động kết nối lại khi hệ thống được khắc phục mà không cần kỹ sư can thiệp thủ công.
**Cách thực hiện chi tiết:**
1. Ở AWS EC2 Console, chọn lại toàn bộ các máy của Cụm 1 và bấm **Start instance**.
2. Chờ khoảng 1-2 phút để hệ điều hành, Kubernetes và các Pod của Istio khởi động xong.
3. Liên tục theo dõi **Trình duyệt** và chạy lại **Terminal 2**.
**Kỳ vọng (Kết quả Tốt):**
- **Trình duyệt:** Ngay khi Istio Ingress ở Cụm 1 hoạt động lại, HAProxy thực hiện ping thành công 2 lần (mất đúng 4 giây). Các server `c1-*` tự động chuyển từ Đỏ sang **Xanh lục (UP)**.
- **Terminal 1:** Không có bất kỳ timeout hay request FAILED nào xảy ra trong quá trình failback (mượt mà 100%).
- **Terminal 2:** Số lượng đếm request bắt đầu chia đều lại cho cả 2 cụm như Kịch bản 1.

---

## 4. Hướng dẫn Quan sát và Đánh giá kết quả (Tốt / Xấu)

Để đánh giá chính xác hệ thống có hoạt động HA (High Availability) hoàn hảo hay không, bạn cần phối hợp quan sát trên **3 công cụ chính**:
1. **Terminal 1 (`01-simulate-traffic.sh`)**: Góc nhìn của Khách hàng (End-User).
2. **Terminal 2 (`02-check-istio-logs.sh`)**: Góc nhìn của Hệ thống nội bộ (K8s/Istio).
3. **Trình duyệt (HAProxy Stats `:8404/stats`)**: Góc nhìn của Bộ định tuyến (Load Balancer).

### 🟢 TRƯỜNG HỢP TỐT (HỆ THỐNG ĐẠT CHUẨN)
- **Trên Terminal 1 (Góc User):** Khi bạn đánh sập 1 Cụm/Node, có thể sẽ xuất hiện vài dòng `FAILED 502/503`, nhưng hệ thống **phải tự động phục hồi** (quay về `SUCCESS 200`) trong vòng tối đa **6 giây**.
- **Trên Terminal 2 (Góc K8s):**
  - Trạng thái bình thường: Request được chia tương đối đều. (Ví dụ: `Cụm 1: 45 req`, `Cụm 2: 47 req`).
  - Trạng thái sập Cụm 1: 100% Request tự động tràn sang Cụm 2 gánh vác. (Ví dụ: `Cụm 1: 0 req`, `Cụm 2: 92 req`).
- **Trên Trình duyệt (Góc HAProxy):** Các Node đang chạy có màu **Xanh lục (UP)**. Khi bạn Stop máy ảo, đúng 6 giây sau Node đó tự động chuyển **Màu Đỏ (DOWN)** (HAProxy nhận diện được lỗi và ngắt luồng). Khi bật máy lên lại, Node tự động Xanh lục lại.

### 🔴 TRƯỜNG HỢP XẤU (HỆ THỐNG BỊ LỖI)
- **Trên Terminal 1 (Góc User):** Khi có sự cố, lệnh báo `FAILED - Status: 502/503/000` liên tục kéo dài hàng chục giây hoặc vĩnh viễn mà không tự phục hồi. (Hệ thống không có khả năng HA).
- **Trên Terminal 2 (Góc K8s):** Dù cả 2 Cụm đều khỏe mạnh nhưng kết quả chỉ báo `Cụm 1: 90 req, Cụm 2: 0 req` (Lỗi HAProxy không thèm chia tải cho Cụm 2).
- **Trên Trình duyệt (Góc HAProxy):** 
  - Máy ảo vẫn sống, Istio Ingress vẫn chạy nhưng HAProxy Stats báo **Màu Đỏ** toàn bộ. (Thường do lỗi cấu hình Security Group tường lửa không cho HAProxy ping vào Port `30081`).
  - Máy ảo đã bị tắt/chết nhưng HAProxy Stats vẫn hiện **Màu Xanh** (Lỗi do cấu hình Health Check `check inter 2000` bị sai, dẫn đến HAProxy tiếp tục đổ user vào máy chết).

---

## 5. Hướng dẫn sử dụng công cụ Kiểm tra chéo ở tầng K8s

Để chắc chắn 100% request thực sự rơi vào cả 2 cụm, thay vì chỉ tin tưởng màn hình HAProxy (nhiều khi hiển thị ảo), dự án đã cung cấp sẵn script đếm log tự động.

**Cách thực hiện:**
Mở 1 Terminal mới và chạy script kiểm tra log Istio:
```bash
cd tests/ha-proxy
./02-check-istio-logs.sh
```

**Cách đọc kết quả và nghiệm thu (Nghiệm thu High Availability):**
- **Trong Kịch bản 1 (Mọi thứ bình thường):** Kết quả in ra trên màn hình sẽ cho thấy số lượng request được chia khá đều. Ví dụ: `Cluster 1: 45 requests, Cluster 2: 47 requests`. Điều này chứng tỏ HAProxy đang làm rất tốt nhiệm vụ Round-Robin Load Balancing.
- **Trong Kịch bản 3 (Cụm 1 bị sập hoàn toàn):** Bạn sẽ thấy `Cluster 1: 0 requests`, trong khi `Cluster 2: 92 requests` (Gánh 100% tải). Dù một cụm K8s bốc hơi hoàn toàn, phía `01-simulate-traffic.sh` vẫn in ra mã trạng thái HTTP là `200 SUCCESS`. Đây là minh chứng vàng cho việc hệ thống đã đạt chuẩn Disaster Recovery (Chống chịu thảm họa)!
