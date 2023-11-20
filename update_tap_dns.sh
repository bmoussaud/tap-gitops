
#!/bin/bash

IP=$(kubectl get HTTPProxy  -n tap-gui tap-gui -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
DOMAINS_NAME="tap152.tanzu.moussaud.org"
DOMAINS_NAME=$(kubectl get HTTPProxy  -n tap-gui tap-gui -o=jsonpath='{.spec.virtualhost.fqdn}')

TAP_INSTANCE=$(echo ${DOMAINS_NAME} | cut -d "." -f 2)
SUFFIX_DNS=$(echo ${DOMAINS_NAME} | cut -d "." -f 3,4,5)

echo "TAP_INSTANCE: ${TAP_INSTANCE}"
echo "SUFFIX_DNS:   ${SUFFIX_DNS}"
echo "IP:           ${IP}"
exit 1
set -x 
az network dns record-set a delete -g moussaud.org -z ${SUFFIX_DNS} -n "*.${TAP_INSTANCE}" -y
az network dns record-set a create -g moussaud.org -z ${SUFFIX_DNS} -n "*.${TAP_INSTANCE}" --metadata owner=tanzu
az network dns record-set a add-record  -g moussaud.org -z ${SUFFIX_DNS} -n "*.${TAP_INSTANCE}" -a ${IP} --ttl 10
