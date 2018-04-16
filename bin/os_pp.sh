#!/bin/bash
# This Script will be executed as post-processor of the Openstack packer builder. It builds a OS instance with Terraform

# Installing needed tools
# NB: this bash script run in travis where sudo is required. Thus we must put sudo before the usual pip command
sudo pip install python-openstackclient==3.11.0

# Building the OS Instance
cd ./bin || exit

# Environmental Variables for building with Terraform apply
export TF_VAR_username="$OS_USERNAME"
export TF_VAR_password="$OS_PASSWORD"
export TF_VAR_auth_url="$OS_AUTH_URL"
export TF_VAR_user_domain_id="$OS_USER_DOMAIN_ID"
export TF_VAR_domain_id="$OS_DOMAIN_ID"
export TF_VAR_region_name="$OS_REGION_NAME"
export TF_VAR_project_id="$OS_PROJECT_ID"
export TF_VAR_project_name="$OS_PROJECT_NAME"
export TF_VAR_api_version="$OS_IDENTITY_API_VERSION"
export TF_VAR_os_pool_name="$OS_POOL_NAME"
export TF_VAR_ssh_key_pub="${HOME}/.ssh/id_rsa.pub"
export TF_VAR_current_version=$CURRENT_VERSION
export TF_VAR_kubenow_image_name=$IMAGE_NAME

# Parsing KubeNow image ID of newly crated one. \s option will look for exact match
image_id=$(openstack image list | grep "\skubenow-$CURRENT_VERSION\s" | awk '{print $2}')
export TF_VAR_kubenow_image_id=$image_id

# Parsing some needed values for spawning Openstack instance with terraform
os_image_id=$(openstack image list | grep "Ubuntu 16.04 Xenial Xerus" | awk '{print $2}')
export TF_VAR_os_image_id=$os_image_id

network_id=$(openstack network list | grep -i "default" | awk '{print $2}')
export TF_VAR_network_id=$network_id

# Creating a credetianl file which will be provisioned via Terraform to an OS instance
echo -e "
#!/bin/bash
# Openstack credentials and env variables
export OS_PASSWORD=$OS_PASSWORD
export OS_USERNAME=$OS_USERNAME
export OS_AUTH_URL=$OS_AUTH_URL
export OS_USER_DOMAIN_ID=$OS_USER_DOMAIN_ID
export OS_DOMAIN_ID=$OS_DOMAIN_ID
export OS_REGION_NAME=$OS_REGION_NAME
export OS_PROJECT_ID=$OS_PROJECT_ID
export OS_PROJECT_NAME=$OS_PROJECT_NAME
export OS_IDENTITY_API_VERSION=3
export OS_POOL_NAME=$OS_POOL_NAME
export OS_EXTERNAL_NET_UUUID=$OS_EXTERNAL_NET_UUUID
# AWS credentials and Buckets URLs
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION
export AWS_BUCKET1_URL=$AWS_BUCKET1_URL
export AWS_BUCKET2_URL=$AWS_BUCKET2_URL
" >>/tmp/aws_and_os.sh

# Launching OS instance with terraform
/tmp/terraform apply
TF_STATUS="$?"

# Destroying OS instance with terraform
/tmp/terraform destroy -force

# Return code for Packer since this is a post-processor. This way if something goes wrong with terraform apply, then Packer knows is and will make the overall image building failing
exit $TF_STATUS
