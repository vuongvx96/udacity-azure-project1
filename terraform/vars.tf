variable "prefix" {
  description = "The prefix which should be used for all resources in the resource group specified"
  default     = "udacity-nd82-project-1"
  type        = string
}

variable "resource_group" {
  description = "Name of the resource group"
  default     = "Azuredevops"
  type        = string
}

variable "num_of_vms" {
  description = "Number of VM resources to create behund the load balancer"
  default     = 2
  type        = number
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default     = "eastus"
  type        = string
}

variable "packer_image_rg" {
  description = "Resource group where the packer image lives"
  default     = "Azuredevops"
}

variable "packer_image" {
  description = "Image created with packer"
  default     = "myPackerImage"
}

variable "username" {
  default = "vuongvx"
}

variable "password" {
  default = "Pa$$word!@"
}
