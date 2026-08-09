# Hướng dẫn xử lý khi địa chỉ IP Public của EC2 bị thay đổi

Khi bạn tắt (Stop) và bật lại (Start) máy ảo trên AWS EC2, nếu bạn không thuê **Elastic IP (IP Tĩnh)**, thì địa chỉ Public IP của máy ảo sẽ bị thay đổi ngẫu nhiên. Dưới đây là danh sách những nơi bạn **bắt buộc phải cập nhật lại IP mới** để hệ thống tiếp tục hoạt động.

> [!TIP]
> **Giải pháp triệt để:** Để không bao giờ phải làm những bước thủ công bên dưới nữa, lời khuyên là bạn nên vào giao diện AWS Console -> **Elastic IPs** -> Cấp phát 1 IP tĩnh và gắn (Associate) nó vào con máy ảo NGINX Proxy và K3s Master của bạn. Khi đó IP sẽ không bao giờ bị đổi nữa (Lưu ý: AWS có tính phí rất nhỏ cho Elastic IP).

---

## 1. Cập nhật lại Bản ghi DNS (Cloudflare)
Vì địa chỉ IP của NGINX Proxy (cửa ngõ đi vào hệ thống) đã thay đổi, khách hàng từ Internet sẽ không thể tìm thấy máy chủ của bạn nữa (Lỗi 522 hoặc Connection Timed Out).

**Cách xử lý:**
1. Đăng nhập vào trang quản trị tên miền (Ví dụ: **Cloudflare**).
2. Tìm đến phần quản lý DNS (DNS Records).
3. Tìm các bản ghi chữ **A** mà bạn đã tạo trước đó (Ví dụ: `*.nginx`, `*.istio`, `api.nginx`...).
4. Nhấn chỉnh sửa và **thay thế dải IP cũ** bằng **Public IP mới** của con máy ảo **NGINX Proxy**.
5. Lưu lại và đợi khoảng 1-2 phút để DNS cập nhật.

---

## 2. Cập nhật lại tệp kết nối K8s (`kubeconfig`) trên máy tính cá nhân
Nếu bạn dùng Terminal ở máy tính cá nhân (hoặc Jenkins) để gõ lệnh `kubectl` điều khiển cụm K3s từ xa, nó sẽ báo lỗi `Unable to connect to the server` vì nó đang kết nối vào IP Master cũ.

**Cách xử lý:**
1. Mở tệp kubeconfig trên máy tính cá nhân của bạn (thường nằm ở `~/.kube/config`).
2. Tìm đến phần `clusters -> cluster -> server`.
3. Sửa lại URL thành Public IP mới của máy K3s Master:
   ```yaml
   server: https://<PUBLIC_IP_MỚI_CỦA_MASTER>:6443
   ```
4. Lưu tệp và gõ lệnh `kubectl get nodes` để kiểm tra kết nối.

### 🔴 Xử lý các lỗi thường gặp khi gõ lệnh kubectl:

