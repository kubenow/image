#!/bin/bash
# This Script will be executed as post-processor of the Openstack packer builder. It builds a OS instance with Terraform

# Installing needed tools
pip install --upgrade pip
pip install python-glanceclient python-neutronclient

# Building the OS Instance
cd ./bin || exit

# Environmental Variables for building with Terraform apply
export TF_VAR_username="$OS_USERNAME"
export TF_VAR_password="$OS_PASSWORD"
export TF_VAR_auth_url="$OS_AUTH_URL"
export TF_VAR_user_domain_id="$OS_USER_DOMAIN_ID"
export TF_VAR_domain_id="$DOMAIN_ID"
export TF_VAR_region_name="$REGION_NAME"
export TF_VAR_project_id="$PROJECT_ID"
export TF_VAR_tenant_id="$TENANT_ID"
export TF_VAR_tenant_name="$TENANT_NAME"
export TF_VAR_auth_version="$AUTH_VERSION"
export TF_VAR_os_pool_name="$OS_POOL_NAME"
export TF_VAR_ssh_key_pub="${HOME}/.ssh/id_rsa.pub"
export TF_VAR_current_version=$CURRENT_VERSION
export TF_VAR_kubenow_image_name="kubenow-$CURRENT_VERSION"

# Parsing KubeNow image ID of newly crated one. The following lines of code are necessary.
# Let's take the case of a release, e.g v030. Searching for "kubenow-v030" will also retunr "-test" and "-current" images
# Hence we need to check whether or not current version is tagged as release
if [[ "$CURRENT_VERSION" =~ $KUBENOW_REGEX ]]; then
    echo "Kubenow current version tagged as release"
    IMAGE_ID=$(glance image-list | grep "kubenow-$CURRENT_VERSION[^-]")
else
    echo "Kubenow current version tagged as \"test\" or \"current\""
    IMAGE_ID=$(glance image-list | grep "kubenow-$CURRENT_VERSION")
fi
# Just doing some text manipulation so to obtain a plain string, no spaces, no tab signs
IMAGE_ID=$(echo "$IMAGE_ID" | sed "s/| //;s/ | .*$//g")
export TF_VAR_kubenow_image_id=$IMAGE_ID

# Parsing some needed values for spawning Openstack instance with terraform
OS_IMAGE_ID=$(glance image-list | grep "Ubuntu 16.04 Xenial Xerus")
OS_IMAGE_ID=$(echo "$OS_IMAGE_ID" | sed "s/| //;s/ | .*$//g")
export TF_VAR_os_image_id=$OS_IMAGE_ID

NETWORK_ID=$(neutron net-list | grep -i "default")
NETWORK_ID=$(echo "$NETWORK_ID" | sed "s/| //;s/ | .*$//g")
export TF_VAR_network_id=$NETWORK_ID

# Launching OS instance with terraform
/tmp/terraform apply ; TF_STATUS="$?"

# Destroying OS instance with terraform
/tmp/terraform destroy -force

# Return code for Packer since this is a post-processor. This way if something goes wrong with terraform apply, then Packer knows is and will make the overall image building failing 
exit $TF_STATUS