resource "aws_vpc" "myvpc" {
cidr_block = var.cidr_block

tags = {
name = var.vpc_name
}
}