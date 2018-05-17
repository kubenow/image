#!/bin/bash

# GENERAL IDEA for this cron script: we want to make sure that every time security updates are issued,
# then building of a new kubenow image release is triggered.
# This script will perform the necessary modifications in order to use the latest stable kubenow image
# as source image for our packer builders and run security updates

# Exit immediately if a command exits with a non-zero status
set -e

# Making sure that current version is set to tag of latest supported release
CURRENT_VERSION="v$SUPPORTED_STABLE_TAG"
echo "Inside cron_script-CURRENT_VERSION is:$CURRENT_VERSION"
export CURRENT_VERSION

# Setting attribute source image name to the right value for each cloud provider
if [ "$HOST_CLOUD" = 'aws' ]; then
  echo -e "Running AWS Packer builder...\n"

  # Updating the filters.name within the aws builder file
  export AWS_FILTER_NAME="kubenow-$CURRENT_VERSION"
  echo -e "AWS filters.name is: $AWS_FILTER_NAME\n"
  # Removing owners ID as the default one is used for picking Ubuntu base image from which KubeNow is created.
  # Such default ID is needed for avoiding the "OptInRequired" from API calls when dealing with public images.
  sed -i '/owners/d' build-"$HOST_CLOUD".json
elif [ "$HOST_CLOUD" = 'azure' ]; then
  echo -e "Running Azure Packer builder...\n"

  # Performing login for azure-cli
  az login --service-principal -u "$AZURE_CLIENT_ID" -p "$AZURE_CLIENT_SECRET" --tenant "$AZURE_TENANT_ID" --output "table"

  # Instead of block with Image attibutes (image_publisher, image_offer, image_sku, and/or image_version.), we
  # pass only a URL to a custom VHD to use. First we remove block of not needed lines from build-azure.json
  sed -i -e '/image_publisher/,+3d' build-azure.json

  # Searching and composing URL of to a custom VHD to use, i.e. the latest kubenow stable image
  vhd_name=$(az storage blob list --account-name "$AZURE_STORAGE_ACCOUNT" --container-name "$AZURE_CONTAINER_NAME" --query [].name --output tsv | grep "kubenow-$CURRENT_VERSION[^-abcr]" | grep '.vhd')
  echo -e "vhd_name is: $vhd_name"

  # Check whether or not id string is empty
  if [ -z "$vhd_name" ]; then
    echo -e "No Azure images named kubenow-$CURRENT_VERSION have been found.\nInterrupting building.\n"
    exit 1
  fi
  # Composing URL to be injected into build-azure.json
  kn_vhd_url="https://kubenow.blob.core.windows.net/system/$vhd_name"

  # Finally, inserting image_url attribute in build-azure.json
  sed -i -e "/os_type/a \         \"image_url\": \"$kn_vhd_url\", " build-azure.json

  kn_vhd_url="https://kubenow.blob.core.windows.net/system/$vhd_name"

  # Finally, inserting image_url attribute in build-azure.json
  sed -i -e "/os_type/a \         \"image_url\": \"$kn_vhd_url\", " build-azure.json
  echo -e "Kubenow latest stable VHD url is: $kn_vhd_url .\n"
elif [ "$HOST_CLOUD" = 'gce' ]; then
  echo -e "Running GCE Packer builder...\n"
  export GCE_SOURCE_IMAGE_NAME="kubenow-$CURRENT_VERSION"
elif [ "$HOST_CLOUD" = 'openstack' ]; then
  echo -e "Running Openstack Packer builder...\n"
  export OS_SOURCE_IMAGE_NAME="kubenow-$CURRENT_VERSION"
else
  echo -e "HOST_CLOUD is NOT set to one of the following values: aws, azure, gce, openstack .\n"
fi

# Finally, overwriting provisioner's default script attribute (i.e. requirements.sh)
# Reason: using a stable image, no need to reinstall all requirements, only security updates
sed -i -e 's|requirements.sh|bin/get_security_updates.sh|g' build-"$HOST_CLOUD".json
