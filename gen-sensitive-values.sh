
#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
set -o xtrace

cat > clusters/${CLUSTER_NAME}/cluster-config/values/tap-sensitive-values.yaml << EOF
tap_install:
  sensitive_values:
    shared: 
      image_registry:
        project_path: ${INSTALL_REGISTRY_HOSTNAME}/library/tanzu-build-service
        username: "${INSTALL_REGISTRY_USERNAME}"
        password: "${INSTALL_REGISTRY_PASSWORD}"
EOF

