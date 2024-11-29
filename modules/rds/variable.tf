variable "allocated_storage" {
  description = "The allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "The maximum allocated storage in GB"
  type        = number
  default     = 100
}

variable "engine" {
  description = "The database engine (e.g., mysql, postgres)"
  type        = string
  default     = "mysql"
}

variable "engine_version" {
  description = "The version of the database engine"
  type        = string
  default     = "8.0"
}

variable "instance_class" {
  description = "The instance class for the database"
  type        = string
  default     = "db.t2.micro"
}

variable "db_name" {
  description = "The name of the database"
  type        = string
}

variable "db_username" {
  description = "The master username for the database"
  type        = string
}

variable "db_password" {
  description = "The master password for the database"
  type        = string
  sensitive   = true
}

variable "parameter_group_name" {
  description = "The name of the parameter group"
  type        = string
  default     = "default.mysql8.0"
}

variable "publicly_accessible" {
  description = "Whether the database is publicly accessible"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot on deletion"
  type        = bool
  default     = true
}

variable "multi_az" {
  description = "Enable Multi-AZ for RDS instance"
  type        = bool
  default     = false
}

variable "db_security_group_id" {
  description = "The ID of the security group for the database"
  type        = string
}

variable "db_subnet_group_name" {
  description = "The name of the database subnet group"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the resources"
  type        = map(string)
}
