source ~/.kube/acr/.${1}.config
export GIT_SSH_PRIVATE_KEY=$(cat ~/.dotconfig/.ssh/github_rsa)
export GIT_KNOWN_HOSTS=$(ssh-keyscan github.com)
export SOPS_AGE_KEY_FILE=$(cat ${2})
export TAP_PKGR_REPO=${INSTALL_REGISTRY_HOSTNAME}/tanzu-application-platform/tap-packages

echo "INSTALL_REGISTRY_HOSTNAME: ${INSTALL_REGISTRY_HOSTNAME}"
echo "INSTALL_REGISTRY_USERNAME: ${INSTALL_REGISTRY_USERNAME}"
echo "SOPS_AGE_KEY_FILE:         ${SOPS_AGE_KEY_FILE}"
echo "TAP_PKGR_REPO:             ${TAP_PKGR_REPO}"
#echo ${GIT_KNOWN_HOSTS}
#echo ${GIT_SSH_PRIVATE_KEY}