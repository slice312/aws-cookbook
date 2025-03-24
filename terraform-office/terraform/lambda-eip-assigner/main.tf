locals {
  lambda_path     = "lambda-eip-assigner"
  lambda_zip_path = "../${local.lambda_path}/.aws-sam/build/eip-assigner.zip"
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
        Effect   = "Allow",
        Action   = "ec2:AssociateAddress",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_role_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_exec_policy.arn
}

resource "aws_lambda_function" "eip_assigner" {
  function_name = "eip-assigner"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.13"
  architectures = ["arm64"]

  filename         = local.lambda_zip_path
  source_code_hash = filesha256(local.lambda_zip_path)

  timeout     = 30
  memory_size = 128
  publish     = true

  environment {
    variables = {
      ELASTIC_IP_ALLOCATION_ID = var.bastion_eip_allocation_id
    }
  }
}
