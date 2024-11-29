output "instance_ids" {
  description = "IDs of the created instances"
  value       = aws_instance.this[*].id
}

output "private_ips" {
  description = "Private IPs of the created instances"
  value       = aws_instance.this[*].private_ip
}

output "public_ips" { // Doesn't want to display :( )
  value = aws_instance.this[*].public_ip
  description = "The public IP of the first EC2 instance"
}
