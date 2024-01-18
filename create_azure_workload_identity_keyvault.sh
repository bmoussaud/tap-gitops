# from https://medium.com/@rcdinesh1/access-secrets-via-argocd-through-external-secrets-9173001be885
# Dont Use.
set -x
CLUSTER_NAME=aks-eu-tap-8
VAULT_NAME=vault-micropets
VAULT_RG=mytanzu.xyz
IDENTITY_NAME="${VAULT_NAME}-for-${CLUSTER_NAME}"
TARGET_DIR="clusters/${CLUSTER_NAME}/cluster-config/config-post-install/external-secrets"
az aks show --resource-group ${CLUSTER_NAME} --name ${CLUSTER_NAME} -o json | jq '.securityProfile.workloadIdentity'
az aks show --resource-group ${CLUSTER_NAME} --name ${CLUSTER_NAME} -o json | jq '.oidcIssuerProfile'
az identity create --name ${IDENTITY_NAME} --resource-group ${VAULT_RG}
export USER_ASSIGNED_IDENTITY_CLIENT_ID="$(az identity show --name ${IDENTITY_NAME} --resource-group ${VAULT_RG} --query 'clientId' -otsv)"
export USER_ASSIGNED_IDENTITY_OBJECT_ID="$(az identity show --name ${IDENTITY_NAME} --resource-group ${VAULT_RG} --query 'principalId' -otsv)"
echo "USER_ASSIGNED_IDENTITY_CLIENT_ID: ${USER_ASSIGNED_IDENTITY_CLIENT_ID}"
echo "USER_ASSIGNED_IDENTITY_OBJECT_ID: ${USER_ASSIGNED_IDENTITY_OBJECT_ID}"
az keyvault set-policy --name ${VAULT_NAME} --secret-permissions get --object-id "${USER_ASSIGNED_IDENTITY_OBJECT_ID}"

export TENANT_ID=$(az account show - query tenantId | tr -d \")
echo "
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: ${USER_ASSIGNED_IDENTITY_CLIENT_ID}
    azure.workload.identity/tenant-id: ${TENANT_ID}
  name: external-secrets-test
  namespace: external-secrets
"  >>  ${TARGET_DIR}/sa.yaml

export SERVICE_ACCOUNT_ISSUER="$(az aks show --resource-group ${CLUSTER_NAME} --name ${CLUSTER_NAME} --query 'oidcIssuerProfile.issuerUrl' -otsv)"
echo "SERVICE_ACCOUNT_ISSUER ${SERVICE_ACCOUNT_ISSUER}"
az identity federated-credential create \
  --name "kubernetes-federated-credential" \
  --identity-name ${IDENTITY_NAME} \
  --resource-group ${ ${CLUSTER_NAME}} \
  --issuer "${SERVICE_ACCOUNT_ISSUER}" \
  --subject "system:serviceaccount:external-secrets:external-secrets-test"

echo "
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: azure-store
  namespace: playground
spec:
  provider:
    azurekv:
      authType: WorkloadIdentity
      vaultUrl: "https://keyvault-test.vault.azure.net"
      serviceAccountRef:
        name: external-secrets-test