**Lỗi 1: `i/o timeout` (Chính là lỗi bạn đang gặp)**
*   **Nguyên nhân:** Lỗi này 100% là do Tường lửa (AWS Security Group) đang chặn gói tin của bạn. Khi mạng ở nhà bạn bị khởi động lại hoặc qua ngày mới, nhà mạng thường đổi địa chỉ IP máy tính cá nhân của bạn. Trong khi đó, file `terraform/security.tf` đang khóa cứng việc mở cổng 6443 và 22 cho mỗi cái IP cũ (`125.234.97.118`).
*   **Cách khắc phục:** Truy cập [whatismyip.com](https://www.whatismyip.com/) để lấy địa chỉ IP mạng nhà bạn hiện tại. Vào file `terraform/security.tf`, sửa tất cả những chỗ có `125.234.97.118/32` thành IP mới của bạn. Sau đó chạy lệnh `terraform apply` để AWS mở cửa tường lửa cho bạn vào.

**Lỗi 2: `x509: certificate is valid for <IP_CŨ>, not <IP_MỚI>`**

*   **Nguyên nhân:** Khi K3s khởi động, nó tạo ra một Chứng chỉ TLS và "đóng dấu" cứng danh sách các địa chỉ IP được phép kết nối vào bên trong (gọi là SAN - Subject Alternative Names). IP Public mới của EC2 không nằm trong danh sách đó nên K8s từ chối kết nối để bảo vệ bảo mật.

*   **Cách khắc phục (Giữ nguyên bảo mật TLS - Khuyên dùng):** Phải tái tạo lại chứng chỉ K3s bao gồm IP mới. Thực hiện tuần tự các bước sau:

**Bước 1: SSH vào máy K3s Master**
```bash
ssh -i <tên_file_key.pem> ubuntu@<PUBLIC_IP_MỚI>
```

**Bước 2: Xóa chứng chỉ TLS cũ để K3s tạo lại**
```bash
sudo rm -f /var/lib/rancher/k3s/server/tls/server-ca.crt
sudo rm -f /var/lib/rancher/k3s/server/tls/server-ca.key
sudo rm -f /var/lib/rancher/k3s/server/tls/dynamic-cert.json
```

**Bước 3: Thêm IP Public mới vào tham số khởi động của K3s**
```bash
sudo nano /etc/systemd/system/k3s.service
```
Tìm dòng `ExecStart=` và thêm tham số `--tls-san <PUBLIC_IP_MỚI>` vào (thay IP thật vào):
```
ExecStart=/usr/local/bin/k3s server \
    --tls-san 13.229.183.240 \
    ... (giữ nguyên các tham số cũ khác)
```

**Bước 4: Khởi động lại K3s để tạo chứng chỉ mới**
```bash
sudo systemctl daemon-reload
sudo systemctl restart k3s
# Đợi khoảng 30 giây cho K3s khởi động hoàn toàn
```

**Bước 5: Tải file kubeconfig mới về máy cá nhân**
*(Gõ lệnh này trên máy tính cá nhân của bạn, không phải trên EC2)*
```bash
scp -i <tên_file_key.pem> ubuntu@<PUBLIC_IP_MỚI>:/etc/rancher/k3s/k3s.yaml ~/.kube/config-ecommerce-aws-k3s
```

**Bước 6: Sửa địa chỉ server trong file kubeconfig vừa tải về**
K3s luôn ghi mặc định là `127.0.0.1`, bạn cần đổi thành IP Public thật:
```bash
# Trên Linux/macOS
sed -i 's/127.0.0.1/<PUBLIC_IP_MỚI>/g' ~/.kube/config-ecommerce-aws-k3s

# Trên Windows (PowerShell)
(Get-Content ~/.kube/config-ecommerce-aws-k3s) -replace '127.0.0.1','<PUBLIC_IP_MỚI>' | Set-Content ~/.kube/config-ecommerce-aws-k3s
```

**Bước 7: Kiểm tra kết nối**
```bash
kubectl get nodes --kubeconfig ~/.kube/config-ecommerce-aws-k3s
```
Kết quả kỳ vọng: Danh sách các Node K3s hiện ra với trạng thái `Ready`.

> [!NOTE]
> Lần tiếp theo khi IP thay đổi, bạn chỉ cần lặp lại **Bước 3 đến Bước 7** (thay IP mới vào). Không cần xóa chứng chỉ lần nữa vì Bước 3 sẽ khiến K3s tự động tạo lại.

---

## 3. Cập nhật kết nối SSH
Tất nhiên, khi dùng phần mềm SSH (MobaXterm, PuTTY, hoặc Terminal) để remote vào server, bạn cũng phải sửa thông tin Host thành IP Public mới của các máy ảo.

---

## 4. (Tham khảo) Terraform
Nếu bạn dùng Terraform để quản lý hạ tầng, việc tự ý Stop/Start máy ảo ngoài giao diện AWS có thể gây lệch trạng thái (State drift).
Nếu bạn chạy lại lệnh `terraform apply`, Terraform có thể phát hiện IP bị đổi và sẽ cố gắng cập nhật lại thông tin (hoặc xóa máy đi tạo lại nếu cấu hình không chuẩn). Lời khuyên là nếu đã dùng Terraform, nên cấu hình gán **Elastic IP** (EIP) bằng code Terraform luôn ngay từ đầu.

> [!NOTE]
> Địa chỉ **Private IP** của các máy ảo trong cùng mạng VPC AWS thường sẽ **giữ nguyên** dù bạn có Stop/Start (trừ khi bạn Terminate/xóa hẳn máy). Do đó, cấu hình Firewall nội bộ (Security Groups) hoặc cấu hình mạng Flannel giữa các K3s Node sẽ **KHÔNG** bị ảnh hưởng và bạn không cần phải sửa cấu hình bên trong K8s.
