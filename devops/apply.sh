#!/bin/bash

set -e  # Exit immediately if a command fails

# ------------------------------
# Terraform: apply infrastructure
# ------------------------------
echo "Initializing and applying Terraform..."
terraform init
terraform apply -auto-approve

# ------------------------------
# ECR: Authenticate, build, push
# ------------------------------
echo "Build backend"

aws ecr get-login-password --region ap-southeast-2 | \
  docker login --username AWS --password-stdin 058264550947.dkr.ecr.ap-southeast-2.amazonaws.com

docker buildx build --platform linux/amd64 -f ../backend/Dockerfile.prod -t teg/backend ../backend --load

docker tag teg/backend:latest 058264550947.dkr.ecr.ap-southeast-2.amazonaws.com/teg/backend:latest
docker push 058264550947.dkr.ecr.ap-southeast-2.amazonaws.com/teg/backend:latest

# ------------------------------
# Frontend: build 
# ------------------------------
echo "Build frontend"

cd ../frontend
npm install
npm run build

# ------------------------------
# ECS: Update service
# ------------------------------
echo "Sync backend"

aws ecs update-service \
  --cluster teg-backend \
  --service teg-backend-service \
  --force-new-deployment

# ------------------------------
# Frontend: build and sync to S3
# ------------------------------
echo "Sync frontend"

cd ../devops
aws s3 sync ../frontend/dist s3://teg-frontend --delete

# ------------------------------
# CloudFront: Invalidate cache
# ------------------------------
echo "Invalidating CloudFront cache for domain $DOMAIN..."

DOMAIN="teg.quangtechnologies.com"
aws cloudfront create-invalidation \
  --distribution-id $(aws cloudfront list-distributions \
      --query "DistributionList.Items[?Aliases.Items[0]=='$DOMAIN'].Id" \
      --output text) \
  --paths "/*"