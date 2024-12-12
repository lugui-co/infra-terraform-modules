
#
# VPC resources
#
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    {
      Name        = "main_vpc"
    },
    var.tags
  )
}

resource "aws_subnet" "app" {
  count = length(var.app_subnets.subnet)
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = lookup(element(var.app_subnets.subnet, count.index), "cidr_block")
  availability_zone       = join("",[var.region, lookup(element(var.app_subnets.subnet, count.index), "az")])     

  tags = merge(
    {
      Name        = "app_subnet"
    },
    var.tags
  )
}

resource "aws_subnet" "db" {
  count = length(var.db_subnets.subnet)
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = lookup(element(var.db_subnets.subnet, count.index), "cidr_block")
  availability_zone       = join("",[var.region, lookup(element(var.db_subnets.subnet, count.index), "az")])     

  tags = merge(
    {
      Name        = "db_subnet"
    },
    var.tags
  )
}

resource "aws_subnet" "dmz" {
  count = length(var.dmz_subnets.subnet)
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = lookup(element(var.dmz_subnets.subnet, count.index), "cidr_block")
  availability_zone       = join("",[var.region, lookup(element(var.dmz_subnets.subnet, count.index), "az")])        
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name        = "dmz_subnet"
    },
    var.tags
  )
}