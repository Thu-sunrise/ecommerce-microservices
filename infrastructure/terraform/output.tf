#===========================================
# KẾT QUẢ TRẢ VỀ (OUTPUTS) SAU KHI TRIỂN KHAI
#===========================================

# HAProxy (Đầu vào của hệ thống)
output "haproxy_public_ip" {
  description = "Truy cap Web qua IP nay"
  value       = aws_instance.haproxy.public_ip
}

output "haproxy_private_ip" {
  description = "Private IP cua HAProxy"
  value       = aws_instance.haproxy.private_ip
}

# Cum K8s so 1 (Cluster 1)
output "cluster_1_master_public_ip" {
  description = "IP de SSH vao Master Node 1"
  value       = aws_instance.cluster_1_master_node.public_ip
}

output "cluster_1_master_private_ip" {
  description = "Private IP cua Master Node 1"
  value       = aws_instance.cluster_1_master_node.private_ip
}

output "cluster_1_workers_private_ips" {
  description = "Private IPs cua cac Worker Node 1"
  value       = aws_instance.cluster_1_worker_node[*].private_ip
}

# Cum K8s so 2 (Cluster 2)
output "cluster_2_master_public_ip" {
  description = "IP de SSH vao Master Node 2"
  value       = aws_instance.cluster_2_master_node.public_ip
}

output "cluster_2_master_private_ip" {
  description = "Private IP cua Master Node 2"
  value       = aws_instance.cluster_2_master_node.private_ip
}

output "cluster_2_workers_private_ips" {
  description = "Private IPs cua cac Worker Node 2"
  value       = aws_instance.cluster_2_worker_node[*].private_ip
}