variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "subnets" {
  description = "Office subnets"
  type = map(object({
    id                      = string
    cidr_block              = string
    availability_zone_id    = string
    map_public_ip_on_launch = bool
  }))

}

variable "eip_assigner_lambbda" {
  description = "EIP Assigner Lambda details"
  type = object({
    function_name = string
    arn           = string
  })
}