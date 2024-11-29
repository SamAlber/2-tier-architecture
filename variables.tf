variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

# ------------------------- Networking ------------------------- #


variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

/*
Why 10.0.0.0/16?
Part of the Reserved Private IP Range:

The 10.0.0.0/8 block is one of the private IP address ranges defined by RFC 1918:
10.0.0.0/8
172.16.0.0/12
192.168.0.0/16
These addresses are non-routable on the public internet and are commonly used in private networks like AWS VPCs.
*/

variable "http_port" {
  description = "Port for HTTP traffic"
  default     = 80
}

variable "https_port" {
  description = "Port for HTTPS traffic"
  default     = 443
}

variable "db_port" {
  description = "Port for database traffic (MySQL default)"
  default     = 3306
}
