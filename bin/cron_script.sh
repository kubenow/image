#!/bin/bash

# GENERAL IDEA for this cron script: we want to make sure that every time security updates are issued,
# then building of a new kubenow image release is triggered.
# This script will perform the necessary modifications in order to use the latest stable kubenow image
# as source image for our packer builders and run security updates

# Exit immediately if a command exits with a non-zero status
set -e

# Setting attribute source image name to the right value for each cloud provider
if [ "$HOST_CLOUD" = 'aws' ]; then
    echo -e "Running AWS Packer builder...\n"
    
    # Installing aws-cli
    pip install awscli --upgrade --user
    
    # Extracting ami ID of latest kubenow stable (usually in the format of "ImageId:" "ami-xxxxxxx",)
    kubenow_latest_amiId=$(aws ec2 describe-images --filters "Name=name,Values=kubenow-v$SUPPORTED_STABLE_TAG" "Name=owner-id,Values=105135433346" \
    | grep "ImageId" \
    | awk '{ print $2 }' \
    | sed -e 's/^"//' -e 's/",$//' )
    
    # Check whether or not id string is empty
    if [ -n "$kubenow_latest_amiId" ]; then
        # Updating source image id that will be used for AWS packer builder
        echo -e "Kubenow latest stable ami ID is: $kubenow_latest_amiId .\n"
        export AWS_SOURCE_IMAGE_ID="$kubenow_latest_amiId"
        echo -e "AWS Source Image ID is: $AWS_SOURCE_IMAGE_ID\n"
    
    else
        echo -e "No AWS images named kubenow-v$SUPPORTED_STABLE_TAG have been found.\nInterrupting building.\n"
        exit 1

    fi

elif [ "$HOST_CLOUD" = 'azure' ]; then
    echo -e "Running Azure Packer builder...\n"
    
    # Performing login for azure-cli (which is already installed, see .travis.yml)
    az login --service-principal -u "$AZURE_CLIENT_ID" -p "$AZURE_CLIENT_SECRET" --tenant "$AZURE_TENANT_ID" --output "table"

    # Instead of block with Image attibutes (image_publisher, image_offer, image_sku, and/or image_version.), we
    # pass only a URL to a custom VHD to use. First we remove block of not needed lines from build-azure.json
    sed -e '/image_publisher/,+3d' build-azure.json > /tmp/modified-build-azure.json
    
    # Searching and composing URL of to a custom VHD to use, i.e. the latest kubenow stable image
    vhd_name=$(az storage blob list --account-name "$AZURE_STORAGE_ACCOUNT" --container-name "$AZURE_CONTAINER_NAME" --query [].name --output tsv | grep "kubenow-v$SUPPORTED_STABLE_TAG" | grep '.vhd')
    kn_vhd_url="https://kubenow.blob.core.windows.net/system/$vhd_name"
    
    # Finally, inserting image_url attribute in build-azure.json
    sed '/os_type/a \         "image_url": "'"$kn_vhd_url"'", ' build-azure.json > /tmp/modified-build-azure.json
    cat /tmp/modified-build-azure.json > build-azure.json

elif [ "$HOST_CLOUD" = 'gce' ]; then
    echo -e "Running GCE Packer builder...\n"
    export GCE_SOURCE_IMAGE_NAME="kubenow-v$SUPPORTED_STABLE_TAG"
    echo -e "GCE Source Image Name is: $GCE_SOURCE_IMAGE_NAME\n"

elif [ "$HOST_CLOUD" = 'openstack' ]; then
    echo -e "Running Openstack Packer builder...\n"
    export OS_SOURCE_IMAGE_NAME="kubenow-v$SUPPORTED_STABLE_TAG"

else
    echo -e "Variable HOST_CLOUD is NOT set to one of the following values: aws, azure, gce, openstack .\n"

fi

# Last but not least, replacing the script attribute in the provisioner section to a different value than default one (i.e. requirements.sh)
# Given that we are starting from a stable kubenow image, we do not want to reinstall the requirements, rather to perform security updates
sed -i -e 's|requirements.sh|bin/get_security_updates.sh|g' build-"$HOST_CLOUD".json

# Print to output the builder json (mainly for testing, can be removed if output too verbose in .travis.yaml)
cat build-"$HOST_CLOUD".json
