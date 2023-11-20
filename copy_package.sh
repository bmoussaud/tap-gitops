#!/bin/bash

set -x
#REGISTRY_NAME=$1
PACKAGE=$1
VERSION=$2

source ~/.kube/acr/.${REGISTRY_NAME}.config

echo "INSTALL_REGISTRY_HOSTNAME ${INSTALL_REGISTRY_HOSTNAME}"
echo "PACKAGE ${PACKAGE}"
echo "VERSION ${VERSION}"
imgpkg copy -b registry.tanzu.vmware.com/${PACKAGE}:${VERSION} --to-repo ${INSTALL_REGISTRY_HOSTNAME}/${PACKAGE} --include-non-distributable-layers --concurrency 5
