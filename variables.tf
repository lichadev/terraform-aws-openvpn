variable "compose_cidr" {
    type    = string
    default = "192.168.127.1/24"
}
variable "docker_cidr" { 
    type    = string
    default = "192.168.125.1/24"
}
variable "dns_name" {
    type =  string
    default = ""
}
variable "instance_type" {
    type    = string
    default = "t3a.micro"
}
variable "peered_networks" {
    type    = list(string)
    default = []
}
variable "ssh_ingress_cidrs" {
    type    = list(string)
    default = []
}
variable "ssm_parameters_path" {
    type    = string
    default = ""
}
variable "stack_name" {
    type    = string
    default = "openvpn"
}
variable "subnet_id" {
    type = string
}
variable "tags" {
    type    = map
    default = {}
}
variable "ubuntu_ami_id" {
    type    = string
    default = ""
}
variable "region" {
    type    = string
    default = "us-east-2"
}
variable "volume_path" {
    type    = string
    default = "/openvpn/"
}
variable "vpc_id" {
    type = string
}