#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

#Azure
CMD_OUTPUT_FMT="table"

# Performing Login (azure-cli is already installed in .travis.yml)
echo -e "AZURE:\n-----"
az login --service-principal -u "$AZURE_CLIENT_ID" -p "$AZURE_CLIENT_SECRET" --tenant "$AZURE_TENANT_ID" --output "$CMD_OUTPUT_FMT"

echo -e "-----------  -----------  ---------------------------  -------  ------------------------------------\n"
echo -e "Check if $IMAGE_NAME already exists:\n"

# Extracting id of the last successful built artifact.
# Useful later when we need to evaluate if there are any duplicates.
artifact_id=$(grep "OSDiskUri:" </tmp/pckr_build_log.txt | awk -F "/" '{print $NF}')
echo -e "ID of the latest successfull built artifact is: $artifact_id\n"

# This part is necessary to then list and identify the right namesake duplicates
if [ "$TRAVIS_EVENT_TYPE" = 'cron' ]; then
  # Then it means that we are working with stable release. That is: v040, v050, vXXX etc...
  # So we need to slightly modify the regexp for the next grep, otherwise a stable will also
  # match a test or a current.
  reg_expr="$IMAGE_NAME[^-abcr]"
else
  reg_expr="$IMAGE_NAME"
fi

# Extracting KubeNow images that are flagged as $IMAGE_NAME if any
# Using tee (which almost always return 0) because of set -e at the beginning
echo -e "Listing any potential duplicates for $IMAGE_NAME...\n"
az storage blob list --account-name "$AZURE_STORAGE_ACCOUNT" --container-name "$AZURE_CONTAINER_NAME" --query [].name --output tsv | grep "$reg_expr" | grep '.vhd' | tee /tmp/az_out_images.txt

tot_no_images=$(wc -l </tmp/az_out_images.txt)
counter_del_img=0

if [ "$tot_no_images" -gt "0" ]; then

  echo -e "\nDuplicated images found:\n"

  # Going through found duplicates in order to delete them
  while read -r line; do
    id_to_delete=$(echo "$line" | awk -F "/" '{print $NF}')

    if [ "$id_to_delete" != "$artifact_id" ]; then
      # Because of files' names convention between a vhd file and its related vmTemplate json
      rel_json_blob="${line/osDisk/vmTemplate}"
      rel_json_blob="${rel_json_blob/.vhd/.json}"

      # Deleting old KubeNow Image
      echo -e "Starting to delete duplicate KubeNow image: $IMAGE_NAME\n"
      az storage blob delete --account-name "$AZURE_STORAGE_ACCOUNT" -c "$AZURE_CONTAINER_NAME" -n "$line"

      # If related json blob does not exist, then will simply skip this step. Otherwise it must be deleted as well
      if [ -n "$rel_json_blob" ]; then
        az storage blob delete --account-name "$AZURE_STORAGE_ACCOUNT" -c "$AZURE_CONTAINER_NAME" -n "$rel_json_blob"
        echo -e "Starting to delete related json blob: $rel_json_blob\n"
      fi

      counter_del_img=$((counter_del_img + 1))
      echo -e "Keep looking for any other duplicate image...\n\n"
    fi
  done </tmp/az_out_images.txt
else
  echo -e "No KubeNow images named $IMAGE_NAME were found."
fi

echo -e "\nNo of deleted image: $counter_del_img\nDone.\n"
