provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "Main-VPC"
  }
}

resource "aws_subnet" "scraper_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "Scraper-Subnet"
  }
}

resource "aws_internet_gateway" "scraper_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "Scraper-IGW"
  }
}

resource "aws_route_table" "scraper_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.scraper_igw.id
  }

  tags = {
    Name = "Scraper-Route-Table"
  }
}

resource "aws_route_table_association" "scraper_route_table_assoc" {
  subnet_id      = aws_subnet.scraper_subnet.id
  route_table_id = aws_route_table.scraper_route_table.id
}

resource "aws_security_group" "ec2_sg" {
  name_prefix = "scraper-sg"
  vpc_id      = aws_vpc.main_vpc.id

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

  tags = {
    Name = "Scraper-SG"
  }
}

resource "aws_sqs_queue" "scraper_queue" {
  name = "scraper-queue"
}

resource "aws_instance" "scraper_instance" {
  ami           = "ami-05576a079321f21f8"
  instance_type = "t2.micro"
  key_name      = "vockey"
  subnet_id     = aws_subnet.scraper_subnet.id
  iam_instance_profile   = "EMR_EC2_DefaultRole"

  security_groups = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y python git pip
              sudo pip3 install --upgrade pip
              sudo git clone https://github.com/CreamsCode/collector.git /home/ec2-user/scraper
              cd /home/ec2-user/scraper
              sudo pip3 install -r requirements.txt
              sudo python3 main.py --queue_url ${aws_sqs_queue.scraper_queue.url}
              EOF

  tags = {
    Name = "Scraper"
  }
}

output "sqs_queue_url" {
  value = aws_sqs_queue.scraper_queue.url
}

output "collector_public_ip" {
  value = aws_instance.scraper_instance.public_ip
}

resource "aws_ssm_parameter" "vpc_id" {
  name  = "/shared/vpc/id"
  type  = "String"
  value = aws_vpc.main_vpc.id
  tags = {
    Name = "shared-vpc-id"
  }
}


resource "aws_ssm_parameter" "sqs_queue_url" {
  name  = "sqs_queue_url"
  type  = "String"
  overwrite = true
  value = aws_sqs_queue.scraper_queue.url
}

resource "aws_ssm_parameter" "scraper_ip" {
  name  = "scraper_ip"
  type  = "String"
  overwrite = true
  value = aws_instance.scraper_instance.public_ip
}

