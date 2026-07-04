#!/bin/bash
# user_data script for Instance A - Homepage
# AMI: Amazon Linux 2023 | Instance type: t2.micro (Free Tier eligible)

dnf update -y
dnf install -y nginx

echo "<h1>Homepage!</h1>" > /usr/share/nginx/html/index.html

systemctl enable nginx
systemctl start nginx
