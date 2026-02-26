# Ubuntu 22.04 LTS (Official Canonical)


data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical Official AWS Account

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for EC2 (HTTP + HTTPS + SSH optional)

resource "aws_security_group" "ec2_sg" {
  name        = "${var.environment}-ec2-sg"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = aws_vpc.main.id

  # HTTP
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # OPTIONAL SSH (restrict to your IP in real production)
  ingress {
    description = "Allow SSH (Restrict in production)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound - allow all (required for updates, S3, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-ec2-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# EC2 Instance (Public Subnet)

resource "aws_instance" "app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

    # Encrypted Root Volume (Production Ready)

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  # Enforce IMDSv2 (Security Best Practice)

  metadata_options {
    http_tokens = "required"
  }
  
  # Enable Detailed Monitoring
  
  monitoring = true

    # Basic User Data (Optional - Install Nginx)
  
  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y nginx
              systemctl enable nginx
              systemctl start nginx
              EOF

  tags = {
    Name        = "${var.environment}-ec2"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Output Public IP

output "ec2_public_ip" {
  value = aws_instance.app.public_ip
}
