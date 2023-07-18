source ~/.kube/acr/.${1}.config
export GIT_SSH_PRIVATE_KEY=$(cat ~/.dotconfig/.ssh/id_rsa)
export GIT_KNOWN_HOSTS=$(ssh-keyscan github.com)
export SOPS_AGE_KEY=$(cat ${2})
export SOPS_AGE_KEY_FILE=${2}
export SOPS_AGE_RECIPIENTS=`cat ${SOPS_AGE_KEY_FILE} | grep "# public key: " | sed 's/# public key: //'`
export TAP_PKGR_REPO=${INSTALL_REGISTRY_HOSTNAME}/tanzu-application-platform/tap-packages
export CLUSTER_NAME=${3}

echo "INSTALL_REGISTRY_HOSTNAME: ${INSTALL_REGISTRY_HOSTNAME}"
echo "INSTALL_REGISTRY_USERNAME: ${INSTALL_REGISTRY_USERNAME}"
echo "CLUSTER_NAME:              ${CLUSTER_NAME}"
echo "SOPS_AGE_KEY:              ${SOPS_AGE_KEY}"
echo "SOPS_AGE_KEY_FILE:         ${SOPS_AGE_KEY_FILE}"
echo "TAP_PKGR_REPO:             ${TAP_PKGR_REPO}"
echo "GIT_KNOWN_HOSTS           \n${GIT_KNOWN_HOSTS}\n/GIT_KNOWN_HOSTS"
echo "GIT_SSH_PRIVATE_KEY       \n${GIT_SSH_PRIVATE_KEY}\n/GIT_SSH_PRIVATE_KEY"