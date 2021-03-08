variable "env" {
	description = "env type ex: prod, qa, dev, stage"
    type = string
}

variable "pod" {
	description = "name of the team ex: frontend, backend"
    type = string
}
variable "vpc_cidr_first_two" {
	description = "first number fo cidr range"
    type = string
    default = "10.20"
}

variable "region" {
	description = "region name"
	default = "ap-southeast-1"
    type = string
}

variable "public_subnet_cidr" {
	type = list
	default = ["0.0/20", "16.0/20", "32.0/20"]
}

variable "private_subnet_cidr" {
	type = list
	default = ["48.0/20", "64.0/20", "80.0/20"]
}

variable "ingress_rules" {
    type = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_block  = string
      description = string
    }))
    default     = [
        {
          from_port   = 0
          to_port     = 21
          protocol    = "tcp"
          cidr_block  = "0.0.0.0/0"
          description = "ingress rule1"
        },
        {
          from_port   = 23
          to_port     = 65535
          protocol    = "tcp"
          cidr_block  = "0.0.0.0/0"
          description = "ingress rule2"
        },
    ]
}
