variable "instance_type" {
  default = "t3a.micro"
  type    = string
}
variable "associate_public_ip_address" {
  default = false
  type    = bool
}
variable "instance_count" {
  default = 1
  type    = number
}
variable "key_name" {
  default = "prod-key"
  type    = string
}
variable "subnet_id" {
  type    = string
}
variable "sg_id" {
  type = list
}
variable "name" {
  type = string
}
variable "env" {
  type = string
}
variable "pod" {
  type = string
}
