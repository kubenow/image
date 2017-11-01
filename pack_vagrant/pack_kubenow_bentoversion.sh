#!/bin/bash
set -e

# export ATLAS_ORG=my org
# export ATLAS_TOKEN= token is stored somewhere else:)

USERNAME="kubenow"
BOX_NAME="kubenow"
BOX_VERSION="0.4.0b1"
VERSION="$BOX_VERSION"
BOX_BASENAME="$BOX_NAME-$BOX_VERSION"
DISK_SIZE=214400
VAGRANT_CLOUD_TOKEN="<your-vagrant-cloud-token>"
PROVIDER="virtualbox"

# Install bento (for uploading)
#gem install bento-ya

# clone bento
# checkout a speciffic master commit - in future change to release
# but for now to long since a release
if [ ! -d "bento" ]; then
  git clone https://github.com/chef/bento.git
fi
cd bento
git checkout eef9780188056e4b87d5db3f7a1cabbe7c7f4706

# Build from ubuntu subdir
cd ubuntu

# Inject requirements script into packer builder-json
FIND='"scripts/cleanup.sh",'
#INSERT='"$REQUIREMENTS_PATH/requirements\.sh",'
INSERT='"\.\./\.\./\.\./requirements\.sh",'
REPLACE="$INSERT\n$FIND"
sed "s#$FIND#$REPLACE#" ubuntu-16.04-amd64.json > kubenow.json

# build it
packer build --only=hyperv-iso \
             --force \
             -var "box_basename=$BOX_BASENAME" \
             -var "name=$BOX_NAME" \
             -var "template=$BOX_NAME" \
             -var "version=$BOX_VERSION" \
             -var "disk_size=$DISK_SIZE" \
             -var "iso_checksum=737ae7041212c628de5751d15c3016058b0e833fdc32e7420209b76ca3d0a535" \
             -var "iso_checksum_type=sha256" \
             -var "iso_name=ubuntu-16.04.2-server-amd64.iso" \
             -var "memory=1024" \
             -var "mirror=http://releases.ubuntu.com" \
             -var "mirror_directory=16.04.2" \
             -var "headless=true" \
             kubenow.json

# UPLOAD BOX
# https://www.vagrantup.com/docs/vagrant-cloud/api.html

# Create a new box (not needed since kubenow are there already
curl \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/boxes \
  --data "{ \"box\": { \"username\": \"$USERNAME\", \"name\": \"$BOX_NAME\" } }"

# Create a new version
curl \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/box/$USERNAME/$BOX_NAME/versions \
  --data "{ \"version\": { \"version\": \"$VERSION\" } }"

# Create a new provider
curl \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/box/$USERNAME/$BOX_NAME/version/$VERSION/providers \
  --data "{ \"provider\": { \"name\": \"$PROVIDER\" } }"
  
# Prepare the provider for upload/get an upload URL
response=$(curl \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/box/$USERNAME/$BOX_NAME/version/$VERSION/provider/$PROVIDER/upload )

# Extract the upload URL from the response (requires the jq command)
upload_path=$(echo "$response" | jq -r .upload_path)

# Perform the upload
curl $upload_path --request PUT --upload-file builds/$BOX_NAME.$PROVIDER.box > /dev/null

# Release the version
curl \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/box/$USERNAME/$BOX_NAME/version/$VERSION/release \
  --request PUT
