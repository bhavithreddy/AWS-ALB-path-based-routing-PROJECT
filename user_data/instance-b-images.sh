#!/bin/bash
# user_data script for Instance B - Images
# AMI: Amazon Linux 2023 | Instance type: t2.micro (Free Tier eligible)

dnf update -y
dnf install -y nginx

mkdir -p /usr/share/nginx/html/images
echo "<h1>Images!</h1>" > /usr/share/nginx/html/images/index.html

systemctl enable nginx
systemctl start nginx
