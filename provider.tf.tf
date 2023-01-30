terraform {
  required_version = ">= 0.12"
}
provider "aws" {
  region = var.aws_region
}
data "aws_availability_zones" "available" {}

data "aws_vpc" "pt_vpc" {
  id = var.vpc_id
}

data "aws_security_group" "selected" {
 id = var.security_group_id
}

provider "http" {}