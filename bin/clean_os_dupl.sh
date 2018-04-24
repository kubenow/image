#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Installing necessary tool for the script: python-glanceclient
sudo pip install python-openstackclient==3.11.0

echo -e "OPENSTACK\n---------"
echo -e "Check if $IMAGE_NAME already exists:\n"

# Extracting id of the last successful built artifact.
# Useful later when we need to evaluate if there are any duplicates.
artifact_id=$(grep "An image was created:" </tmp/pckr_build_log.txt | awk '{print $NF}')
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
openstack image list | grep "$reg_expr" | awk '{print $2, $4}' | tee /tmp/os_out_images.txt

tot_no_images=$(wc -l </tmp/os_out_images.txt)
counter_del_img=0

if [ "$tot_no_images" -gt "0" ]; then

  echo -e "\nDuplicated images found:\n"

  # Going through found duplicates in order to delete them
  while read -r line; do
    # Extracting image's "Name" and "ImageId"
    id_to_delete=$(echo "$line" | awk '{print $1}')
    name=$(echo "$line" | awk '{print $2}')

    if [ "$id_to_delete" != "$artifact_id" ]; then
      # Deleting old KubeNow Image
      echo -e "Starting to delete duplicate KubeNow image...\nName: $name \nID:$id_to_delete\n"
      openstack image delete "$id_to_delete"
      counter_del_img=$((counter_del_img + 1))
      echo -e "Keep looking for any other duplicate image...\n\n"
    fi
  done </tmp/os_out_images.txt

else
  echo -e "No KubeNow images named $IMAGE_NAME were found.\n"
fi

echo -e "\nNo of deleted image: $counter_del_img\nDone.\n"
