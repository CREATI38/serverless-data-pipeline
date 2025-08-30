variable "participant_name" {
  type = string
}

variable "transfer_bucket_name" {
  type = string
}

variable "transfer_endpoint_type" {
  type    = string
  default = "PUBLIC"
}

variable "users" {
  description = "List of Transfer Family users with username + prefix"
  type = list(object({
    name   = string
    prefix = string
  }))
}
