# Hướng Dẫn Chi Tiết: Thiết Lập Cụm K3s Trên AWS Từ Con Số 0 (A - Z)

Tài liệu này hướng dẫn chi tiết từng bước để dựng cụm K3s (1 Master Node + 2 Worker Nodes) trên nền tảng AWS EC2 sử dụng tài nguyên hạ tầng đã được cấu hình trong thư mục `terraform`.

---

## BẢN ĐỒ TRIỂN KHAI (ROADMAP)

1.  **Phần 1:** Khởi tạo hạ tầng AWS bằng Terraform.
2.  **Phần 2:** Đăng nhập SSH vào các Node.
3.  **Phần 3:** Cài đặt các gói tiền đề (Prerequisites) cho Longhorn Storage.
4.  **Phần 4:** Cài đặt K3s Control Plane (Master Node).
5.  **Phần 5:** Cài đặt K3s Agents (Worker Nodes).
6.  **Phần 6:** Cấu hình điều khiển cụm từ máy Local (Kubeconfig).
7.  **Phần 7:** Kiểm tra & Khắc phục sự cố (Troubleshooting).

---

## PHẦN 1: KHỞI TẠO HẠ TẦNG TRÊN AWS BẰNG TERRAFORM

Đứng ở máy cá nhân (Local Machine) của bạn:

1.  **Cài đặt AWS CLI và cấu hình tài khoản AWS:**
    Chạy lệnh sau và điền thông tin `AWS Access Key ID`, `AWS Secret Access Key`, và vùng `ap-southeast-1`:
    ```bash
    aws configure
    ```

2.  **Khởi tạo và chạy Terraform:**
    Di chuyển vào thư mục chứa code Terraform và khởi chạy:
    ```bash
    cd ecommerce-microservices/terraform
    terraform init
    terraform plan
    terraform apply -auto-approve
    ```

3.  **Thu thập thông tin địa chỉ IP của các node:**
    Sau khi chạy xong, Terraform sẽ in ra danh sách các máy ảo (hoặc bạn có thể xem trên trang quản trị AWS Console). Hãy ghi lại:
    *   **Master Node:** Public IP (`MASTER_PUBLIC_IP`) và Private IP (`MASTER_PRIVATE_IP`).
    *   **Worker Node 1:** Public IP (`WORKER_1_PUBLIC_IP`) và Private IP (`WORKER_1_PRIVATE_IP`).
    *   **Worker Node 2:** Public IP (`WORKER_2_PUBLIC_IP`) và Private IP (`WORKER_2_PRIVATE_IP`).

---

## PHẦN 2: ĐĂNG NHẬP SSH VÀO CÁC NODE

Terraform đã tự động tạo khóa SSH bí mật tên là `ecommerce-ssh-key` trong thư mục `terraform/`.

1.  **Phân quyền cho tệp khóa bí mật (Chỉ chạy trên Linux/macOS):**
    ```bash
    chmod 400 ecommerce-ssh-key
    ```

2.  **Đăng nhập thử vào Master Node bằng SSH:**
    ```bash
    ssh -i ecommerce-ssh-key ubuntu@<MASTER_PUBLIC_IP>
    ```

> [!TIP]
> Bạn có thể mở 3 tab Terminal riêng biệt để SSH vào cả 3 node nhằm tiện thao tác đồng thời ở các bước tiếp theo.

---

## PHẦN 3: CÀI ĐẶT CÁC GÓI TIỀN ĐỀ (PREREQUISITES)

Để cụm K3s có thể cài đặt được **Longhorn Storage Class** (phục vụ lưu trữ dữ liệu cho Kafka, Prometheus), ta cần chuẩn bị thư viện kết nối đĩa cứng ảo trên cả **3 node (Master + 2 Workers)**.

Chạy các lệnh sau trên cả 3 node:

1.  **Cập nhật hệ điều hành:**
    ```bash
    sudo apt-get update && sudo apt-get upgrade -y
    ```

2.  **Cài đặt open-iscsi và nfs-common:**
    ```bash
    sudo apt-get install -y open-iscsi nfs-common
    ```
    chú thích: 
    - open-iscsi để mount đĩa ảo (block storage-RWO) cho các pod. Gói open-iscsi chính là phần mềm client (initiator) trên hệ điều hành giúp máy ảo EC2 hiểu và kết nối được với các ổ đĩa iSCSI mà Longhorn tạo ra.
    - Để truyền tải dữ liệu đĩa cứng qua mạng giữa các node, Longhorn sử dụng giao thức iSCSI (truyền lệnh SCSI qua mạng TCP/IP).
3.  **Kích hoạt dịch vụ iscsid:**
    ```bash
    sudo systemctl enable --now iscsid
    ```

---

## PHẦN 4: CÀI ĐẶT K3S CONTROL PLANE (MASTER NODE)

Đăng nhập SSH vào **Master Node** (`MASTER_PUBLIC_IP`):

1.  **Chạy lệnh cài đặt K3s Server:**
    Thay thế `<MASTER_PUBLIC_IP>` và `<MASTER_PRIVATE_IP>` tương ứng của bạn vào lệnh dưới đây:
    ```bash
    curl -sfL https://get.k3s.io | sh -s - \
      --write-kubeconfig-mode 644 \
      --disable traefik \
      --tls-san <MASTER_PUBLIC_IP> \
      --node-ip <MASTER_PRIVATE_IP>
    ```
    *Ý nghĩa các tham số:*
    *   `--write-kubeconfig-mode 644`: Cấp quyền đọc file `/etc/rancher/k3s/k3s.yaml` cho user thông thường (để không cần dùng lệnh `sudo` khi chạy `kubectl`).
    *   `--disable traefik`: Vô hiệu hóa Ingress Traefik mặc định để chúng ta cài đặt Istio làm Gateway.
    *   `--tls-san`: Đăng ký IP Public của Master vào chứng chỉ bảo mật SSL, cho phép chúng ta quản trị cụm từ máy Local.
    *   `--node-ip`: Khai báo IP nội bộ của Master cho mạng cụm.

