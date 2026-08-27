resource "aws_vpc" "environment_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "image-recognition-${var.environment}-vpc"
    Environment = var.environment
    Component   = "network"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.environment_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "image-recognition-${var.environment}-public-${count.index + 1}"
    Environment = var.environment
    Component   = "network"
  }
}

resource "aws_internet_gateway" "environment_igw" {
  vpc_id = aws_vpc.environment_vpc.id

  tags = {
    Name        = "image-recognition-${var.environment}-igw"
    Environment = var.environment
    Component   = "network"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.environment_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.environment_igw.id
  }

  tags = {
    Name        = "image-recognition-${var.environment}-public-rt"
    Environment = var.environment
    Component   = "network"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}