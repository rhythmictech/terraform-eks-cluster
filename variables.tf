locals {
  common_tags = {
    env       = var.env
    owner     = var.owner
    namespace = var.namespace
  }
}

variable "additional_tags" {
  type = map(string)
  default = {}
}

variable "env" {
  type = string
}

variable "namespace" {
  type = string
}

variable "owner" {
  type = string
}

variable "region" {
  default = ""
}

variable "account_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "key_name" {
  type = string  
}

variable "subnets" {
  type = list(string)
}

variable "vpc_id" {
  type = string  
}

variable "worker_additional_security_group_ids" {
  type = list(string)
  default = []
}

variable "worker_groups" {
  type = list(map(string))
}
