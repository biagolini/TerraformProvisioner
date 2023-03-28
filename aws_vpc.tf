resource "aws_vpc" "poc_vpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  tags             = { Name = "MyVPC" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.poc_vpc.id
  tags = {
    Name = "POC IG"
  }
}

resource "aws_egress_only_internet_gateway" "egress_only" { ###// Creates an egress-only Internet gateway for your VPC
  vpc_id = aws_vpc.poc_vpc.id
  tags = {
    Name = "IPv6 egress only POC"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.poc_vpc.id
  cidr_block              = "192.168.1.0/24"
  map_public_ip_on_launch = true
  depends_on              = [aws_internet_gateway.gw]
  tags                    = { Name = "Public subnet" }
}


resource "aws_route_table" "webdmz_rt" {
  vpc_id = aws_vpc.poc_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.egress_only.id
  }

  tags = {
    Name = "SG for public subnet"
  }
}

resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.webdmz_rt.id
}

resource "aws_security_group" "webdmz_sg" {
  name        = "webdmz_sg"
  description = "Open HTTP, HTTPS, and SSH to internet"
  vpc_id      = aws_vpc.poc_vpc.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "WebDMZ-SG POC"
  }
}

resource "aws_security_group_rule" "public_in_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.webdmz_sg.id
}

resource "aws_security_group_rule" "public_in_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.webdmz_sg.id
}

resource "aws_security_group_rule" "public_in_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.webdmz_sg.id
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name = "name"
    values = [
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }
  filter {
    name = "owner-alias"
    values = [
      "amazon",
    ]
  }
}

