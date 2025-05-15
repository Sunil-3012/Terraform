<div align="center">
  <h1>Terraform</h1>
</div>

*topics*

* Terraform basic commands and Intializing infrastructure
* Launching EC2 Instance
* Taint
* Terraform Locals
* Dynamic Local Variables
* Terraform Workspaces
* Creating VPC
* META Arguments(Depend_on, Count, For_each, Lifecycle)
* Launchin Docker Containers
* Terraform Modules
* Provisioner(local-exec, remote-exec, file)
* Data-Source
* Terraformer
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

## Taint

Terraform taint command is used to manually mark a specific resource for recreation. When you mark a resource as "tainted," it indicates to Terraform that the resource is in a bad or inconsistent state and should be destroyed and recreated during the next terraform apply operation.

When to Use : Failed Deployments, Manual Changes and Resource Corruption

```
provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "myinstance" {
  ami           = "ami-0492447090ced6eb5"
  instance_type = "t2.micro"
  tags = {
    Name = "taint-server-example"
  }
}

resource "aws_s3_bucket" "mys3bucket" {
  bucket = "test-bkt-dkkfg-reya"
}
```

`terraform apply --auto-approve`

`terraform state list`   This will show you the resources handles by statefile

`terraform taint aws_s3_bucket.mys3bucket`

`terraform apply --auto-approve`    This will now delete only S3 bucket and recreate it not EC2 as S3 bucket has marked as tainted

**TO UNTAINT** `terraform untaint aws_instance.myinstance`

## TERRAFORM LOCALS

In Terraform, locals are used to define and assign values to variables that are meant to be used within a module or a configuration block.

Unlike input variables, which allow values to be passed in from the outside, local values are set within the configuration itself and are used to simplify complex expressions, avoid repetition, and improve the readability of your Terraform code.

```
locals {
  project_name   = "sample-project"
  environment    = "sunil"
  instance_count = 2
  tags = {
    Name        = "${local.project_name}-${local.environment}"
    Environment = local.environment
  }
}
resource "aws_instance" "myinstance" {
  ami           = "ami-0492447090ced6eb5"
  instance_type = "t2.micro"
  count         = local.instance_count
  tags          = local.tags
}
```
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

## Launching Docker containers

launching a sample container with image

```
terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "3.5.0"
    }
  }
}

provider "docker" {
host = "unix:///var/run/docker.sock"   # for linux/macOS
}

resource "docker_image" "bank" {
name = "sunil3012/mb-image:latest"    # Image name
keep_locally = false
}

resource "docker_container" "bankcont" {
name = "bank-conatainer"
image = docker_image.bank.image_id
ports {
internal = 80
external = 7543    # external port number
}
}
```

to run `terraform init` --> `terrafom plan` --> `terraform apply --auto-approve` and to destroy --> `terraform destroy --auto-approve`

## TERRAFORM MODULES

Terraform modules are a fundamental feature that helps in organizing and reusing Terraform configurations.A module is a container for multiple resources that are used together.Modules allow you to encapsulate and manage resources as a single unit, making your Terraform configurations more modular, readable, and maintainable.

There are 2 type of Modules

**Root Module** : The root module is the main configuration where Terraform starts its execution.It is usually defined in the main configuration directory where terraform init and terraform apply are run.The root module can call other modules, referred to as child modules.

**Child Module** : Child modules are modules that are called from within other modules (including the root module).They help in organizing resources and reusing configurations.Each child module can be stored in a separate directory and can be called using a module block in the root module or another parent module.

`**You can refer a sameple module which is present in the files section on top of this page by the name of MODULEPROJECT**`

## Provisioners

Terraform provisioners are used to perform actions on a local or remote machine after a resource is created or updated. They are typically used for tasks such as configuring or installing software on a machine, which Terraform itself does not handle directly.

**local-exec:** Executes a command locally on the machine where Terraform is run. Useful for running scripts or commands that need to be executed locally. The "local-exec" provisioner runs commands on the local machine where Terraform is executed

the below code will launch an instance and print the instance id in .txt file which is stored locally
```
provider "aws" {
region = "us-east-1"
}

resource "aws_instance" "myinstance" {
ami = ""
instance_type = "t2.micro"
provisioner "local-exec" {
command = "echo'instance ID: $-{self.id}' > instance.id.txt"
}
}
```

**Remote-Exec:** The remote-exec provisioner runs commands on a remote resource. It typically requires a connection configuration.


In the below, i am using remote exec where I would be launching an ec2 instance and connecting via ssh and installing apache server.

tip: Copy the private key content into `~/.ssh/id_rsa.pub`
```
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "myinstance" {
  ami           = "ami-085386e29e44dacd7"
  instance_type = "t2.micro"
  key_name      = "firstkey"
  tags = {
    name = "sample-instance"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install httpd -y",
      "sudo systemctl start httpd"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa.pub")
      host        = self.public_ip
    }

  }

}
```

**File Provisioner:** The file provisioner uploads files from the local machine to the remote resource. Uploads files from the local machine to a remote resource. Useful for transferring configuration files or scripts to a remote machine.

In this code, terraform will take the command form a file and execute it in the machine 

Create a sample .sh file 
```
#!/bin/bash

echo "Running remote script"

sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd

echo "<html><h1>Hey, this a sample infra created by Sunil with the help of terraform</h1></html>" | sudo tee /var/www/html/index.html > /dev/null
```

then `vi.main.tf`

```
provisioner "file" {
  source      = "remote_script.sh"
  destination = "/tmp/remote_script.sh"

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/firstkey.pem")
    host        = self.public_ip
  }
}

provisioner "remote-exec" {
  inline = [
    "chmod +x /tmp/remote_script.sh",
    "/tmp/remote_script.sh"
  ]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/firstkey.pem")
    host        = self.public_ip
  }
}
```

## DATA-Source

In Terraform, a data source allows you to fetch information from existing resources or services that are external to your Terraform configuration. Fetching Information About Existing Resources. If you need to retrieve information about an existing resource that wasn't created by your Terraform configuration (e.g., an existing AWS VPC or EC2 AMI).

For example, if you want to make changes in the alreday created resorces in this case VPC, and want to add a ec2 instance
```
provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "example" {
  ami           = "ami-08ee1453725d19cdb"
  instance_type = "t2.micro"
  subnet_id     = data.aws_vpc.default.id
}


data "aws_s3_bucket" "sunil_bucket" {
  bucket = "sample_bucket"
}

output "bucket_arn" {
  value = data.aws_s3_bucket.sunil_bucket.arn
}
```

## TERRAFORMER

Terraformer is used for importing the existing resources in one shot. 

for eample you can import all the resorces in a already existing vpc with this command `terraformer import aws --resources=instance,vpc,subnet --regions=us-east-1`
