output "main_server_ip" {
  value = aws_instance.main.public_ip
  description = "Pubic IP of the Conduit application"
}

