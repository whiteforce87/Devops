provider "aws" {
  region = "eu-west-1"
}

resource "aws_instance" "project-server" {
    ami           = "ami-0776c814353b4814d"
    instance_type = each.value.instance_type
    key_name      = "keyPair"
    //security_groups = [ "project-sg" ]
    vpc_security_group_ids = [aws_security_group.project-sg.id]
    subnet_id = aws_subnet.fth-public-subnet-01.id 
    //this is for create EC2 instance for each below, for multiple EC2 creation
    //for_each = toset(["jenkins-master", "build-slave", "ansible"])

    # Using for_each to create instances with different configurations
    for_each = {
      "jenkins-master" = { volume_size = 8, instance_type = "t2.micro" }
      "build-slave"    = { volume_size = 14, instance_type = "t2.small", ami="ami-0776c814353b4814d" }
      "ansible"        = { volume_size = 8, instance_type = "t2.micro" }
    }
    
    root_block_device {
        volume_size = each.value.volume_size
        volume_type = "gp2"
    }


    # If swap volume is needed for over RAM load use this, but it uses harddisk space
    //ebs_block_device {
    //    device_name = "/dev/xvdf"  # Swap alanı için bir cihaz adı belirtin
    //    volume_size = 10  # Swap alanı boyutunu belirtin
    //    volume_type = "gp2"  # Swap alanı için uygun bir depolama türü belirtin
    //}

   tags = {
     Name = "${each.key}"
   }
   user_data = <<-EOF
              #!/bin/bash
              sudo chmod 777 /var/run/docker.sock
            EOF

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

    ingress {
    description      = "Jenkins port"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }

    ingress {
    description      = "Mysql port"
    from_port        = 3306
    to_port          = 3306
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
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "fth-vpc"
  }
}

resource "aws_subnet" "fth-public-subnet-01" {
  vpc_id = aws_vpc.fth-vpc.id
  cidr_block = "10.1.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "eu-west-1a"
  tags = {
    Name = "fth-public-subent-01"
  }
}

resource "aws_subnet" "fth-public-subnet-02" {
  vpc_id = aws_vpc.fth-vpc.id
  cidr_block = "10.1.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "eu-west-1b"
  tags = {
    Name = "fth-public-subent-02"
  }
}

resource "aws_internet_gateway" "fth-gw" {
  vpc_id = aws_vpc.fth-vpc.id 
  tags = {
    Name = "fth-gw"
  } 
}

resource "aws_route_table" "fth-public-rt" {
  vpc_id = aws_vpc.fth-vpc.id 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fth-gw.id 
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

/*
//Below part is related kubernetes - eks 
module "sgs" {
    source = "../sg_eks"
    vpc_id  =  aws_vpc.fth-vpc.id
}

module "eks" {
   source = "../eks"
   vpc_id  =  aws_vpc.fth-vpc.id
   subnet_ids = [aws_subnet.fth-public-subnet-01.id,aws_subnet.fth-public-subnet-02.id]
   sg_ids = module.sgs.security_group_public
}
*/

//Commands:
//terraform init
//terraform validate
//terraform plan
//terraform apply --auto-approve