variable "ami" {
type = string
description = "AMI Instance"
}

variable "instance_type" {
type = string
description = "Type of Instance to be used"
}

variable "name" {
type = string
description = "Instance_name"
}

variable "subnet_id" {
type = string 
description = "subnet id present in VPC for EC2 Instance"
}
