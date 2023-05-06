variable "vpc-cidr-block" {}
variable "subnet-cidr-block" {}
variable "env_prefix" {}
variable "az" {}

resource "aws_vpc" "myvpc" {
   cidr_block = var.vpc-cidr-block
   tags = {
      Name = "${var.env_prefix}-vpc"
   }
}

resource "aws_subnet" "mysubnet" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = var.subnet-cidr-block
    availability_zone = var.az
    tags = {
      Name = "${var.env_prefix}-subnet"
   }
}
 
resource "aws_internet_gateway" "myigw" {
    vpc_id = aws_vpc.myvpc.id
    tags = {
      Name = "${var.env_prefix}-igw"
   }
}

resource "aws_route_table" "rtb1" {
    vpc_id = aws_vpc.myvpc.id
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.myigw.id
  }
    tags = {  
      Name = "${var.env_prefix}-rtb"
  }
}

resource "aws_route_table_association" "rtb-assoc" {
    subnet_id = aws_subnet.mysubnet.id
    route_table_id = aws_route_table.rtb1.id 
}

resource "aws_security_group" "my-sg" {
    name = "my-sg"
    vpc_id = aws_vpc.myvpc.id

    ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["192.168.0.159/32"]
}
    ingress {
       from_port = 8082
       to_port = 8082
       protocol = "tcp"
       cidr_blocks = ["0.0.0.0/0"]
}
    egress {
       from_port = 0
       to_port = 0
       protocol = "-1"
       cidr_blocks = ["0.0.0.0/0"]
       prefix_list_ids = []
}
    tags = {
      Name = "${var.env_prefix}-sg"
 }
}

    resource "aws_instance" "app-server" {
       ami = "ami-08333bccc35d71140"
       instance_type = "t2.micro"
       subnet_id = aws_subnet.mysubnet.id
       vpc_security_group_ids = [aws_security_group.my-sg.id]
       availability_zone = var.az
       associate_public_ip_address = true
       key_name = "jk2"
         
       user_data = <<EOF
                     #!/bin/bash
                     sudo yum update -y && sudo yum install docker -y
                     sudo systemctl start docker
                     sudo usermod -aG docker ec2-user
                     docker run -p 8082:80 nginx
                   EOF

       tags = {
         Name = "${var.env_prefix}-app-server"
  }
}  
