resource "aws_autoscaling_group" "web_asg" {
  desired_capacity = var.desired_capacity   # Desired number of instances
  max_size         = var.max_size           # Maximum number of instances
  min_size         = var.min_size           # Minimum number of instances
  vpc_zone_identifier = var.subnet_ids      # Subnets for the ASG

  launch_template {
    id      = aws_launch_template.web_server.id
    version = "$Latest"
  }

  #target_group_arns = [module.alb.target_group_arn] # Attach to the ALB target group (ERROR will occur because modules cannot directly access other modules.)
  target_group_arns = var.target_group_arns
  /*
   In your case, the asg module is trying to directly reference module.alb.target_group_arn, but it doesn't have access to the alb module's outputs.
    To resolve this, you need to pass the ALB's target group ARN as an input to the asg module.
    */
}

#--------------------- ASG Template -----------------------# 

resource "aws_launch_template" "web_server" {
  name          = "web-server-launch-template"
  image_id      = var.ami                  # AMI ID
  instance_type = var.instance_type        # Instance type
  key_name      = var.key_name             # SSH key pair

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = var.security_groups
    subnet_id                   = null # Subnet will be managed by ASG
  }

  # Requires base64encode for ASG Template
  user_data = base64encode(<<-EOT
    #!/bin/bash
    yum update -y
    amazon-linux-extras enable nginx1
    yum install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "Welcome to Auto Scaled NGINX on $(hostname -f)" > /usr/share/nginx/html/index.html
  EOT
  )
}

