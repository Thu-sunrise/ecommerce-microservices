resource "random_password" "k3s_token" {
  length  = 32
  special = false
}

#==========================k8s cluster 1=============================

# create master node
resource "aws_instance" "cluster_1_master_node" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"

  subnet_id              = aws_subnet.cluster_subnet_1.id
  vpc_security_group_ids = [aws_security_group.cluster_sg.id]
  key_name               = aws_key_pair.ecommerce_keypair.key_name

  user_data = <<-EOF
        #!/bin/bash
        PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
        curl -sfL https://get.k3s.io | K3S_TOKEN=${random_password.k3s_token.result} sh -s - server --disable traefik --tls-san $PUBLIC_IP
    EOF

  tags = {
    Name = "cluster-1-master-node"
  }
}

# create worker node
resource "aws_instance" "cluster_1_worker_node" {
  count         = 2
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.large"

  subnet_id              = aws_subnet.cluster_subnet_1.id
  vpc_security_group_ids = [aws_security_group.cluster_sg.id]
  key_name               = aws_key_pair.ecommerce_keypair.key_name

  user_data = <<-EOF
        #!/bin/bash
        sleep 30
        curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.cluster_1_master_node.private_ip}:6443 K3S_TOKEN=${random_password.k3s_token.result} sh -
    EOF

  tags = {
    Name = "cluster-1-worker-${count.index + 1}"
  }
}

#==========================k8s cluster 2=============================

# create master node
resource "aws_instance" "cluster_2_master_node" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t3.medium"

    subnet_id = aws_subnet.cluster_subnet_2.id
    vpc_security_group_ids = [aws_security_group.cluster_sg.id]
    key_name = aws_key_pair.ecommerce_keypair.key_name

    user_data = <<-EOF
        #!/bin/bash
        PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
        curl -sfL https://get.k3s.io | K3S_TOKEN=${random_password.k3s_token.result} sh -s - server --disable traefik --tls-san $PUBLIC_IP
    EOF

    tags = {
        Name = "cluster-2-master-node"
    }
}


# create worker node
resource "aws_instance" "cluster_2_worker_node" {
    count = 2
    ami = data.aws_ami.ubuntu.id
    instance_type = "t3.large"

    subnet_id = aws_subnet.cluster_subnet_2.id
    vpc_security_group_ids = [aws_security_group.cluster_sg.id]
    key_name = aws_key_pair.ecommerce_keypair.key_name

    user_data = <<-EOF
        #!/bin/bash
        sleep 30
        curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.cluster_2_master_node.private_ip}:6443 K3S_TOKEN=${random_password.k3s_token.result} sh -
    EOF

    tags = {
        Name = "cluster-2-worker-${count.index + 1}"
    }
}


#==============================HAproxy===============================

# create reverse proxy 
resource "aws_instance" "haproxy" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  subnet_id              = aws_subnet.haproxy_subnet.id
  vpc_security_group_ids = [aws_security_group.haproxy_sg.id]
  key_name               = aws_key_pair.ecommerce_keypair.key_name

  user_data = <<-EOF
        #!/bin/bash
        # 1. Cài đặt Nginx
        sudo apt-get update -y
        sudo apt-get install haproxy -y 

        # 2. Sử dụng lệnh cat kết hợp templatefile để tạo file cấu hình mới
        cat << 'CONFIG_END' > /etc/haproxy/haproxy.cfg
        ${templatefile("${path.module}/haproxy.cfg.tftpl", {
        c1_master_ip = aws_instance.cluster_1_master_node.private_ip
        c2_master_ip = aws_instance.cluster_2_master_node.private_ip

        c1_worker1_ip = aws_instance.cluster_1_worker_node[0].private_ip
        c1_worker2_ip = aws_instance.cluster_1_worker_node[1].private_ip

        c2_worker1_ip = aws_instance.cluster_2_worker_node[0].private_ip
        c2_worker2_ip = aws_instance.cluster_2_worker_node[1].private_ip
})}
        CONFIG_END

        # 3. Khởi động lại dịch vụ HAProxy
        sudo systemctl restart haproxy
        sudo systemctl enable haproxy
    EOF

tags = {
  Name = "haproxy"
}

}