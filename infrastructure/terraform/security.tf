# Tường lửa cho HAProxy
resource "aws_security_group" "haproxy_sg" {
  name   = "haproxy-sg"
  vpc_id = aws_vpc.ecommerce_vpc.id

  # cổng 80 (http)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # cổng 443 (https)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # cổng 8404 (haproxy stats)
  ingress {
    from_port        = 8404
    to_port          = 8404
    protocol         = "tcp"
    cidr_blocks      = ["125.234.97.118/32", "171.250.165.236/32"]
    ipv6_cidr_blocks = ["2402:800:6311:93e6:f5b3:4b81:893f:9720/128"]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["125.234.97.118/32", "171.250.165.236/32"]
    ipv6_cidr_blocks = ["2402:800:6311:93e6:f5b3:4b81:893f:9720/128"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# tường lửa cho các node k3s
resource "aws_security_group" "cluster_sg" {
  name   = "cluster-sg"
  vpc_id = aws_vpc.ecommerce_vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["125.234.97.118/32", "171.250.165.236/32"]
    ipv6_cidr_blocks = ["2402:800:6311:93e6:f5b3:4b81:893f:9720/128"]
  }

  # mở cổng giao tiếp của kubernetes API server
  ingress {
    from_port        = 6443
    to_port          = 6443
    protocol         = "tcp"
    cidr_blocks      = ["125.234.97.118/32", "171.250.165.236/32"]
    ipv6_cidr_blocks = ["2402:800:6311:93e6:f5b3:4b81:893f:9720/128"]
  }

  # Dải Port 30000-32767: NodePort mặc định của Kubernetes -> chỉ mở port cho istio
  # port cho istio (HTTP)
  ingress {
    from_port       = 30081
    to_port         = 30081
    protocol        = "tcp"
    security_groups = [aws_security_group.haproxy_sg.id]
  }

  # port cho istio (HTTPS)
  ingress {
    from_port       = 30082
    to_port         = 30082
    protocol        = "tcp"
    security_groups = [aws_security_group.haproxy_sg.id]
  }

  # cho phép các máy ảo trong cùng group giao tiếp với nhau
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}