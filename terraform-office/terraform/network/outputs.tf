output "bastion_eip" {
  value = aws_eip.bastion_instance_eip
}

output "vpc_id" {
  value = aws_vpc.office-vpc.id
}

output "subnets" {
  value = aws_subnet.office_subnets
}