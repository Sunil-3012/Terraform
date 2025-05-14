variable "bkt_name" {
type = string
description = "S3 Bucket Name"
}

variable "acl" {
type = string
description = "s3 acl"
default = "private"
}