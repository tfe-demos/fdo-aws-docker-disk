output "public_ip" {
  value = aws_instance.ubuntu.public_ip
}

output "public_dns" {
  value = aws_instance.ubuntu.public_dns
}

output "connection_string" {
  value = "ssh -i ubuntu.pem ubuntu@${aws_instance.ubuntu.public_dns}"
}