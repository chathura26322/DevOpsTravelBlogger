provider "aws" {
  region = "ap-south-1"  # Mumbai region
}

resource "aws_instance" "mern_app" {
  ami           = "ami-002f6e91abff6eb96"  # Amazon Linux 2 for ap-south-1
  instance_type = "t2.micro"
  key_name      = "mern-keypair"
  security_groups = [aws_security_group.mern_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              EOF

  tags = {
    Name = "mern-app-instance"
  }
}

resource "aws_security_group" "mern_sg" {
  name        = "mern-app-sg-${formatdate("YYYYMMDDHHMMSS", timestamp())}"
  description = "Allow traffic for MERN app"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5173
    to_port     = 5173
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "instance_public_ip" {
  value = aws_instance.mern_app.public_ip
}