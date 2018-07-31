#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Installing necessary tool for the script: awscli
pip install -qq awscli --upgrade

# Current list of other regions we work with
aws_regions=("eu-west-1" "eu-west-2" "eu-west-3" "eu-central-1" "ca-central-1" "us-east-1" "us-east-2" "us-west-1" "us-west-2")

# We make sure to correctly set the source region with the default one (which should be eu-west-1 for KubeNow AWS builder),
# the latest create AMI ID and its name
aws_source_region="$AWS_DEFAULT_REGION"
new_created_ami=$(grep -A 2 "successful builds" </tmp/pckr_build_log.txt | grep "^eu-west-1" | awk '{ print $2 }')
ami_name=$(aws ec2 describe-images --image-ids "$new_created_ami" | grep "Description" | awk '{print $2}' | sed -e 's/^"//' -e 's/,$//' -e 's/"$//')

echo -e "Amazon Web Services - Copying new created AMI into account's regions:\n\n"
echo -e "Current source region is: $aws_source_region.\n"
echo -e "Latest created AMI ID is: $new_created_ami.\n"
echo -e "Latest created AMI Name is: $ami_name.\n"

# Now we start the process of copy the Kubenow AMI across all the other regions
for reg in ${aws_regions[*]}; do
  if [ "$reg" != "$aws_source_region" ]; then
    if [ -n "$new_created_ami" ]; then
      echo -e "Copying AMI: $new_created_ami from $aws_source_region into $reg.\n"
      aws ec2 copy-image --source-image-id "$new_created_ami" --source-region "$aws_source_region" --region "$reg" --name "$ami_name" --description "$ami_name"
    else
      echo -e "Something went wrong. Most likely the AMI id is unavailable.\n"
      exit 1
    fi
  fi
done

exit $?
