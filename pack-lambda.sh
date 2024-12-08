#!/bin/bash

set -e


cd lambda-eip-assigner
sam build

cd .aws-sam/build/EipAssigner
zip -r -X ../eip-assigner.zip ./*
cd ..
shasum -a 256 eip-assigner.zip

# a5af7ba627cb13702b5fa98715093bb5642e9b4f31b79799b556c6e5fa9e7d7f  eip-assigner.zip