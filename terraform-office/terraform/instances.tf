resource "aws_key_pair" "main_server_key" {
  key_name   = "main_server_key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICChMNNqLJZ+G+JokEVXJCDxMboTlWmYDOpnZEt3Y0v8"
}

data "aws_ami" "amazon_linux_2" {
  owners = ["137112412989"] # amazon id

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
  key_name  = aws_key_pair.main_server_key.key_name

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
  key_name  = aws_key_pair.main_server_key.key_name

  vpc_security_group_ids = [
    aws_security_group.egress-anywhere.id,
    aws_security_group.ssh-access.id
  ]

  tags = {
    Name = "office-private-server-1a"
  }
}


resource "aws_launch_template" "bastion" {
  name                   = "bastion"
  description            = "managed by Terraform"
  image_id               = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.main_server_key.key_name
  update_default_version = true

  network_interfaces {
    delete_on_termination = true
    security_groups = [
      aws_security_group.egress-anywhere.id,
      aws_security_group.ssh-access.id
    ]
  }


  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "bastion"
    }
  }
}


resource "aws_autoscaling_group" "bastion" {
  name             = "bastion"
  max_size         = 1
  min_size         = 1
  desired_capacity = 1

  vpc_zone_identifier = [
    aws_subnet.office_subnets["public-1a"].id,
    aws_subnet.office_subnets["public-1b"].id
  ]

  launch_template {
    id      = aws_launch_template.bastion.id
    version = aws_launch_template.bastion.latest_version
  }
}


resource "aws_cloudwatch_event_rule" "asg_eip_assignment" {
  name        = "asg-eip-assignment"
  description = "Assigning an Elastic IP when starting an Auto Scaling Group instance"

  event_pattern = jsonencode({
    source      = ["aws.autoscaling"]
    detail-type = ["EC2 Instance Launch Successful"]
    detail = {
      AutoScalingGroupName = [aws_autoscaling_group.bastion.name]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.asg_eip_assignment.name
  target_id = "lambda_eip_assigner"
  arn       = aws_lambda_function.eip_assigner.arn
}


resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# TODO: че такое,
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_exec_policy" {
  name        = "lambda_exec_policy"
  description = "Policy for Lambda to associate EIP"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "ec2:AssociateAddress",
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_exec_role_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_exec_policy.arn
}


locals {
  lambda_path     = "lambda-eip-assigner"
  lambda_zip_path = "../${local.lambda_path}/.aws-sam/build/eip-assigner.zip"
}


resource "aws_eip" "instance_ip" {
  public_ipv4_pool     = "amazon"
  network_border_group = var.region

  tags = {
    Name = "bastion"
  }
}



resource "aws_lambda_function" "eip_assigner" {
  function_name = "eip-assigner"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.13"

  filename         = local.lambda_zip_path
  source_code_hash = filesha256(local.lambda_zip_path)

  timeout     = 30
  memory_size = 128
  publish     = true

  environment {
    variables = {
      ELASTIC_IP_ALLOCATION_ID = aws_eip.instance_ip.allocation_id
    }
  }
}

resource "aws_lambda_permission" "eventbridge_invoke_permission" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.eip_assigner.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.asg_eip_assignment.arn
}