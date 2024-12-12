resource "aws_eip" "nat" {
  count = length(var.dmz_subnets.subnet)
  domain = "vpc"

  tags = merge(
    {
      Name = "app"
    },
    var.tags
  )
}

resource "aws_nat_gateway" "nat" {
  count = length(var.dmz_subnets.subnet)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.dmz[count.index].id

  tags = merge(
    {
      Name = "app"
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.igw]
}