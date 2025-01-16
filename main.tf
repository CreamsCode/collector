provider "aws" {
  region = "us-east-1" # Cambia la región si es necesario
}

# Crear una cola SQS
resource "aws_sqs_queue" "scraper_queue" {
  name = "scraper-queue"
}

# Crear un grupo de seguridad para la instancia EC2
resource "aws_security_group" "ec2_sg" {
  name_prefix = "scraper-sg"

  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_instance" "scraper_instance" {
  ami           = "ami-05576a079321f21f8"
  instance_type = "t2.micro"
  key_name      = "vockey"
  iam_instance_profile   = "EMR_EC2_DefaultRole"

  security_groups = [aws_security_group.ec2_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras enable python3.8
              yum install -y python3.8 git
              pip3 install --upgrade pip
              git clone https://github.com/CreamsCode/collector.git /home/ec2-user/scraper
              cd /home/ec2-user/scraper
              pip3 install -r requirements.txt
              python3 main.py --queue_url ${aws_sqs_queue.scraper_queue.url}
              EOF

  tags = {
    Name = "Scraper"
  }
}

# Salidas para información importante
output "sqs_queue_url" {
  value = aws_sqs_queue.scraper_queue.url
}

output "ec2_public_ip" {
  value = aws_instance.scraper_instance.public_ip
}
