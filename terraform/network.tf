
# Data source to fetch the Default VPC
data "aws_vpc" "default" {
  default = true
}

data "aws_availability_zones" "available" {}

# Neues VPC
resource "aws_vpc" "custom_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "custom-vpc"
  }
}

# Öffentliches Subnetz
resource "aws_subnet" "public_subnet_container" {
  vpc_id = aws_vpc.custom_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "public-subnet-container"
  }
}

# Privates Subnetz
resource "aws_subnet" "private_subnet_rds" {
  vpc_id = aws_vpc.custom_vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = false
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "private-subnet-rds"
  }
}
