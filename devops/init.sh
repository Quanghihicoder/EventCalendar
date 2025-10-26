#!/bin/bash

set -e  # Exit immediately if a command fails

# Create container repo
aws ecr create-repository \
  --repository-name teg/backend \
  --region ap-southeast-2 \
  --no-cli-pager

# Create Terraform bucket
aws s3 mb s3://teg-challenge-terraform --region ap-southeast-2

# Create terraform lock table
aws dynamodb create-table \
  --table-name teg-challenge-terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-southeast-2 \
  --no-cli-pager