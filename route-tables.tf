resource "aws_route_table" "rt-office-default" {
  vpc_id = aws_vpc.office-vpc.id

  route {
    cidr_block = aws_vpc.office-vpc.cidr_block
    gateway_id = "local"
  }

  tags = {
    Name = "rt-office-default"
  }
}

# Public subnet route tables
resource "aws_route_table" "rt-office-public" {
  vpc_id = aws_vpc.office-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-office-main.id
  }

  tags = {
    Name = "rt-office-public"
  }
}

resource "aws_route_table_association" "office-public-1a-assoc" {
  route_table_id = aws_route_table.rt-office-public.id
  subnet_id      = aws_subnet.office_subnets["public-1a"].id
}

resource "aws_route_table_association" "office-public-1b-assoc" {
  route_table_id = aws_route_table.rt-office-public.id
  subnet_id      = aws_subnet.office_subnets["public-1b"].id
}


# Private subnet route tables
resource "aws_route_table" "rt-office-private-1a" {
  vpc_id = aws_vpc.office-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw-office-1a.id
  }

  tags = {
    Name = "rt-office-private-1a"
  }
}

resource "aws_route_table_association" "office-private-1a-assoc" {
  route_table_id = aws_route_table.rt-office-private-1a.id
  subnet_id      = aws_subnet.office_subnets["private-1a"].id
}


resource "aws_route_table" "rt-office-private-1b" {
  vpc_id = aws_vpc.office-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw-office-1b.id
  }

  tags = {
    Name = "rt-office-private-1b"
  }
}

resource "aws_route_table_association" "office-private-1b-assoc" {
  route_table_id = aws_route_table.rt-office-private-1b.id
  subnet_id      = aws_subnet.office_subnets["private-1b"].id
}


# Database subnet route tables
resource "aws_route_table" "rt-office-database" {
  vpc_id = aws_vpc.office-vpc.id


  tags = {
    Name = "rt-office-database"
  }
}

resource "aws_route_table_association" "office-database-1a-assoc" {
  route_table_id = aws_route_table.rt-office-database.id
  subnet_id      = aws_subnet.office_subnets["database-1a"].id
}

resource "aws_route_table_association" "office-database-1b-assoc" {
  route_table_id = aws_route_table.rt-office-database.id
  subnet_id      = aws_subnet.office_subnets["database-1b"].id
}