2.  **Lấy Token gia nhập cụm (Node Token):**
    Chạy lệnh sau trên Master và sao chép lại chuỗi ký tự trả về:
    ```bash
    sudo cat /var/lib/rancher/k3s/server/node-token
    ```
    *(Token sẽ có dạng chuỗi dài bắt đầu bằng `K10...`)*

---

## PHẦN 5: CÀI ĐẶT K3S AGENT (WORKER NODES)

Đăng nhập SSH vào từng máy **Worker Node** (`worker-1` và `worker-2`):

1.  **Chạy lệnh cài đặt K3s Agent:**
    Thay thế `<MASTER_PRIVATE_IP>`, `<NODE_TOKEN>`, và `<WORKER_PRIVATE_IP>` tương ứng của từng Worker rồi chạy lệnh:
    ```bash
    curl -sfL https://get.k3s.io | K3S_URL=https://<MASTER_PRIVATE_IP>:6443 K3S_TOKEN=<NODE_TOKEN> sh -s - \
      --node-ip <WORKER_PRIVATE_IP>
    ```
    *(Lưu ý: Luôn sử dụng Private IP của Master để đảm bảo các node liên lạc nội bộ với nhau qua mạng AWS nội bộ tốc độ cao và miễn phí cước băng thông)*.

2.  **Kiểm tra dịch vụ Agent:**
    ```bash
    sudo systemctl status k3s-agent
    ```

---

## PHẦN 6: CẤU HÌNH ĐIỀU KHIỂN CỤM TỪ MÁY LOCAL

Để có thể thao tác với cụm K3s (ví dụ: deploy microservices, check logs) trực tiếp từ máy cá nhân của bạn mà không cần SSH vào Master:

1.  **Đứng ở máy Local, tải file cấu hình Kubeconfig từ Master:**
    ```bash
    # Tạo thư mục .kube nếu chưa có
    mkdir -p ~/.kube
    
    # Download file cấu hình về máy local đặt tên là config-aws-k3s
    scp -i path/to/ecommerce-ssh-key ubuntu@<MASTER_PUBLIC_IP>:/etc/rancher/k3s/k3s.yaml ~/.kube/config-aws-k3s
    ```

2.  **Cập nhật địa chỉ API Server:**
    Mở file `~/.kube/config-aws-k3s` trên máy local bằng trình soạn thảo (VS Code, Nano, v.v.):
    *   Tìm dòng: `server: https://127.0.0.1:6443`
    *   Sửa thành: `server: https://<MASTER_PUBLIC_IP>:6443` (Sử dụng IP Public của Master).

3.  **Khai báo biến môi trường KUBECONFIG:**
    ```bash
    export KUBECONFIG=~/.kube/config-aws-k3s
    ```
    *(Để cấu hình này tự động nhận mỗi khi mở Terminal mới, hãy thêm dòng trên vào cuối tệp `~/.bashrc` hoặc `~/.zshrc`)*.

4.  **Kiểm tra kết nối tới cụm K3s:**
    ```bash
    kubectl get nodes
    ```
    **Kết quả mong muốn:**
    ```text
    NAME                    STATUS   ROLES                  AGE    VERSION
    ecommerce-master-node   Ready    control-plane,master   10m    v1.2X.X+k3s1
    ecommerce-worker-1      Ready    <none>                 5m     v1.2X.X+k3s1
    ecommerce-worker-2      Ready    <none>                 5m     v1.2X.X+k3s1
    ```

---

## PHẦN 7: KIỂM TRA & KHẮC PHỤC SỰ CỐ (TROUBLESHOOTING)

### 1. Lỗi không kết nối được `kubectl` từ máy Local
*   **Nguyên nhân:** Cổng `6443` (Kubernetes API Server) trên Master Node bị chặn.
*   **Khắc phục:** 
    1. Kiểm tra Security Group (`ecommerce-sg`) trên AWS xem đã cấu hình cho phép cổng `6443` trỏ tới IP Public hiện tại của máy local bạn chưa.
    2. Kiểm tra xem bạn đã cấu hình đúng tham số `--tls-san <MASTER_PUBLIC_IP>` ở phần 4 chưa (nếu thiếu, chứng chỉ TLS sẽ từ chối kết nối từ ngoài vào).

### 2. Các Worker Node không gia nhập được cụm (Trạng thái Not Ready hoặc không xuất hiện)
*   **Nguyên nhân:** Lỗi kết nối giữa các Node qua mạng nội bộ AWS.
*   **Khắc phục:** 
    1. Kiểm tra xem Security Group của AWS có luật cho phép mọi traffic nội bộ giữa các máy ảo nằm chung trong Group không (`self = true` hoặc cho phép các cổng UDP 8472, TCP 10250).
    2. Đảm bảo lúc cài Worker, bạn đã nhập đúng Private IP của Master và Token chính xác.

### 3. Cách xem log trực tiếp để debug trên các Node
*   **Xem log K3s Server (Master):**
    ```bash
    sudo journalctl -u k3s -f
    ```
*   **Xem log K3s Agent (Worker):**
    ```bash
    sudo journalctl -u k3s-agent -f
    ```
