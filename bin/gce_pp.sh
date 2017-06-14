#!/bin/bash
# This Script will be executed as post-processor of the GCE packer builder.
# It will simply set the new created GCE KubeNow image as public

# Setting acls to public for new created image in Google storage so that it can be imported
echo "Setting new created Google image as shared publicly..."
gsutil acl ch -u AllUsers:R gs://kubenow-images/kubenow-"$CURRENT_VERSION".tar.gz
