variable "vpc_cidr_block" {
  description = "Main CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "rds_db_name" {
  description = "Database name for cocktails DB"
  type        = string
  default     = "cocktails"
}