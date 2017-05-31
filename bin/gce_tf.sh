#!/bin/bash
# shellcheck disable=SC1091

# This Script will be executed as post-processor of the GCE packer builder within a GCE VM instances, not in Travis.
# Travis environment has not enough resources for the below steps, hence it takes a longer time causing timeouts.
# It takes one parameter: CURRENT_VERSION which is previously determined at runtime based on the current branch and tag.

#Install Tools
sudo apt-get update && sudo apt-get install qemu-utils awscli -y

# Donwloading kubenow-current compressed image from Google Storage
echo "Downloading kubenow compressed image from Google bucket..."
wget -nv https://storage.googleapis.com/kubenow-images/kubenow-"$1".tar.gz

# Extracting it
echo "Extracting image tar..."
tar -xzvf kubenow-"$1".tar.gz

# Converting image from raw to qcow format.
echo "Converting RAW image into QCOW2 format..."
qemu-img convert -f raw -O qcow2 disk.raw kubenow-"$1".qcow2  

# Uploading the new image format to the AWS S3 bucket. Previous copy will be overwritten.
echo "Sourcing AWS environment..."
source /tmp/aws_credentials.sh

echo "Uploading new image format into AWS S3 bucket: kubenow-us-east-1 ..."
aws s3 cp kubenow-"$1".qcow2 s3://kubenow-us-east-1 --region us-east-1 --acl public-read --quiet