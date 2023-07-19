#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
#set -o xtrace
TAP_ICON_BASE64=$(base64 -i clusters/${CLUSTER_NAME}/cluster-config/tap-logo.png) ytt -f templates/tap-gui-icon-values.yaml --data-values-file clusters/${CLUSTER_NAME}/cluster-config/values/tap-install-values.yaml --data-values-env TAP > clusters/${CLUSTER_NAME}/cluster-config/values/tap-gui-icon-values.yaml



