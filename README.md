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

**To Launch EC2 instances via variable and arguments**
`vi main.tf`

```
provider "aws" {
  region = "us-east-1"
}
variable "instance_name" {
  description = "Name of the server"
  type        = string
  default     = "Tf_Server"
}

variable "instance_ami" {
  description = "type of AMI to be used"
  type        = string
  default     = "ami-085386e29e44dacd7"
}

variable "instance_type" {
  description = "type of instance to be used"
  type        = string
  default     = "t2.micro"
}

variable "instance_count" {
  description = "Number of instances to be launched"
  type        = number
  default     = 2
}


resource "aws_instance" "myinstance" {
  count         = var.instance_count
  instance_type = var.instance_type
  ami           = var.instance_ami
  tags = {
    name = var.instance_name
  }
}
```

 **OR you can sepearte the variable into different file**

 `vi main.tf`
 
```
provider "aws" {
  region = "us-east-1"
}


resource "aws_instance" "myinstance" {
  count         = var.instance_count
  instance_type = var.instance_type
  ami           = var.instance_ami
  tags = {
    name = var.instance_name
  }
}
```
`vi variable.tf` keeping the sepearte file for variables

```
variable "instance_name" {
  description = "Name of the server"
  type        = string
}

variable "instance_ami" {
  description = "type of AMI to be used"
  type        = string
}

variable "instance_type" {
  description = "type of instance to be used"
  type        = string
}

variable "instance_count" {
  description = "Number of instances to be launched"
  type        = number
}
```
`vi dev.tfvars` creating a file for values

```
instance_type = "t2.micro"
instance_count = 3
instance_name = "dev_server"
instance_ami = "ami-085386e29e44dacd7"
```
`Terraform apply --auto-approve -var-file="dev.tfvars"` 
