data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  availability_zone = var.zone
  vpc_id            = data.aws_vpc.default.id
  default_for_az    = true
}

# AMI designed for NAT purposes
# https://docs.aws.amazon.com/vpc/latest/userguide/VPC_NAT_Instance.html#nat-instance-ami
data "aws_ami" "nat" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat-2018.03.0*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_security_group" "nat_access" {
  name        = "nat_access"
  description = "Allow SSH access only from single computer and HTTP traffic to the internt"

  tags = {
    Name = "nat_access"
  }

  ingress {
    description = "SSH from laptop only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.external_access_ip}/32"]
  }
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }
  ingress {
    description = "HTTP from private subnetwork"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.private_a.cidr_block]
  }
  ingress {
    description = "HTTPS from private subnetwork"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.private_a.cidr_block]
  }

  # Terraform removed default egress ALLOW_ALL rule
  # It has to be explicitely added
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# setup NAT instance as NAT Gateway is not free-tier eliglible
resource "aws_instance" "nat" {
  ami                    = data.aws_ami.nat.id
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnet.default.id
  key_name               = aws_key_pair.vm_key.key_name
  vpc_security_group_ids = [aws_security_group.nat_access.id]
  # NAT instance has to have source / dest adress check disabled
  source_dest_check = false
  user_data         = file("nat.cloud-init.yaml")
  tags = {
    Name = "nat"
  }
}


resource "aws_subnet" "private_a" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.96.0/20"
  availability_zone       = var.zone
  map_public_ip_on_launch = false
  tags = {
    Name = "private for ${var.zone}"
    Tier = "private"
  }
}


resource "aws_route_table" "natted" {
  vpc_id = data.aws_vpc.default.id

  # default route, mapping the VPC's CIDR block to "local", is created implicitly and cannot be specified.
  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = aws_instance.nat.id
  }

  tags = {
    Name = "natted"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.natted.id
}


resource "aws_security_group" "http_from_single_computer" {
  name        = "http_from_single_computer"
  description = "Allow HTTP access only from single computer"

  tags = {
    Name = "http_from_single_computer"
  }

  ingress {
    description = "HTTP from laptop only"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.external_access_ip}/32"]
  }

  # Terraform removed default egress ALLOW_ALL rule
  # It has to be explicitely added
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "nat_id" {
  value = aws_instance.nat.id
}

output "nat_ip" {
  value = aws_instance.nat.public_ip
}

output "nat_dns" {
  value = aws_instance.nat.public_dns
}

output "nat_ssh" {
  description = "Connect to NAT instance"
  value       = format("ssh -i ~/.ssh/id_rsa.aws.vm ec2-user@%s", aws_instance.nat.public_dns)
}
