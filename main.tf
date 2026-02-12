terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
provider "aws" {
    region = "eu-north-1"
}

#VPC
resource "aws_vpc" "myvpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
      Name = "my-VPC"
    }
  
}
# subnet
resource "aws_subnet" "public-cub" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "eu-north-1a"

    tags = {
      Name = "public-sub"
    }
  
}

resource "aws_subnet" "private-sub" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "eu-north-1a"
    map_public_ip_on_launch = false


    tags = {
      Name = "private-sub"
    }
}

# IGW 

resource "aws_internet_gateway" "myigw" {
    vpc_id = aws_vpc.myvpc.id

    tags = {
      Name = "my-igw"
    }
}
/*
resource "aws_internet_gateway_attachment" "attach" {
    internet_gateway_id = aws_internet_gateway.myigw.id
    vpc_id = aws_vpc.myvpc.id
  
}*/

# Route Table

resource "aws_route_table" "public-route" {
    vpc_id = aws_vpc.myvpc.id
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myigw.id
    }
  tags = {
    Name = "public-route"
  }
}

resource "aws_route_table_association" "a" {
    subnet_id = aws_subnet.public-cub.id
    route_table_id = aws_route_table.public-route.id
  
}

# Security Group

resource "aws_security_group" "vpc-sg" {
    name = "vpc-sg"
    vpc_id =  aws_vpc.myvpc.id
    

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}

# NIC

resource "aws_network_interface" "inter" {
    subnet_id = aws_subnet.public-cub.id
    private_ips = [ "10.0.1.100" ]

    tags = {
      Name = "public-NIC"
    }
  
}

# EC2

resource "aws_instance" "myec2" {
    ami = "ami-073130f74f5ffb161"
    instance_type = "t3.micro"
    key_name = "demo"
    subnet_id = aws_subnet.public-cub.id
    vpc_security_group_ids = [ aws_security_group.vpc-sg.id ]
    /*network_interface{
        network_interface_id = aws_network_interface.inter.id
        device_index = 0
    }*/
    tags ={
        Name = "vpc-ec2"
    }
    user_data = base64encode(<<-EOF
        #!/bin/bash
        apt update -y
        apt install -y nginx
        systemctl enable nginx
        systemctl start nginx
    EOF
    )
}

output "vpc" {
    value = aws_vpc.myvpc.tags
  
}
output "public-ip" {
    value = aws_instance.myec2.public_ip
}
output "subnet" {
    value = aws_subnet.public-cub.tags  
}
output "ec2" {
    value = aws_instance.myec2.private_ip
  
}
