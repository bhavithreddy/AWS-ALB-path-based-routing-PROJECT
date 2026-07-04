#!/bin/bash
# user_data script for Instance C - Register
# AMI: Amazon Linux 2023 | Instance type: t2.micro (Free Tier eligible)

dnf update -y
dnf install -y nginx

mkdir -p /usr/share/nginx/html/register
echo "<h1>Register!</h1>" > /usr/share/nginx/html/register/index.html

systemctl enable nginx
systemctl start nginx
