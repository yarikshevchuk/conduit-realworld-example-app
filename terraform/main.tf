resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Conduit VPC"
  }
}

# subnets
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "Conduit public subnet"
  }
}

# internet gateways
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Conduit Internet gateway"
  }
}

resource "aws_eip" "eip" {
  instance = aws_instance.main.id
  domain   = "vpc"

  tags = {
    Name = "Conduit elastic IP"
  }
}

# route tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.any_ip
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Conduit public route table"
  }
}

resource "aws_route_table_association" "pub" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public.id
}

# security groups
resource "aws_security_group" "main_sg" {
  name        = "Main-sg"
  description = "Allow all HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "Main security group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "http_in" {
  security_group_id = aws_security_group.main_sg.id

  description = "HTTP through Nginx"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = var.any_ip
}

resource "aws_vpc_security_group_ingress_rule" "ssh_in" {
  security_group_id = aws_security_group.main_sg.id

  description = "SSH"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv4   = var.any_ip
}

resource "aws_vpc_security_group_egress_rule" "http_out" {
  security_group_id = aws_security_group.main_sg.id

  description = "All outbound traffic"
  ip_protocol = "-1"
  cidr_ipv4   = var.any_ip
}

# secrets manager
resource "aws_secretsmanager_secret" "db_creds" {
  name                    = "conduit/db/credentials"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = aws_secretsmanager_secret.db_creds.id
  secret_string = jsonencode({
    DB_USER     = var.DB_USER
    DB_PASSWORD = var.DB_PASSWORD
    DB_NAME     = var.DB_NAME
  })
}

# iam role
resource "aws_iam_role" "ec2_role" {
  name = "conduit-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# iam policy
resource "aws_iam_policy" "read_policy" {
  name        = "conduit-secrets-policy"
  description = "Allow EC2 retrieve secrets from Secrets manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = [aws_secretsmanager_secret.db_creds.arn]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.read_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 instance

resource "aws_key_pair" "key" {
  key_name   = "conduit-ec2-key"
  public_key = file("./conduit_project_key.pub")
}

resource "aws_instance" "main" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.ec2_instance_type
  key_name               = aws_key_pair.key.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.main_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "Conduit EC2 instance"
  }
}


