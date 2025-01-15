locals {
  subnets = {
    "public-1a" = {
      cidr_block              = "10.0.10.0/24"
      availability_zone_id    = "eun1-az1"
      map_public_ip_on_launch = true
      name                    = "office-public-1a"
    }
    "private-1a" = {
      cidr_block              = "10.0.11.0/24"
      availability_zone_id    = "eun1-az1"
      map_public_ip_on_launch = false
      name                    = "office-private-1a"
    }
    "database-1a" = {
      cidr_block              = "10.0.12.0/24"
      availability_zone_id    = "eun1-az1"
      map_public_ip_on_launch = false
      name                    = "office-database-1a"
    }
    "public-1b" = {
      cidr_block              = "10.0.20.0/24"
      availability_zone_id    = "eun1-az2"
      map_public_ip_on_launch = true
      name                    = "office-public-1b"
    }
    "private-1b" = {
      cidr_block              = "10.0.21.0/24"
      availability_zone_id    = "eun1-az2"
      map_public_ip_on_launch = false
      name                    = "office-private-1b"
    }
    "database-1b" = {
      cidr_block              = "10.0.22.0/24"
      availability_zone_id    = "eun1-az2"
      map_public_ip_on_launch = false
      name                    = "office-database-1b"
    }
  }
}

resource "aws_subnet" "office_subnets" {
  for_each                = local.subnets
  vpc_id                  = aws_vpc.office-vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone_id    = each.value.availability_zone_id
  map_public_ip_on_launch = each.value.map_public_ip_on_launch

  tags = {
    Name = each.value.name
  }
}