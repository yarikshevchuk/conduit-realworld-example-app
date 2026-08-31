output "main_server_ip" {
  value       = aws_instance.main.public_ip
  description = "Pubic IP of the Conduit application"
}

output "app_server_public_ip" {
  description = "Static elastic IP"
  value       = aws_eip.eip.public_ip
}