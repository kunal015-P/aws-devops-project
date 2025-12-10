variable "project" {}
variable "vpc_cidr" {}
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }

# VPC
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags       = { Name = "${var.project}-vpc" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.project}-igw" }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "${var.project}-public-rt" }
}

# Availability Zones
data "aws_availability_zones" "available" {}

# Public Subnets
resource "aws_subnet" "public" {
  for_each = { for idx, cidr in var.public_subnets : idx => cidr }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = data.aws_availability_zones.available.names[each.key]
  map_public_ip_on_launch = true
  tags               = { Name = "${var.project}-public-${each.key}" }
}

# Associate public subnets with route table
resource "aws_route_table_association" "public" {
  for_each      = aws_subnet.public
  subnet_id     = each.value.id
  route_table_id = aws_route_table.public.id
}

# Private Subnets
resource "aws_subnet" "private" {
  for_each = { for idx, cidr in var.private_subnets : idx => cidr }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = data.aws_availability_zones.available.names[each.key]
  tags               = { Name = "${var.project}-private-${each.key}" }
}

# Outputs
output "vpc_id" { value = aws_vpc.this.id }
output "public_subnets" { value = [for s in aws_subnet.public : s.id] }
output "private_subnets" { value = [for s in aws_subnet.private : s.id] }
