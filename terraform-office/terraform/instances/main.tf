resource "aws_key_pair" "main_server_key" {
  key_name   = "main_server_key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICChMNNqLJZ+G+JokEVXJCDxMboTlWmYDOpnZEt3Y0v8"
}

// TODO: in further configure Security Groups between bastion and inner servers
// configure SSH key deployment and secure managing this key with SSH Forwaring may be, ssh-agent

data "aws_ami" "amazon_linux_2" {
  owners = ["137112412989"] # amazon id

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.20250116.0-x86_64-gp2"]
  }

  most_recent = true
}

resource "aws_launch_template" "default_server" {
  name                   = "default_server"
  image_id               = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.main_server_key.key_name
  update_default_version = true

  metadata_options {
    http_endpoint          = "enabled"
    http_tokens            = "required"
    instance_metadata_tags = "enabled"
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "default_server"
    }
  }
}

resource "aws_instance" "office-public-server-1a" {
  subnet_id = var.subnets["public-1a"].id

  launch_template {
    id      = aws_launch_template.default_server.id
    version = aws_launch_template.default_server.latest_version
  }

  vpc_security_group_ids = [
    aws_security_group.egress-anywhere.id,
    aws_security_group.ssh-access.id,
  ]

  tags = {
    Name = "office-public-server-1a"
  }
}

resource "aws_instance" "office-private-server-1a" {
  subnet_id = var.subnets["private-1a"].id

  launch_template {
    id      = aws_launch_template.default_server.id
    version = aws_launch_template.default_server.latest_version
  }

  vpc_security_group_ids = [
    aws_security_group.egress-anywhere.id,
    aws_security_group.ssh-access.id,
  ]

  tags = {
    Name = "office-private-server-1a"
  }
}


resource "aws_launch_template" "bastion" {
  name                   = "bastion"
  image_id               = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.main_server_key.key_name
  update_default_version = true

  vpc_security_group_ids = [
    aws_security_group.egress-anywhere.id,
    aws_security_group.ssh-access.id
  ]

  metadata_options {
    http_endpoint          = "enabled"
    http_tokens            = "required"
    instance_metadata_tags = "enabled"
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
    var.subnets["public-1a"].id,
    var.subnets["public-1b"].id
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
  arn       = var.eip_assigner_lambbda.arn
}

resource "aws_lambda_permission" "eventbridge_invoke_permission" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.eip_assigner_lambbda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.asg_eip_assignment.arn
}