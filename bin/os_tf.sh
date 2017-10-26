#!/bin/bash
# shellcheck disable=SC1091

# This Script will be executed as post-processor of the Openstack packer builder within a OS VM instances, not in Travis.
# Travis environment has not enough resources for the below steps, hence it takes a longer time causing timeouts.
# The script takes two parameters: current_version and image_id of the newly created KubewNow image.
set -e

kubenow_image_name="$1"
kubenow_image_id="$2"

# Fix OS potential issue/bug: "sudo: unable to resolve host..."
sudo sed -i /etc/hosts -e "s/^127.0.0.1 localhost$/127.0.0.1 localhost $(hostname)/"

# Install Tools
# NOTE: Reason why here I am installing glance via apt instead of pip it's because I am running a different version of Ubuntu compared to the Travis' one
sudo apt-get update
sudo apt-get install python-glanceclient awscli qemu-utils -y

# Donwloading newly created KubeNow from OS
echo "Downloading KubeNow image from Openstack..."
echo "Sourcing Openstack environment"
source /tmp/aws_and_os.sh
glance image-download --file "$kubenow_image_name" "$kubenow_image_id"

# Converting image from raw to qcow format.
echo "Converting RAW image into QCOW2 format..."
qemu-img convert -f qcow2 -O qcow2 -c -q "$kubenow_image_name" "$kubenow_image_name".qcow2

# Generate md5sum of image
md5sum "$kubenow_image_name".qcow2 > "$kubenow_image_name".qcow2.md5

# Uploading the new image format to the AWS S3 bucket. Previous copy will be overwritten.
echo "Uploading new image format into AWS S3 bucket: kubenow-us-east-1 ..."
aws s3 cp "$kubenow_image_name".qcow2 s3://kubenow-us-east-1 --region us-east-1 --acl public-read --quiet
aws s3 cp "$kubenow_image_name".qcow2.md5 s3://kubenow-us-east-1 --region us-east-1 --acl public-read --quiet

# Copy file to bucket in other aws region
aws s3 cp "s3://kubenow-us-east-1/$kubenow_image_name".qcow2 s3://kubenow-eu-central-1/ --region us-east-1 --region eu-central-1 --acl public-read
aws s3 cp "s3://kubenow-us-east-1/$kubenow_image_name".qcow2.md5 s3://kubenow-eu-central-1/ --region us-east-1 --region eu-central-1 --acl public-read
