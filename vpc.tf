# VPC resource
# * VPC
# * Subnets
# * Route Table 

data "aws_availability_zones" "available_zones" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block = "var.myvpc"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(aws.vpc.main.cidr_block, 8, 2 + count.index)
  count      = 2
  availability_zone = data.aws_availability_zones.available_zones.name[count.index]


  tags = {
    Name = "publicsubnet"
  }
}resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(aws.vpc.main.cidr_block, 8, 2 + count.index)
  count      = 2
  availability_zone = data.aws_availability_zones.available_zones.name[count.index]

  tags = {
    Name = "privatesubnet"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}


resource "aws_route" "internet_access" {

    route_table_id  = aws_vpc.main.main_route_table_id
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
}

resource "aws_eip" "gateway" {
    count  = 2
  vpc      = true 
  depends_on = [aws_internet_gateway.igw]
}


resource "aws_nat_gateway" "gate" "gateway"{
count    = 2
subnet_id  = element(aws_subnet.public.*.id, counnt.index)
allocation_id = element(aws_eip.gateway.*.id, count.index)
}


resource "aws_route_table" "private" {
    count  = 2
  vpc_id    = aws_vpc.main.id

route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gateway.*.id, count.index)
}
}
resource "aws_route_table_association" "private" {
count    = 2
subnet_id  = element(aws_subnet.public.*.id, counnt.index)
route_table_id = element(aws_route_table.private.*.id, count.index)
}



resource "aws_security_group" "lb" {
  name        = "lb"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.main.cidr_block]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_ib" "name" {
    name        =  "lb"
    subnets     = aws_subnet.public.*.vpc_id
    aws_security_group = [aws_security_group.lb.id]
  
}

resource "aws_lb_target_group" "hello_world" {
name     = "eaxample-target-group"
port      = 80
protocol  = "HTTP"
vpc_id =  aws_vpc.main.id
target_type = "ip"

  
} 
resource "aws_lb_listener" "hellow_world" {
    load_balancer_arn = aws_lb.main.id 
    port              = "80"
    protocol          = "HTTP"


default_action {
  target_group_arn = aws_lb_target_group.hellow_world.id
  type             = "forward"
}


}
