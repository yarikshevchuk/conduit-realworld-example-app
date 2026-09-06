variable "aws_region" {
  default = "eu-central-1"
  type    = string
}

variable "any_ip" {
  description = "All possible IPs"
  default     = "0.0.0.0/0"
  type        = string
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro"
  type        = string
}

variable "DB_USER" {
  type      = string
  sensitive = true
}

variable "DB_PASSWORD" {
  type      = string
  sensitive = true
}

variable "DB_NAME" {
  type      = string
  sensitive = true
}