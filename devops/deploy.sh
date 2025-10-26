#!/bin/bash

set -e  # Exit immediately if a command fails

# Authenticate to ECR
aws ecr get-login-password --region ap-southeast-2 | \
  docker login --username AWS --password-stdin 058264550947.dkr.ecr.ap-southeast-2.amazonaws.com

# Build Docker image ( Very important if build from Mac M chip)
docker buildx build --platform linux/amd64 -f ../backend/Dockerfile.prod -t teg/backend ../backend --load

# Tag and push
docker tag teg/backend:latest 058264550947.dkr.ecr.ap-southeast-2.amazonaws.com/teg/backend:latest
docker push 058264550947.dkr.ecr.ap-southeast-2.amazonaws.com/teg/backend:latest

cd ../frontend
npm install
npm run build

cd ../devops
terraform init
terraform apply -auto-approve

aws s3 sync ../frontend/dist s3://teg-frontend --delete