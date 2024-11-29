#!/bin/bash

# Variables
USER="ec2-user"
APP_DIR="/usr/share/nginx/html"
FILES="app/*"

# Loop through instances
for instance in $(aws ec2 describe-instances --filters "Name=tag:Name,Values=web-server-*" --query "Reservations[].Instances[].PublicIpAddress" --output text); do
  echo "Deploying to $instance"
  scp -i ~/.ssh/id_rsa $FILES $USER@$instance:$APP_DIR
done
