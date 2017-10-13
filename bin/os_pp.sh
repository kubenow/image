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
export TF_VAR_region_name="$OS_REGION_NAME"
export TF_VAR_project_id="$OS_PROJECT_ID"
export TF_VAR_domain_id="$OS_DOMAIN_ID"
export TF_VAR_tenant_id="$OS_TENANT_ID"
export TF_VAR_os_pool_name="$OS_POOL_NAME"
export TF_VAR_ssh_key_pub="${HOME}/.ssh/id_rsa.pub"
export TF_VAR_current_version=$CURRENT_VERSION
export TF_VAR_kubenow_image_name=$IMAGE_NAME

# Parsing KubeNow image ID of newly crated one.
IMAGE_ID=$(glance image-list | grep "\skubenow-$CURRENT_VERSION\s")

# Just doing some text manipulation so to obtain a plain string, no spaces, no tab signs
IMAGE_ID=$(echo "$IMAGE_ID" | sed "s/| //;s/ | .*$//g")
export TF_VAR_kubenow_image_id=$IMAGE_ID

# Parsing some needed values for spawning Openstack instance with terraform
OS_IMAGE_ID=$(glance image-list | grep "Ubuntu16.04_XenialXerus")
OS_IMAGE_ID=$(echo "$OS_IMAGE_ID" | sed "s/| //;s/ | .*$//g")
export TF_VAR_os_image_id=$OS_IMAGE_ID

NETWORK_ID=$(neutron net-list | grep -i "SNIC 2017/13-4 Internal IPv4 Network")
NETWORK_ID=$(echo "$NETWORK_ID" | sed "s/| //;s/ | .*$//g")
export TF_VAR_network_id=$NETWORK_ID

# Creating a credetianl file which will be provisioned via Terraform to an OS instance
echo -e "
#!/bin/bash
# Openstack credentials and env variables
export OS_PASSWORD=$OS_PASSWORD
export OS_USERNAME=$OS_USERNAME
export OS_AUTH_URL=$OS_AUTH_URL
export OS_REGION_NAME=$OS_REGION_NAME
export OS_PROJECT_ID=$OS_PROJECT_ID
export OS_DOMAIN_ID=$OS_DOMAIN_ID
export OS_TENANT_ID=$OS_TENANT_ID
export OS_POOL_NAME=$OS_POOL_NAME
export OS_EXTERNAL_NET_UUID=$OS_EXTERNAL_NET_UUID
# AWS credentials
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION
" >> /tmp/aws_and_os.sh

# Launching OS instance with terraform
/tmp/terraform apply ; TF_STATUS="$?"


# Destroying OS instance with terraform
/tmp/terraform destroy -force

# Return code for Packer since this is a post-processor. This way if something goes wrong with terraform apply, then Packer knows is and will make the overall image building failing 
exit $TF_STATUS