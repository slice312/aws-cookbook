output "function_name" {
  value       = aws_lambda_function.eip_assigner.function_name
  description = "Name of the EIP Assigner Lambda function"
}

output "arn" {
  value       = aws_lambda_function.eip_assigner.arn
  description = "ARN of the EIP Assigner Lambda function"
}