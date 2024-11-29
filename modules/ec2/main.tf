resource "aws_instance" "this" {
  count         = var.instance_count
  iam_instance_profile = var.instance_profile
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = element(var.subnet_ids, count.index)
  key_name      = var.key_name
  security_groups = var.security_groups // regenerated each time? 

  tags = merge(
    var.tags,
    { Name = "${var.name_prefix}-${count.index + 1}" }
  )

  # user_data script to install NGINX
  # Use HEREDOC syntax (<<-EOT ... EOT) for multi-line scripts in user_data.
  # hostname -f command in Linux returns the fully qualified domain name (FQDN) of the host.  
  # An FQDN is the complete domain name for a specific computer or host on the internet or within a private network.
  # It typically includes:
  # The hostname (e.g., web-server).
  # The domain name (e.g., example.com).

  user_data = base64encode(<<-EOT
    #!/bin/bash
    # Update system packages
    yum update -y

    # Install Docker
    amazon-linux-extras enable docker
    yum install -y docker
    systemctl start docker
    systemctl enable docker

    # Run NGINX in Docker
    docker run -d --name nginx -p 80:80 nginx
  EOT
  )
}

