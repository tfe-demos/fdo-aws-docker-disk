# Create SSH private key (Only for demo as the key will be cleartext in the state)
resource "tls_private_key" "ubuntu" {
  algorithm = "RSA"
}

# Export the SSH private key to file
resource "local_file" "key" {
  content         = tls_private_key.ubuntu.private_key_pem
  filename        = "ubuntu.pem"
  file_permission = "0400"
}

# Generate public key based on the created private key we just created
resource "aws_key_pair" "ubuntu" {
  key_name   = "ubuntu"
  public_key = tls_private_key.ubuntu.public_key_openssh
}