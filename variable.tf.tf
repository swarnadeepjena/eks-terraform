
variable "aws_region" {
  default = "ap-south-1"
}

variable "cluster-name" {
  default = "IN-Cygnet-PT-EKSCluster-Staging"
  type    = string
}

variable "subnet_id_1" {
  type = string
  default = "subnet-0351849ca1f40f14c"
 }

 variable "subnet_id_2" {
  type = string
  default = "subnet-06d8b35d1d6410010"
 }

  variable "subnet_id_3" {
  type = string
  default = "subnet-0660c0bfe8456d52b"
 }

variable "vpc_id" {
  type = string
  default = "vpc-04ce2bf6faca3c9bf"
}

variable "security_group_id" {
  type = string
  default = "sg-0337fb7aab52640ee"
}