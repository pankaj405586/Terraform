provider "aws" {
  region                  = "ap-southeast-1"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "default"
}

//module "vpc" {
//	source = "../modules/vpc"
//	env = "prod"
//    pod = "last9"
//	region = "ap-southeast-1"
//    vpc_cidr_first_two = "10.20"
//}

//module "public_ec2" {
//	source = "../modules/ec2"
//	env = "prod"
//    pod = "last9"
//    name = "external-ec2"
//    sg_id = ["sg-087b799fe3ccc6c1b"]
//    subnet_id = "subnet-00034807831ad4f12"
//}
//
//module "internal_ec2" {
//	source = "../modules/ec2"
//	env = "prod"
//    pod = "last9"
//    name = "internal-ec2"
//    sg_id = ["sg-0b7d199dace1bf664"]
//    subnet_id = "subnet-02d73ec72bf9fae92"
//}