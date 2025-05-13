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
## Meta arguments

In Terraform, meta-arguments are special arguments that you can use with resources, modules, and other blocks to control how they behave.

### Depends_on

The depends_on meta-argument explicitly defines dependencies between resources. This ensures that one resource is created or updated only after another resource has been successfully created or updated.

```
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "myinstance" {
  ami           = "ami-085386e29e44dacd7"
  instance_type = "t2.micro"
tags = {
    Name = "Depends-on-EC2"
  }
}

resource "aws_eip" "myinstance_eip" {
  instance   = aws_instance.myinstance.id
  depends_on = [aws_instance.myinstance]
}

output "elastic_ip" {
  description = "Elastic IP of the instance"
  value       = aws_eip.myinstance_eip.public_ip
}
```


### Count

The "count" meta-argument allows you to specify the number of instances of a resource or module to create.

In the below code, the instances names are assigned based on the number of instances count we give
```
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "myinstance" {
  count         = 2
  ami           = "ami-085386e29e44dacd7"
  instance_type = "t2.micro"
  tags = {
    name = "webserver-$-{count.index}"
  }
}

output "instance_ids" {
  value = aws_instance.myinstance[*].id
}

output "instance_names" {
  value = aws_instance.myinstance[*].tags.name
}
```

another better way to do it

```
provider "aws" {
  region = "us-east-1"
}

variable "instance_type" {
  default = ["t2.micro", "t2.small", "t2.medium"]
}

variable "instance_name" {
  default = ["dev-server", "test-server", "prod-server"]
}

resource "aws_instance" "myinstance" {
  ami           = "ami-085386e29e44dacd7"
  count         = length(var.instance_type)
  instance_type = var.instance_type[count.index]
  tags = {
    name = var.instance_name[count.index]
  }
}

output "instance_id" {
  value = aws_instance.myinstance[*].id
}
```

### for_each

The "for_each" meta-argument allows you to create multiple instances of a resource or module based on the elements of a set. It provides more control and flexibility than "count"

count vs for_each : count will create identical resources, for_each will create different resources

```
provider "aws" {
  region = "us-east-1"
}
resource "aws_instance" "myinstance" {
  ami           = "ami-085386e29e44dacd7"
  for_each      = toset(["dev-server", "test-server", "prod-server"])
  instance_type = "t2.micro"
  tags = {
    name = "$-{each.key}"
  }
}

output "instance_id" {
  value = { for k, v in aws_instance.myinstance : k => v.id }
}
```
* toset() is a function to create multiple EC2 instances from a list of names

* Terraform will generate a map of instances with keys in this case as "dev-server", "test-server", and "prod-server".

*The "for" expression iterates over aws_instance.myinstance

*k represents the instance key (dev-server, test-server, etc.)

*v.id retrieves the instance ID

*The result is a map of key => instance_id

*In for_each , we can play with key and value like .key and .value


another example 

```
provider "aws" {
  region = "us-east-1"
}
variable "instances" {
  type = map(string)
  default = {
    "dev-server"  = "t2.micro"
    "test-server" = "t2.medium"
    "prod-server" = "t2.large"
  }
}

resource "aws_instance" "myinstance" {

  for_each      = var.instances
  ami           = "ami-085386e29e44dacd7"
  instance_type = each.value
  tags = {
    name = "each.key"
  }
}

output "instances_id" {
  value = { for k, v in aws_instance.myinstance : k => v.id }
}
```

                  

### Lifecycle

The lifecycle meta-argument allows you to control the lifecycle of a resource. It provides options to prevent the destruction of resources, create resources before destroying existing ones, or ignore changes to specific attributes.

                  -- create_before_destroy
                  -- prevent_destroy
                  -- ignore_changes

**Ignore changes**

If anyone modified the resources in AWS console which is created by TF, It will ignore that changes, it will not bring back to desired state. Actual State is AWS Console, Desired State is Statefile

```
resource "aws_instance" "myinstance" {
  ami           = "ami-085386e29e44dacd7"
  instance_type = "t2.micro"
  tags = {
    Name = "example-server"
  }
  lifecycle {
    ignore_changes = all
  }
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.myinstance.id
}
```

**Prevent-destroy**

resources will not delete if you give destroy command
```
provider "aws" {
region = "us-east-1"
}

resource "aws_instance" "one" {
ami = "ami-085386e29e44dacd7"
instance_type = "t2.micro"
tags = {
Name = "example-server"
}
lifecycle{
prevent_destroy = true
}
}
```

**Create-before-destroy**

If you change the instance type or instance name , security groups etc , It will change immediatelyand instance will not get deleted.  but if you want to change the image id of the EC2 instance , instance will delete first and then create a new instance with new ami-id
```
provider "aws" {
region = "us-east-1"
}

resource "aws_instance" "one" {
ami = "ami-085386e29e44dacd7"
instance_type = "t2.micro"
tags = {
Name = "example-server"
}
lifecycle{
create_before_destroy = true
}
}
```

