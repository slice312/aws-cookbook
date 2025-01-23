variable "bastion_eip_allocation_id" {
  description = "The allocation ID of the Elastic IP (EIP) that will be assigned to the Bastion EC2 instance by a Lambda function."
  type        = string
}