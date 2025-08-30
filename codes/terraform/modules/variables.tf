# General
variable "admin_name" {
  description = "Name of the Admin"
  type        = string
}

# S3 Variables
variable "bucket_name" {
  description = "Name of bucket used for naming (globally unique, includes environment info), and for tagging."
  type        = string
}



variable "data_configuration_files_path" {
  description = "Path for data configuration files."
  type        = string
}

# Lambda Variables
variable "requests_lambda_layer_file_path" {
  description = "Path for requests Lambda Layer. It should be a .zip file."
  type        = string
}

variable "pandas_lambda_layer_file_path" {
  description = "Path for pandas Lambda Layer. It should be a .zip file."
  type        = string
}

variable "lambda_function_pull_transfer_path" {
  description = "Path for pull transfer Lambda Function. It should be a .zip file."
  type        = string
}

variable "lambda_function_validate_file_path" {
  description = "Path for validate file Lambda Function. It should be a .zip file."
  type        = string
}

variable "lambda_function_validate_data_path" {
  description = "Path for validate data Lambda Function. It should be a .zip file."
  type        = string
}

variable "lambda_function_s3_copy_path" {
  description = "Path for S3 copy to Redshift Lambda Function. It should be a .zip file."
  type        = string
}

# Redshift
variable "redshift_namespace" {
  description = "Name for Redshift Serverless data warehouse."
  type        = string
}

variable "redshift_database_name" {
  description = "Database Name for Redshift Serverless data warehouse."
  type        = string
}

variable "redshift_workgroup_name" {
  description = "Workgroup Name for Redshift Serverless data warehouse."
  type        = string
}

variable "redshift_subnet_ids" {
  description = "List of Subnet IDs for Redshift Serverless data warehouse."
  type        = list(string)
}


