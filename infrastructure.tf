#############################################################
#   provider
#############################################################

provider "aws" {
    access_key = "AKIARUHWLGNXCEPFC6QI"
    secret_key = "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"
    region = "us-east-1"
}

#############################################################
#   data
#############################################################

data "aws_ssm_parameter" "ami" {
    #name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
    name = "/aws/service/canonical/ubuntu/server/20.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

data "aws_ami" "ubuntu-ami" {
  owners = ["099720109477"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20220110"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
#############################################################
#   resource
#############################################################

# Networking

resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = "true"
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet1" {
    cidr_block =  "10.0.0.0/24"
    vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet2" {
    cidr_block =  "10.0.1.0/24"
    vpc_id = aws_vpc.vpc.id
    availability_zone = "us-east-1a"
}

resource "aws_subnet" "subnet3" {
    cidr_block =  "10.0.2.0/24"
    vpc_id = aws_vpc.vpc.id
    availability_zone = "us-east-1c"
}

resource "aws_db_subnet_group" "mail-subnet-group" {
  name       = "mail_subnet_group"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id, aws_subnet.subnet3.id]

  tags = {
    Name = "My DB subnet group"
  }
}

# Routing

resource "aws_route_table" "rtb" {
    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

resource "aws_route_table_association" "rta-subnet1" {
    subnet_id = aws_subnet.subnet1.id
    route_table_id = aws_route_table.rtb.id
}


# Security Groups

resource "aws_security_group" "ssh-server-sg" {
    name = "ssh-server-sg"
    vpc_id = aws_vpc.vpc.id

    # SMTP access from anywhere
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Outbound internet access
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "mail-database-sg" {
    name = "mail_database_sg"
    vpc_id = aws_vpc.vpc.id

    # SMTP access from anywhere
    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Outbound internet access
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "mail-server-sg" {
    name = "mail_server_sg"
    vpc_id = aws_vpc.vpc.id

    # SMTP access from anywhere
    ingress {
        from_port = 25
        to_port = 25
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Outbound internet access
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "web-mail-server-sg" {
    name = "web-mail-server-sg"
    vpc_id = aws_vpc.vpc.id

    # HTTP access from anywhere
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
   
    # Outbound internet access
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "drive-server-sg" {
    name = "drive-server-sg"
    vpc_id = aws_vpc.vpc.id

    # HTTP access from anywhere
    ingress {
        from_port = 8000
        to_port = 8000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress {
        from_port = 8082
        to_port = 8082
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
   
    # Outbound internet access
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "instant-message-server-sg" {
    name = "instant-message-server-sg"
    vpc_id = aws_vpc.vpc.id

    # HTTP access from anywhere
    ingress {
        from_port = 3000
        to_port = 3000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Outbound internet access
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "LDAP-server-sg" {
    name = "LDAP-server-sg"
    vpc_id = aws_vpc.vpc.id

    # HTTP access from anywhere
    ingress {
        from_port = 389
        to_port = 389
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Outbound internet access
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "libreoffice-server-sg" {
    name = "libreoffice-server-sg"
    vpc_id = aws_vpc.vpc.id

    # HTTP access from anywhere
    ingress {
        from_port = 9980
        to_port = 9980
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Outbound internet access
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Key pairs

resource "aws_key_pair" "aws_mail_key" {
  key_name   = "aws-mail-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC+pkiYXx9qNZeIJYc01LEiHSt2IQ6Q2qh4K+YblmErvHUkGpixgQ0KneZvScJeY5wY2UwUh3SO+PrdlMqSgZ4srXm5K7vCxv5ghiSzP8ak1oDBRlDMp/StuEAdizWSVPfVKj0EAyEuV0lqtlD0WLDLBnXfWfklC8bK6yKrW87whVGfAtNg2d75bTl/fvTpEuZ6/umQsGHz3UtEeyJ7AZgqRrjzwAg6D4IgQgMSbT7LwUaJn6q2cColk7y48I5BwYpf/GYQVIYubdeedcbAh2NUY8W9cjcdHS6a87qjfr4i6P0MvUVcCtsWjxbNWxKEwlDmWLAh59pX4d9Q88K6MUYmcxunvWCqQcYLcIv9vstpRoP0aqnakD22DrLuGo+gCPSX9yS2VJ9letrkRCyf8nGi10nIiu4TuvcEsbSXrRYA0iTPDS437UPX0YDb9nGidpXZ1x40wqyYRo2HZFNjCZeseao7CUcFxy/TYmhdrez7ccOTwCvddXLVDCMAmqZL1fc= l.tsimi.ext@ldp-1759"
}


# Instances

resource "aws_instance" "mail_server" {
    ami = data.aws_ami.ubuntu-ami.id
    instance_type = "t2.micro"
    subnet_id = aws_subnet.subnet1.id
    associate_public_ip_address = "true"
    key_name = "aws-mail-key"
    vpc_security_group_ids = [aws_security_group.mail-server-sg.id, aws_security_group.web-mail-server-sg.id, aws_security_group.ssh-server-sg.id]
    lifecycle {
      ignore_changes = [
        associate_public_ip_address,
      ]
    }
    tags = {
    Name = "mail_server"
    }
}

resource "aws_instance" "ldap_mail_server" {
    ami = data.aws_ami.ubuntu-ami.id
    instance_type = "t2.micro"
    subnet_id = aws_subnet.subnet1.id
    associate_public_ip_address = "true"
    key_name = "aws-mail-key"
    vpc_security_group_ids = [aws_security_group.mail-server-sg.id, aws_security_group.web-mail-server-sg.id, aws_security_group.ssh-server-sg.id, aws_security_group.LDAP-server-sg.id]
    lifecycle {
      ignore_changes = [
        associate_public_ip_address,
      ]
    }
    tags = {
    Name = "ldap_mail_server"
    }
}

resource "aws_instance" "Instant_Message_server" {
    ami = data.aws_ami.ubuntu-ami.id
    instance_type = "t2.micro"
    subnet_id = aws_subnet.subnet1.id
    associate_public_ip_address = "true"
    key_name = "aws-mail-key"
    vpc_security_group_ids = [aws_security_group.mail-server-sg.id, aws_security_group.web-mail-server-sg.id, aws_security_group.ssh-server-sg.id, aws_security_group.instant-message-server-sg.id]
    lifecycle {
      ignore_changes = [
        associate_public_ip_address,
      ]
    }
    tags = {
    Name = "Instant_Message_server"
    }
}

resource "aws_instance" "rocket_chat_server" {
    ami = data.aws_ami.ubuntu-ami.id
    instance_type = "t2.micro"
    subnet_id = aws_subnet.subnet1.id
    associate_public_ip_address = "true"
    key_name = "aws-mail-key"
    vpc_security_group_ids = [aws_security_group.mail-server-sg.id, aws_security_group.web-mail-server-sg.id, aws_security_group.ssh-server-sg.id, aws_security_group.instant-message-server-sg.id]
    lifecycle {
      ignore_changes = [
        associate_public_ip_address,
      ]
    }
    tags = {
    Name = "rocket_chat_server"
    }
}

resource "aws_instance" "seafile_server" {
    ami = data.aws_ami.ubuntu-ami.id
    instance_type = "t2.micro"
    subnet_id = aws_subnet.subnet1.id
    associate_public_ip_address = "true"
    key_name = "aws-mail-key"
    vpc_security_group_ids = [aws_security_group.drive-server-sg.id, aws_security_group.mail-server-sg.id, aws_security_group.web-mail-server-sg.id, aws_security_group.ssh-server-sg.id, aws_security_group.instant-message-server-sg.id]
    lifecycle {
      ignore_changes = [
        associate_public_ip_address,
      ]
    }
    tags = {
    Name = "seafile_server"
    }
}

resource "aws_instance" "libreoffice_server" {
    ami = data.aws_ami.ubuntu-ami.id
    instance_type = "t2.micro"
    subnet_id = aws_subnet.subnet1.id
    associate_public_ip_address = "true"
    key_name = "aws-mail-key"
    vpc_security_group_ids = [aws_security_group.libreoffice-server-sg.id, aws_security_group.drive-server-sg.id, aws_security_group.mail-server-sg.id, aws_security_group.web-mail-server-sg.id, aws_security_group.ssh-server-sg.id, aws_security_group.instant-message-server-sg.id]
    lifecycle {
      ignore_changes = [
        associate_public_ip_address,
      ]
    }
    tags = {
    Name = "libreoffice_server"
    }
}

# Database Instances
resource "aws_db_instance" "mail_database_instance" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "postfix"
  username             = "admin"
  password             = "Admin2022"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.mail-subnet-group.name
  vpc_security_group_ids = [aws_security_group.mail-database-sg.id]
}