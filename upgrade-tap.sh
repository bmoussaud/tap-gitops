set -x
VERSION=$1
./copy_tap_package.sh akseutap6registry ${VERSION}
make gen-install-values gen-tap-gui-icon-values TAP_VERSION=${VERSION}
make generate TAP_VERSION=${VERSION} CLUSTER_NAME=aks-eu-tap-8
git commit -am "upgrade TAP ${VERSION}"
git push
