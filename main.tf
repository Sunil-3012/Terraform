
# Creating a VPC
resource "aws_vpc" "MyVpc" {
  cidr_block = var.cidr
}

# Creating 2 public subnets
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.MyVpc.id
  cidr_block              = "192.168.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.MyVpc.id
  cidr_block              = "192.168.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

Creating internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.MyVpc.id
}

# Creating Public route table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.MyVpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Creating 2 route table association for each of the subnet
resource "aws_route_table_association" "rta1" {
  route_table_id = aws_route_table.rt.id
  subnet_id      = aws_subnet.subnet1.id
}

resource "aws_route_table_association" "rta2" {
  route_table_id = aws_route_table.rt.id
  subnet_id      = aws_subnet.subnet2.id
}

# creating security groups and allowing http port
resource "aws_security_group" "websg" {
  name   = "web"
  vpc_id = aws_vpc.MyVpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "web-sg"
  }
}

creating 2 instances for each of the subnet
resource "aws_instance" "web-server1" {
  ami                    = var.aws_ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.websg.id]
  subnet_id              = aws_subnet.subnet1.id
  user_data              = file("userdata.sh")
}

resource "aws_instance" "web-server2" {
  ami                    = var.aws_ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.websg.id]
  subnet_id              = aws_subnet.subnet2.id
  user_data              = file("userdata1.sh")
}

# Creating a load balancer
resource "aws_lb" "MyLb" {
  name               = "MyAlb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.websg.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  tags = {
    name = "web"
  }
}

# creating the target group
resource "aws_lb_target_group" "tg" {
  name     = "myTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.MyVpc.id
  health_check {
    path = "/"
    port = "traffic-port"
  }
}

# creating attachments for the target groups
resource "aws_lb_target_group_attachment" "attachment1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web-server1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attachment2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web-server2.id
  port             = 80
}

# adding listener
resource "aws_lb_listener" "mylistener" {
  load_balancer_arn = aws_lb.MyLb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}
