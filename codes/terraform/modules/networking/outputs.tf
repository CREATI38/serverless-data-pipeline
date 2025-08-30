output "subnet_1a_id" {
  value       = aws_subnet.main-southeast-1a.id
  description = "ID of Main Subnet in AZ ap-southeast-1a"
}

output "subnet_1b_id" {
  value       = aws_subnet.main-southeast-1b.id
  description = "ID of Main Subnet in AZ ap-southeast-1b"
}

output "subnet_1c_id" {
  value       = aws_subnet.main-southeast-1c.id
  description = "ID of Main Subnet in AZ ap-southeast-1c"
}
