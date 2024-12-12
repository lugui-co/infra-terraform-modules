resource "aws_vpc_endpoint" "s3_endpoint" {
     vpc_id       = aws_vpc.main_vpc.id
    service_name = "com.amazonaws.${var.region}.s3"

    tags = merge(
        {
            Name        = "s3_endpoint"
        },
        var.tags
    )
}

resource "aws_vpc_endpoint_route_table_association" "db_s3_endpoint_association" {
    count = length(aws_route_table.db)
    route_table_id  = aws_route_table.db[count.index].id  
    vpc_endpoint_id = aws_vpc_endpoint.s3_endpoint.id
}

resource "aws_vpc_endpoint_route_table_association" "app_s3_endpoint_association" {
    count = length(aws_route_table.app)
    route_table_id  = aws_route_table.app[count.index].id
    vpc_endpoint_id = aws_vpc_endpoint.s3_endpoint.id
}