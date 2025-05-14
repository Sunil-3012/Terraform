provider "aws" {
region = "us-east-1"
}

module "vpc" {
source = "./modules/vpc"
cidr_block = "192.168.0.0/16"
vpc_name = "my-vpc"
}

module "ec2-instances" {
source = "./modules/ec2-instances"
ami = "ami-085386e29e44dacd7"
instance_type = "t2.micro"
name = "sample-server"
subnet_id = module.vpc.vpc_id
}

module "s3" {
source = "./modules/s3"
bkt_name = "sunil-bucket"
acl = "private"
}
