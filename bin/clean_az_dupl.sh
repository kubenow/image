#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Installing Azure command-line client
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | \
     sudo tee /etc/apt/sources.list.d/azure-cli.list

sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893

sudo apt-get update && sudo apt-get install apt-transport-https azure-cli -y

#Azure
CMD_OUTPUT_FMT="table"

echo -e "AZURE:\n-----"
az login --service-principal \
         -u "$AZURE_CLIENT_ID" \
         -p "$AZURE_CLIENT_SECRET" \
         --tenant "$AZURE_TENANT_ID" \
         --output "$CMD_OUTPUT_FMT"

echo -e "-----------  -----------  ---------------------------  -------  ------------------------------------\n"
echo -e "Check if $IMAGE_NAME already exists:\n"
# Extracting KubeNow images that are flagged as $IMAGE_NAME
az storage blob list --account-name "$AZURE_STORAGE_ACCOUNT" --container-name "$AZURE_CONTAINER_NAME" --query [].name --output tsv | grep "$IMAGE_NAME" | grep '.vhd' | tee /tmp/az_out_images.txt

tot_no_images=$(wc -l < /tmp/az_out_images.txt)
counter_del_img=0

if [ "$tot_no_images" -gt "0" ]; then

    echo -e "\nDuplicated images found:\n" 

    # Going through found duplicates in order to delete them
    while read -r line; do  
        name=$(echo "$line" | grep "$IMAGE_NAME")

        # Because of files' names convention between a vhd file and its related vmTemplate json
        rel_json_blob="${line/osDisk/vmTemplate}"
        rel_json_blob="${rel_json_blob/.vhd/.json}"        

        # Deleting old KubeNow Image
        echo -e "Starting to delete duplicate KubeNow image: $name\n"
        az storage blob delete --account-name "$AZURE_STORAGE_ACCOUNT" -c "$AZURE_CONTAINER_NAME" -n "$line"

        # If related json blob does not exist, then will simply skip this step. Otherwise it must be deleted as well
        if [ -n "$rel_json_blob" ]; then
            az storage blob delete --account-name "$AZURE_STORAGE_ACCOUNT" -c "$AZURE_CONTAINER_NAME" -n "$rel_json_blob"
            echo -e "Starting to delete related json blob: $rel_json_blob\n"
        fi

        counter_del_img=$((counter_del_img+1))
        echo -e "Keep looking for any other duplicate image...\n\n"
    done < /tmp/az_out_images.txt
else
    echo -e "No KubeNow images named $IMAGE_NAME were found."
fi

echo -e "\nNo of deleted image: $counter_del_img\nDone.\n"
