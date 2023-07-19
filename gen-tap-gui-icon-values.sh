
#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
set -o xtrace

ICON_BASE64=$(base64 -i clusters/${CLUSTER_NAME}/cluster-config/tap-logo.png)

cat > clusters/${CLUSTER_NAME}/cluster-config/values/tap-gui-icon-values.yaml << EOF
tap_install:
  values:
    tap_gui:
      app_config:        
        customize:
          custom_logo: "${ICON_BASE64}"
          custom_name: "Micropets Tanzu Application Platform"
          
EOF

