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

# Instances
resource "aws_instance" "mail_server" {
    ami = nonsensitive(data.aws_ssm_parameter.ami.value)
    instance_type = "t2.micro"
    subnet_id = aws_subnet.subnet1.id
    vpc_security_group_ids = [aws_security_group.mail-server-sg.id, aws_security_group.web-mail-server-sg.id, aws_security_group.ssh-server-sg.id]
}