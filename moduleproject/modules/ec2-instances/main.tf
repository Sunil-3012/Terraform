resource "aws_instance" "myinstance" {
ami = var.ami
instance_type = var.instance_type
tags = {
name = var.name
subnet_id = var.subnet_id
}
}

