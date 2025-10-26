#!/bin/bash

# Safety destroy
./destroy.sh

# Delete container repo
aws ecr delete-repository \
  --repository-name teg/backend \
  --region ap-southeast-2 \
  --force \
  --no-cli-pager

# Delete terraform state bucket
aws s3 rb s3://teg-challenge-terraform --force --region ap-southeast-2

# Delete terraform lock table
aws dynamodb delete-table \
  --table-name teg-challenge-terraform-lock \
  --region ap-southeast-2 \
  --no-cli-pager