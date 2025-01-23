resource "aws_security_group" "egress-anywhere" {
  vpc_id = var.vpc_id
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
  vpc_id      = var.vpc_id
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
