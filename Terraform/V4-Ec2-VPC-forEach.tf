provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "project-server" {
    ami           = "ami-04b70fa74e45c3917"
    instance_type = "t2.micro"
    key_name      = "keyPair"
    //security_groups = [ "project-sg" ]
    vpc_security_group_ids = [aws_security_group.project-sg.id]
    subnet_id = aws_subnet.fth-public-subnet-01.id 
    //this is for create EC2 instance for each, for multiple EC2 creation
    for_each = toset(["jenkins-master", "build-slave", "ansible"])
   tags = {
     Name = "${each.key}"
   }

}

resource "aws_security_group" "project-sg" {
  name        = "project-sg"
  description = "SSH Access"
  vpc_id = aws_vpc.fth-vpc.id 
  
  ingress {
    description      = "Shh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ssh-prot"

  }
}

resource "aws_vpc" "fth-vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "fth-vpc"
  }
  
}

resource "aws_subnet" "fth-public-subnet-01" {
  vpc_id = aws_vpc.fth-vpc.id
  cidr_block = "10.1.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-1a"
  tags = {
    Name = "fth-public-subent-01"
  }
}

resource "aws_subnet" "fth-public-subnet-02" {
  vpc_id = aws_vpc.fth-vpc.id
  cidr_block = "10.1.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-1b"
  tags = {
    Name = "fth-public-subent-02"
  }
}

resource "aws_internet_gateway" "fth-igw" {
  vpc_id = aws_vpc.fth-vpc.id 
  tags = {
    Name = "fth-igw"
  } 
}

resource "aws_route_table" "fth-public-rt" {
  vpc_id = aws_vpc.fth-vpc.id 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fth-igw.id 
  }
}

resource "aws_route_table_association" "fth-rta-public-subnet-01" {
  subnet_id = aws_subnet.fth-public-subnet-01.id
  route_table_id = aws_route_table.fth-public-rt.id   
}

resource "aws_route_table_association" "fth-rta-public-subnet-02" {
  subnet_id = aws_subnet.fth-public-subnet-02.id 
  route_table_id = aws_route_table.fth-public-rt.id   
}

//Commands:
//terraform init
//terraform validate
//terraform plan
//terraform apply --auto-approve