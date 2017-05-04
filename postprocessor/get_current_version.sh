#!/bin/bash
#This script will extract the current version based on the github repository's tags

#Get current_version
export CURRENT_VERSION=v$(git describe --tags --always | tr -d .)

regex='^v[0-9]{3}([ab][0-9]{1,}|rc[0-9]{1,})?$'

#Checking whether or not current version is tagged as release
if [[ $CURRENT_VERSION =~ $regex ]]; then
	echo "Kubenow current version tagged as release"
else
	export CURRENT_VERSION="current"
fi

echo "Kubenow current version is: $CURRENT_VERSION"