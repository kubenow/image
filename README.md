![logo](https://github.com/kubenow/KubeNow/blob/master/img/logo_wide_50dpi.png)

Collection of templates for building the KubeNow image.

[![Build Status](https://travis-ci.org/kubenow/image.svg?branch=master)](https://travis-ci.org/kubenow/image)

## Image Building

KubeNow uses prebuilt images to speed up the deployment. Image continous integration is defined in this repository: https://github.com/kubenow/image.

The images are exported on GCE, AWS and Azure:

- `https://storage.googleapis.com/kubenow-images/kubenow-v<version-without-dots>.tar.gz`
- `https://s3.amazonaws.com/kubenow-us-east-1/kubenow-v<version-without-dots>.qcow2`
- `https://kubenow.blob.core.windows.net/system?restype=container&comp=list`

Please refer to this page to figure out the image version: https://github.com/kubenow/image/releases. It is important to point out that the image versioning is now disjoint from the main KubeNow repository versioning. The main reason lies in the fact that pre-built images require less revisions and updates compared to the main KubeNow package.
