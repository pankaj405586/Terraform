data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  associate_public_ip_address = var.associate_public_ip_address
  disable_api_termination = false
  key_name = var.key_name
  subnet_id = var.subnet_id
  vpc_security_group_ids = var.sg_id

  tags = {
    Name = var.name
    env  = var.env
    pod  = var.pod
  }
}

