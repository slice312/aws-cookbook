#!/bin/bash

set -e

cd lambda-eip-assigner

# get the timestamp of the last modification for each file under git control
# sort in descending order and retrieve the most recent one
TIMESTAMP=$(git ls-files -z | \
  xargs -0 -n1 -I {} -- git log -1 --date=format:"%Y%m%d%H%M" --format="%ad" {} | \
  sort -r | \
  head -n 1)

echo "TIMESTAMP=${TIMESTAMP}"

# build lambda with AWS SAM CLI
# and set last timestamp for each file
sam build
cd .aws-sam/build/EipAssigner
find . -exec touch -t ${TIMESTAMP} {} +
zip -r9Xq ../eip-assigner.zip ./*

cd ..
shasum -a 256 eip-assigner.zip