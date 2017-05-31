#!/bin/bash
# This Script will be executed as post-processor of the GCE packer builder. It builds a GCE instance with Terraform

# Setting acls to public for new created image in Google storage so that it can be imported
echo "Setting new created Google image as shared publicly..."
gsutil acl ch -u AllUsers:R gs://kubenow-images/kubenow-"$CURRENT_VERSION".tar.gz

# Building the GCE Instances
cd ./bin || exit

# Environmental Variables for building with Terraform apply
export TF_VAR_gce_credentials_file="account_file.json"
export TF_VAR_gce_project="phenomenal-1145"
export TF_VAR_gce_zone="europe-west1-b"
export TF_VAR_ssh_key="${HOME}/.ssh/id_rsa.pub"
export TF_VAR_current_version=$CURRENT_VERSION

# Creating a simple AWS credential file which will be provisioned as script to a GCE instance with Terraform 
printf 'AWS_DEFAULT_REGION=%s\nAWS_ACCESS_KEY_ID=%s\nAWS_SECRET_ACCESS_KEY=%s\n' "$AWS_DEFAULT_REGION" "$AWS_ACCESS_KEY_ID" "$AWS_SECRET_ACCESS_KEY" > "./aws_credentials.sh"

# Launching GCE instance with terraform
/tmp/terraform apply ; TF_STATUS="$?"

# Destroying GCE instance with terraform
/tmp/terraform destroy -force

# Return code for Packer since this is a post-processor. This way if something goes wrong with terraform apply, then Packer knows is and will make the overall image building failing 
exit $TF_STATUS