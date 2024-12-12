output "vpc_id" {
    value = aws_vpc.main_vpc.id
}

output "db_subnets_cidr" {
    value = var.db_subnets.cidr_base
}

output "db_subnets_cidr_list" {
    value = var.db_subnets.subnet.*.cidr_block
}

output "db_subnets_id" {
    value = aws_subnet.db.*.id
}

output "app_subnets_cidr_list" {
    value = var.app_subnets.subnet.*.cidr_block
}

output "app_subnets_cidr" {
    value = var.app_subnets.cidr_base
}

output "app_subnets_id" {
    value = aws_subnet.app.*.id
}

output "dmz_subnets_cidr_list" {
    value = var.dmz_subnets.subnet.*.cidr_block
}

output "dmz_subnets_cidr" {
    value = var.dmz_subnets.cidr_base
}

output "dmz_subnets_id" {
    value = aws_subnet.dmz.*.id
}

output "dmz_route_tables" {
    value = aws_route_table.dmz.*.id
}

output "route_tables" {
    value = setunion(aws_route_table.dmz.*.id,aws_route_table.app.*.id,aws_route_table.db.*.id)
}

output "route_tables_to_trasitgateway" {
    value = setunion(aws_route_table.app.*.id,aws_route_table.db.*.id)
}

