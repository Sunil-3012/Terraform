# Terraform

### Initialize infrastructure 

`terraform init` Initialize a working directory, it will download the providers plugins

`terraform plan` Creates an execution plan (dry run)

`terraform apply` Executes changes to the actual environment

`terraform apply –auto-approve` Apply changes without being prompted to enter ”yes”

`terraform destroy –auto-approve` Destroy/cleanup without being prompted to enter ”yes”

## Launching EC2 Instance

`vi.main.tf`

**Launching 1 Instance**
```
provider "aws" {

  region = "us-east-1"

}

resource "aws_instance" "instance-1" {
ami = "ami-085386e29e44dacd7"
instance_type = "t2.micro"
}
```
**Launching Multiple instances**
```
provider "aws" {

  region = "us-east-1"

}

resource "aws_instance" "instance-1" {
count = 4
ami = "ami-085386e29e44dacd7"
instance_type = "t2.micro"
}
```

To see the info about the instance `terraform state list`
