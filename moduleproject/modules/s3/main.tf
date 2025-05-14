resource "aws_s3_bucket" "mybucket" {
bucket = var.bkt_name
}

resource "aws_s3_bucket_acl" "mybucket" {
bucket = aws_s3_bucket.mybucket.id
acl = var.acl
}