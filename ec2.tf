# Create the host EC2 Instance
resource "aws_instance" "ubuntu" {
  ami                         = var.ami #Ubuntu 22.04 Jammy x64
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.ubuntu.key_name
  vpc_security_group_ids      = ["${aws_security_group.allow_all.id}"]
  associate_public_ip_address = "true"
  root_block_device {
    volume_size = 40
  }
  tags = {
    Name = "tfe-docker-disk"
  }
  user_data = file("cloudinit.yaml")
  
  provisioner "file" {
    source      = "tfeparty"
    destination = "/home/ubuntu/"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${local_file.key.filename}")
      host        = self.public_ip
    }
  }
}