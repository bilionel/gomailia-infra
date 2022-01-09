#############################################################
#   provider
#############################################################

provider "aws" {
    access_key = "AKIAQQY5CCC5BJYLIBPL"
    secret_key = "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"
    region = "us-east-2"
}

#############################################################
#   data
#############################################################

data "aws_ssm_parameter" "ami" {
    #name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
    name = "/aws/service/canonical/ubuntu/server/20.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
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
        from_port = 0
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

resource "aws_security_group" "mail-server-sg" {
    name = "mail_server_sg"
    vpc_id = aws_vpc.vpc.id

    # SMTP access from anywhere
    ingress {
        from_port = 0
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
        from_port = 0
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

# Key pairs
resource "aws_key_pair" "aws_mail_key" {
  key_name   = "aws-mail-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC+pkiYXx9qNZeIJYc01LEiHSt2IQ6Q2qh4K+YblmErvHUkGpixgQ0KneZvScJeY5wY2UwUh3SO+PrdlMqSgZ4srXm5K7vCxv5ghiSzP8ak1oDBRlDMp/StuEAdizWSVPfVKj0EAyEuV0lqtlD0WLDLBnXfWfklC8bK6yKrW87whVGfAtNg2d75bTl/fvTpEuZ6/umQsGHz3UtEeyJ7AZgqRrjzwAg6D4IgQgMSbT7LwUaJn6q2cColk7y48I5BwYpf/GYQVIYubdeedcbAh2NUY8W9cjcdHS6a87qjfr4i6P0MvUVcCtsWjxbNWxKEwlDmWLAh59pX4d9Q88K6MUYmcxunvWCqQcYLcIv9vstpRoP0aqnakD22DrLuGo+gCPSX9yS2VJ9letrkRCyf8nGi10nIiu4TuvcEsbSXrRYA0iTPDS437UPX0YDb9nGidpXZ1x40wqyYRo2HZFNjCZeseao7CUcFxy/TYmhdrez7ccOTwCvddXLVDCMAmqZL1fc= l.tsimi.ext@ldp-1759"
}


# Instances
resource "aws_instance" "mail_server" {
    ami = nonsensitive(data.aws_ssm_parameter.ami.value)
    instance_type = "t2.micro"
    subnet_id = aws_subnet.subnet1.id
    associate_public_ip_address = "true"
    key_name = "aws-mail-key"
    vpc_security_group_ids = [aws_security_group.mail-server-sg.id, aws_security_group.web-mail-server-sg.id, aws_security_group.ssh-server-sg.id]
}