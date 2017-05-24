![logo](https://github.com/kubenow/KubeNow/blob/master/img/logo_wide_50dpi.png)

Collection of templates for building KubeNow image

[![Build Status](https://travis-ci.org/kubenow/KubeNow.svg?branch=master)](https://travis-ci.org/kubenow/KubeNow)

## Image Building

KubeNow uses prebuilt images to speed up the deployment. Image continous integration is defined in this repository: https://github.com/kubenow/image.

The images are exported on AWS and GCE:

- https://storage.googleapis.com/kubenow-images/kubenow-version-without-dots.tar.gz
- https://s3.amazonaws.com/kubenow-us-east-1/kubenow-version-without-dots.qcow2

Please refer to this page to figure out the image version: https://github.com/kubenow/image/releases. It is important to point out that the image versioning is now disjoint from the main KubeNow repository versioning. The main reason lies in the fact that pre-built images require less revisions and updates compared to the main KubeNow package.
