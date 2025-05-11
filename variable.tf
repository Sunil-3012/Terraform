variable "cidr" {
  default = "192.168.0.0/16"
}

variable "aws_ami" {

  type    = string
  default = ""
}

variable "instance_type" {
  type    = string
  default = ""
}

variable "key_name" {
  type    = string
  default = ""
}
