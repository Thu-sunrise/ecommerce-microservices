
# đẩy mặt Public Key lên AWS
resource "aws_key_pair" "ecommerce_keypair" {
  key_name   = "ecommerce-key-v1"
  public_key = file("${path.module}/ecommerce-ssh-key.pub")
}
