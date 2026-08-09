resource "aws_vpc" "ecommerce_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ecommerce-vpc"
  }
}

# chia subnet (public) 1 để cài đặt 3 instance (k8s cluster 1)
resource "aws_subnet" "cluster_subnet_1" {
  vpc_id                  = aws_vpc.ecommerce_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "cluster-subnet-1"
  }
}

# chia subnet (public) 2 để cài đặt cụm cluster k8s thứ 2
resource "aws_subnet" "cluster_subnet_2" {
  vpc_id                  = aws_vpc.ecommerce_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "cluster-subnet-2"
  }
}

# chia subnet (public) để cài đặt HAproxy 
resource "aws_subnet" "haproxy_subnet" {
  vpc_id                  = aws_vpc.ecommerce_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "haproxy-subnet"
  }
}

# create internet gateway
resource "aws_internet_gateway" "ecommerce_igw" {
  vpc_id = aws_vpc.ecommerce_vpc.id

  tags = {
    Name = "ecommerce-igw"
  }
}

# create route table for public subnet
resource "aws_route_table" "ecommerce-rt" {
  vpc_id = aws_vpc.ecommerce_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecommerce_igw.id
  }
}

# gắn route table cho subnet cụm cluster 1 ra public subnet
resource "aws_route_table_association" "cluster_subnet_1_rta" {
  subnet_id      = aws_subnet.cluster_subnet_1.id
  route_table_id = aws_route_table.ecommerce-rt.id
}

# gắn route table cho subnet cụm cluster 2 ra public subnet
resource "aws_route_table_association" "cluster_subnet_2_rta" {
  subnet_id      = aws_subnet.cluster_subnet_2.id
  route_table_id = aws_route_table.ecommerce-rt.id
}

# gắn route table cho subnet haproxy ra public subnet
resource "aws_route_table_association" "haproxy_rta" {
  subnet_id      = aws_subnet.haproxy_subnet.id
  route_table_id = aws_route_table.ecommerce-rt.id
}

