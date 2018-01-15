#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Fix OS issue/bug: "sudo: unable to resolve host..."
sudo sed -i /etc/hosts -e "s/^127.0.0.1 localhost$/127.0.0.1 localhost $(hostname)/"

# Installing necessary tool for the script: python-glanceclient
sudo pip install --upgrade python-glanceclient

echo -e "OPENSTACK\n---------"
echo -e "Check if $IMAGE_NAME already exists:\n"

# Extracting KubeNow images that are flagged as $IMAGE_NAME
# Using tee (which almost always return 0) because of set -e at the beginning and possible grep's exit code -1 here.
glance image-list | grep "$IMAGE_NAME" | awk '{print $2, $4}' | tee /tmp/os_out_images.txt

tot_no_images=$(wc -l </tmp/os_out_images.txt)
counter_del_img=0

if [ "$tot_no_images" -gt "0" ]; then

  echo -e "\nDuplicated images found:\n"

  # Going through found duplicates in order to delete them
  while read -r line; do
    # Extracting image's "Name" and "ImageId"
    id_to_delete=$(echo "$line" | awk '{print $1}')
    name=$(echo "$line" | awk '{print $2}')
    echo -e "Name: $name \nID:$id_to_delete\n"

    # Deleting old KubeNow Image
    echo -e "Starting to delete duplicate KubeNow image: $id_to_delete.\n"
    glance image-delete "$id_to_delete"
    counter_del_img=$((counter_del_img + 1))
    echo -e "Keep looking for any other duplicate image...\n\n"
  done </tmp/os_out_images.txt

else
  echo -e "No KubeNow images named $IMAGE_NAME were found.\n"
fi

echo -e "\nNo of deleted image: $counter_del_img\nDone.\n"
