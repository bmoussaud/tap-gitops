set -x
VERSION=$1
./copy_tap_package.sh akseutap6registry ${VERSION}
make gen-install-values gen-tap-gui-icon-values  TAP_VERSION=${VERSION}
git commit -am "upgrade TAP ${VERSION}"
git push
