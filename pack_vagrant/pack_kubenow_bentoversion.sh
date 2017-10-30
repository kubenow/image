#!/bin/bash
set -e

# export ATLAS_ORG=my org
# export ATLAS_TOKEN= token is stored somewhere else:)

BOX_VERSION="0.0.6"
BOX_BASENAME="kubenow"
DISK_SIZE=214400


# Install bento (for uploading)
#gem install bento-ya

# clone bento
# checkout a speciffic master commit - in future change to release
# but for now to long since a release
git clone https://github.com/chef/bento.git
cd bento
git checkout eef9780188056e4b87d5db3f7a1cabbe7c7f4706

cd ubuntu

# Inject requirements script into packer builder-json
FIND='"scripts/cleanup.sh",'
#INSERT='"$REQUIREMENTS_PATH/requirements\.sh",'
INSERT='"\.\./\.\./\.\./requirements\.sh",'
REPLACE="$INSERT\n$FIND"
sed "s#$FIND#$REPLACE#" ubuntu-16.04-amd64.json > kubenow.json

# build it
packer build --only=virtualbox-iso \
             --force \
             -var "box_basename=$BOX_BASENAME" \
             -var "name=$BOX_BASENAME" \
             -var "template=$BOX_BASENAME" \
             -var "version=$BOX_VERSION" \
             -var "disk_size=$DISK_SIZE" \
             -var "iso_checksum=737ae7041212c628de5751d15c3016058b0e833fdc32e7420209b76ca3d0a535" \
             -var "iso_checksum_type=sha256" \
             -var "iso_name=ubuntu-16.04.2-server-amd64.iso" \
             -var "memory=1024" \
             -var "mirror=http://releases.ubuntu.com" \
             -var "mirror_directory=16.04.2" \
             kubenow.json
             # -var "headless=true" \

# create meta.json
META=$(cat <<EOF
{
  "name": "$BOX_BASENAME",
  "version": "$BOX_VERSION",
  "box_basename": "$BOX_BASENAME",
  "template": "$BOX_BASENAME",
  "cpus": "1",
  "memory": "1024",
  "providers": [
    {
      "name": "virtualbox",
      "file": "$BOX_BASENAME-$BOX_VERSION.virtualbox.box"
    }
  ]
}
EOF
)
echo $META > "builds/$BOX_BASENAME-$BOX_VERSION.virtualbox.json"

# upload it
# bento upload

# release it
# bento release $BOX_BASENAME $BOX_VERSION
