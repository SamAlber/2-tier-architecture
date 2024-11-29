variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
}

variable "ami" {
  description = "AMI ID for the EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where the instances will be launched"
  type        = list(string)
}

variable "key_name" {
  description = "Key pair name for SSH access"
  type        = string
}

variable "security_groups" {
  description = "List of security groups for the instances"
  type        = list(string)
}

variable "name_prefix" {
  description = "Prefix for the EC2 instance names"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the instances"
  type        = map(string)
}

variable "instance_profile" {
  description = "The IAM instance profile to attach to EC2 instances"
  type        = string
}
