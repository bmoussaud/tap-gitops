#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
set -o xtrace
tanzu-sync/scripts/sensitive-values.sh > /tmp/x.yaml

cat /tmp/x.yaml

kapp deploy -a tanzu-sync \
  -f <(ytt -f tanzu-sync/app/config \
           -f cluster-config/config/tap-install/.tanzu-managed/version.yaml \
           --data-values-file tanzu-sync/app/values/ \
           --data-values-file sensitive-values.sh.stdout=<(tanzu-sync/scripts/sensitive-values.sh) \
      ) $@
