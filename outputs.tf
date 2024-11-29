
// otherwise no input will be displayed. 
output "public_ips" {
  value       = module.ec2.public_ips
  description = "Public IPs of the created EC2 instances"
}