variable "ami" {
  description = "AMI ID for the instances"
  type        = string
}

variable "instance_type" {
  description = "Instance type"
  type        = string
}

variable "key_name" {
  description = "SSH key name"
  type        = string
}

variable "security_groups" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
  default     = 5
}

variable "target_group_arns" {
  description = "List of ALB target group ARNs"
  type        = list(string)
}
