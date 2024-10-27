data "aws_ami" "amazon_linux_2" {
  owners = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.6.20241010.0-kernel-6.1-x86_64"]
  }

  most_recent = true
}


# Security Groups
resource "aws_security_group" "egress-anywhere" {
  vpc_id = aws_vpc.office-vpc.id
  name   = "egress-anywhere"

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    to_port     = 0
    from_port   = 0
    protocol    = -1
    self        = "false"
  }
}

resource "aws_security_group" "ssh-access" {
  vpc_id      = aws_vpc.office-vpc.id
  name        = "ssh-access"
  description = "Allows SSH from anywhere"

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    protocol    = "tcp"
    self        = "false"
    to_port     = 22
  }
}


# Instances
resource "aws_instance" "office-public-server-1a" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"

  subnet_id = aws_subnet.office_subnets["public-1a"].id
  key_name  = local.ec2-key-pair

  vpc_security_group_ids = [
    aws_security_group.egress-anywhere.id,
    aws_security_group.ssh-access.id
  ]

  tags = {
    Name = "office-public-server-1a"
  }
}

resource "aws_instance" "office-private-server-1a" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"

  subnet_id = aws_subnet.office_subnets["private-1a"].id
  key_name  = local.ec2-key-pair

  vpc_security_group_ids = [
    aws_security_group.egress-anywhere.id,
    aws_security_group.ssh-access.id
  ]

  tags = {
    Name = "office-private-server-1a"
  }
}
