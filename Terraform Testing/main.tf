terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~>3.0"
    }
  }
}

#configure the AWS provider
#Using the Terraform user keys. This is not recommended for production use.
provider "aws" {
    region = "us-east-2"
}

#Create VPC
#Creating a resource with a custom reference name
resource "aws_vpc" "DevOps-VPC"{
    cidr_block = var.cidr_block[0]

    tags = {
        Name = "DevOps-VPC"
    }
}

#Create Subnet (Public)

resource "aws_subnet" "DevOps-Public-Subnet" {
    vpc_id = aws_vpc.DevOps-VPC.id
    cidr_block = var.cidr_block[1]

    tags = {
        Name = "DevOps-Public-Subnet"
    }
}

#Create Internet Gateway

resource "aws_internet_gateway" "Devops-Internet-Gateway" {
    vpc_id = aws_vpc.DevOps-VPC.id

    tags = {
        Name = "DevOps-Internet-Gateway"
    }
}
  
#Create Security Group

resource "aws_security_group" "Devops_Security_Group" {
  name = "Devops Security Group"
  description = "Allow inbound & outbound traffic from all sources"
  vpc_id = aws_vpc.DevOps-VPC.id


allow SSH inbound traffic
   ingress {
     from_port = 22
     to_port = 22 #port 22 is SSH
     protocol = "tcp" #tcp is the protocol
     cidr_blocks = ["0.0.0.0/0"] #Allows connections from all sources
   }

  dynamic "ingress" { #dynamic allows us to iteratively use content from the variables.tf file
    iterator = port
    for_each = var.ports
      content {
        from_port = port.value
        to_port = port.value
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
  }

  egress {
    from_port = 0 #0 means all ports
    to_port = 0
    protocol = "-1" #-1 is a wildcard for all protocols
    cidr_blocks = ["0.0.0.0/0"] #Allows connections from all sources
  }

  tags = {
    Name = "Allow SSH in, all traffic out."
  }
  
}

#Create an AWS Jenkins instance

resource "aws_instance" "Jenkins" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name = "EC2-us-east-2"
  vpc_security_group_ids = [aws_security_group.Devops_Security_Group.id]
  subnet_id = aws_subnet.DevOps-Public-Subnet.id
  associate_public_ip_address = true
  user_data = file("./InstallJenkins.sh")

  tags = {
    "Name" = "Jenkins-Server"
  }
}


#Create an AWS Ansible instance

resource "aws_instance" "AnsibleController" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name = "EC2-us-east-2"
  vpc_security_group_ids = [aws_security_group.Devops_Security_Group.id]
  subnet_id = aws_subnet.DevOps-Public-Subnet.id
  associate_public_ip_address = true
  user_data = file("./InstallAnsibleCN.sh")

  tags = {
    "Name" = "Ansible-ControlNode"
  }
}

resource "aws_instance" "AnsibleManagedNode1" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name = "EC2-us-east-2"
  vpc_security_group_ids = [aws_security_group.Devops_Security_Group.id]
  subnet_id = aws_subnet.DevOps-Public-Subnet.id
  associate_public_ip_address = true
  user_data = file("./AnsibleManagedNode.sh")

  tags = {
    "Name" = "Ansible-Managed-ApacheTomcat"
  }
}

resource "aws_instance" "Docker" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name = "EC2-us-east-2"
  vpc_security_group_ids = [aws_security_group.Devops_Security_Group.id]
  subnet_id = aws_subnet.DevOps-Public-Subnet.id
  associate_public_ip_address = true
  user_data = file("./Docker.sh")

  tags = {
    "Name" = "Docker"
  }
}

resource "aws_instance" "Nexus" {
  ami           = var.ami
  instance_type = var.instance_type_for_nexus
  key_name = "EC2-us-east-2"
  vpc_security_group_ids = [aws_security_group.Devops_Security_Group.id]
  subnet_id = aws_subnet.DevOps-Public-Subnet.id
  associate_public_ip_address = true
  user_data = file("./InstallNexus.sh")

  tags = {
    "Name" = "Nexus-Server"
  }
}

#Create route table & association

resource "aws_route_table" "DevOps-Public-Route-Table" {
    vpc_id = aws_vpc.DevOps-VPC.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.Devops-Internet-Gateway.id
    }

    tags = {
      Name = "Devops-Public-Route-Table"
    }
  
}

resource "aws_route_table_association" "DevOpsRoute_Assn" {
    subnet_id = aws_subnet.DevOps-Public-Subnet.id
    route_table_id = aws_route_table.DevOps-Public-Route-Table.id
}


  