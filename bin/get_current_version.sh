#!/bin/bash
# This script will extract the current version based on the github repository's tags

# Get current_version
export CURRENT_VERSION
CURRENT_VERSION=v$(git describe --tags --always | tr -d .)

export KUBENOW_REGEX
KUBENOW_REGEX='^v[0-9]{3}([ab][0-9]{1,}|rc[0-9]{1,})?$'

# Checking whether or not current version is tagged as release
if [[ "$CURRENT_VERSION" =~ $KUBENOW_REGEX ]]; then
	echo "Kubenow current version tagged as release"
elif [ "$TRAVIS_BRANCH" == 'master' ]; then
	export CURRENT_VERSION="${CURRENT_VERSION}-current"
else
    export CURRENT_VERSION="${CURRENT_VERSION}-test"
fi

echo "KubeNow image version is: $CURRENT_VERSION"
export CURRENT_VERSION
