resource "aws_route_table" "app" {
  count = length(var.app_subnets.subnet)
  vpc_id = aws_vpc.main_vpc.id
 
  tags = merge(
    {
      Name        = "app"
    },
    var.tags
  )
}

resource "aws_route_table" "db" {
  count = length(var.db_subnets.subnet)
  vpc_id = aws_vpc.main_vpc.id
  
  tags = merge(
    {
      Name        = "db"
    },
    var.tags
  )
}

resource "aws_route_table" "dmz" {
  count = length(var.dmz_subnets.subnet)
  vpc_id = aws_vpc.main_vpc.id

  tags = merge(
    {
      Name        = "dmz"
    },
    var.tags
  )
}

resource "aws_route_table_association" "app" {
  count = length(var.app_subnets.subnet)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app[count.index].id  
}

resource "aws_route_table_association" "db" {
  count = length(var.db_subnets.subnet)
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db[count.index].id
}

resource "aws_route_table_association" "dmz" {
  count = length(var.dmz_subnets.subnet)
  subnet_id      = aws_subnet.dmz[count.index].id
  route_table_id = aws_route_table.dmz[count.index].id
}

resource "aws_route" "rout_to_igw" {
  count = length(aws_route_table.dmz.*.id)
  route_table_id            = aws_route_table.dmz[count.index].id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}
