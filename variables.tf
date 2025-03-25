variable "region" {
  description = "The AWS region to deploy the resources"
  type        = string
  default     = "eu-north-1"
}

variable "instance_type" {
  type    = string
  default = "c5.xlarge"
}

variable "ami" {
  type    = string
  default = "ami-0989fb15ce71ba39e"
}