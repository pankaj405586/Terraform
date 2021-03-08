#################################################
## Private Subnets: 3                          ##
## Public Subnet: 3                            ##
## Internet Gateway: 1                         ##
## EIP : 1                                     ##
## Nat Gateway: 1                              ##
## Route Tables: 2                             ##
## Routes for NG & IG                          ##
## Subnet and Route Table Association          ##
## VPC endpoint: 1                             ##
## VPC endpoint and Rote Table Association     ##
#################################################


data "aws_availability_zones" "azs"{}


## Creating VPC ##


resource "aws_vpc" "main" {
  cidr_block           = "${var.vpc_cidr_first_two}.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "${var.env}-${var.pod}-vpc"
    env  = var.env
    pod  = var.pod
  }
}



## Creating EIP  ##

resource "aws_eip" "eip" {
  vpc = true
  public_ipv4_pool = "amazon"

  tags = {
    Name = "${var.env}-${var.pod}-eip"
    env  = var.env
    pod  = var.pod
  }

}


## Creating NAT Gateway  ##

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_subnet[0].id


  tags = {
    Name = "${var.env}-${var.pod}-ngw"
    env  = var.env
    pod  = var.pod
  }
 depends_on     = [aws_internet_gateway.igw, aws_subnet.public_subnet]
}


###########################################
## Gateway VPC Endpoint                  ##
###########################################

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"

  tags = {
    Name = "${var.env}-${var.pod}-vpc-endpoint-s3"
    env  = var.env
    pod  = var.pod
  }
}




###########################################
## private Subnets, Route table & Routes ##
###########################################

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-${var.pod}-private-rt"
    env  = var.env
    pod  = var.pod
  }
}

## Adding Nat gateway to the route ##

resource "aws_route" "nat-gw" {
  route_table_id         = aws_route_table.private_rt.id
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
  destination_cidr_block = "0.0.0.0/0"
  depends_on = [aws_route_table.private_rt, aws_nat_gateway.nat_gw]

}




######################
## private Subnets  ##
######################

resource "aws_subnet" "private_subnet" {
  count = length(data.aws_availability_zones.azs.names)
  availability_zone = element(data.aws_availability_zones.azs.names,count.index )
  vpc_id            = aws_vpc.main.id
  cidr_block        = "${var.vpc_cidr_first_two}.${element(var.private_subnet_cidr,count.index )}"

  tags = {
    Name = "${var.env}-${var.pod}-private-${count.index+1}"
    env  = var.env
    pod  = var.pod

  }
}


resource "aws_route_table_association" "private_subnet_to_route" {
  count          = length(aws_subnet.private_subnet)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt.id
  depends_on     = [aws_subnet.private_subnet, aws_route_table.private_rt]
}



################################################################################################################
################################################################################################################




################################################
## Public Subnets, IG, Route table & Routes ##
################################################

## Creating Internet Gateway  ##

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-${var.pod}-igw"
    env  = var.env
    pod  = var.pod
  }
}


## Creating route table ##

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-${var.pod}-public-rt"
    env  = var.env
    pod  = var.pod
  }
}


## Adding Internet gateway to the route ##

resource "aws_route" "internet_igw" {
  route_table_id         = aws_route_table.public_rt.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
  depends_on = [aws_route_table.public_rt,aws_internet_gateway.igw ]
}



######################
## Public Subnets ##
######################


resource "aws_subnet" "public_subnet" {
  count = length(data.aws_availability_zones.azs.names)
  availability_zone = element(data.aws_availability_zones.azs.names,count.index )
  vpc_id            = aws_vpc.main.id
  cidr_block        = "${var.vpc_cidr_first_two}.${element(var.public_subnet_cidr,count.index )}"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env}-${var.pod}-public-${count.index+1}"
    env  = var.env
    pod  = var.pod
  }
  depends_on = [aws_vpc.main]
}

resource "aws_route_table_association" "public_subnet_to_route" {
  count = length(aws_subnet.public_subnet)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
  depends_on = [aws_subnet.public_subnet, aws_route_table.public_rt]
}


resource "aws_vpc_endpoint_route_table_association" "private" {
  route_table_id  = aws_route_table.private_rt.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  depends_on = [aws_route_table.private_rt, aws_vpc_endpoint.s3]
}


resource "aws_vpc_endpoint_route_table_association" "public" {
  route_table_id  = aws_route_table.public_rt.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  depends_on = [aws_route_table.public_rt, aws_vpc_endpoint.s3]
}


####### Security Groups ######


resource "aws_security_group" "prod_ec2_sg" {
  vpc_id                 = aws_vpc.main.id

  ingress {
    description          = "open all ports internally"
    from_port            = 0
    to_port              = 65535
    protocol             = "tcp"
    cidr_blocks          = ["${var.vpc_cidr_first_two}.0.0/16"]
  }


  egress {
    from_port            = 0
    to_port              = 0
    protocol             = "-1"
    cidr_blocks          = ["0.0.0.0/0"]
  }

  tags = {
    Name                 = "${var.env}-${var.pod}-ec2-sg"
    env                  = var.env
    tool                 = "terraform"
    pod                  = var.pod
  }
  depends_on             = [aws_vpc.main]
}




resource "aws_security_group" "public_sg" {
  name                   = "ec2-public-sg"
  vpc_id                 = aws_vpc.main.id
  egress {
    from_port            = 0
    to_port              = 0
    protocol             = "-1"
    cidr_blocks          = ["0.0.0.0/0"]
  }
  tags = {
    Name                 = "${var.env}-${var.pod}-ec2-sg"
    env                  = var.env
    tool                 = "terraform"
    pod                  = var.pod
  }
  depends_on             = [aws_vpc.main]
}


resource "aws_security_group_rule" "public_ingress_rules" {
  count = length(var.ingress_rules)

  type              = "ingress"
  from_port         = var.ingress_rules[count.index].from_port
  to_port           = var.ingress_rules[count.index].to_port
  protocol          = var.ingress_rules[count.index].protocol
  cidr_blocks       = [var.ingress_rules[count.index].cidr_block]
  description       = var.ingress_rules[count.index].description
  security_group_id = aws_security_group.public_sg.id
}
