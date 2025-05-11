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

## Terraform Workspace

* A workspace is an isolated environment where a separate state file is maintained.

* This feature allows you to manage different environments (like development, staging, production) within the same Terraform configuration.

* Each workspace has its own state, enabling you to deploy the same infrastructure to multiple environments without needing to duplicate the configuration files.

* All workspace statefiles are under directory terraform.tfstate.d

`terraform workspace list` **to show list of workspace**

`terraform workspace new ` **to Create and switch to workspace "dev"**

`terraform workspace show` **to show current workspace**

`terraform workspace select` **to switch between workspaces**

`terraform workspace delete` **to delete the workspaces**

Example to create multiple workspaces and multiple EC2 Instances and assigning those workspaces to respective instances based on the requirement with Local variable

```
provider "aws" {
  region = "us-east-1"
}

locals {
  instance_types = {
    dev  = "t2.micro"
    test = "t2.small"
    prod = "t2.medium"
  }
}

resource "aws_instance" "myinstance" {
  ami           = "ami-085386e29e44dacd7"
  instance_type = local.instance_types[terraform.workspace]
  tags = {
    name = "$(terraform.workspace)-server"
  }
}

output "active_workspace" {
  value = terraform.workspace
}
```

## Creating a VPC(with one subnet and one instance)

```
provider "aws" {
  region = "us-east-1"
}

locals {
  env = terraform.workspace
}

resource "aws_vpc" "MyVpc" {
  cidr_block = "192.168.0.0/16"
  tags = {
    name = "$(local.env)-vpc"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.MyVpc.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    name = "$(local.env)-subnet"
  }
}

resource "aws_instance" "MyInstance" {
  subnet_id     = aws_subnet.subnet.id
  ami           = "ami-085386e29e44dacd7"
  instance_type = "t2.micro"
  tags = {
    name = "$(local.env)-instance"
  }
}
```
## Dynamic Local Variable

it is the concept of **If else** where code has a variable terraform.workspace which is taking the value dynamicly from which workspace we are using, in this case we are using default workspace, that default workspace will be passed to instace_type = default, if prod m4.large will launch, if not t2.small
```
provider "aws" {
  region = "us-east-1"

}

resource "aws_instance" "myinstance" {
  ami           = "ami-085386e29e44dacd7"
  instance_type = terraform.workspace == "prod" ? "m4.large" : "t2.small"
  tags = {
    name = "dyanimic-local-variable-$(terraform.workspace)"
  }
}

output "active_workspace" {
  description = "current worspace"
  value       = aws_instance.myinstance.instance_type
}
```

