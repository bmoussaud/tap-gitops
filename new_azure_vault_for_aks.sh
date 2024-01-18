#!/bin/bash
#from https://github.com/doddatpivotal/akv-external-secret
set -x
CLUSTER_NAME=aks-eu-tap-8
RESOURCE_GROUP=${CLUSTER_NAME}
VAULT_NAME=${CLUSTER_NAME}-micropets
VAULT_RG=${RESOURCE_GROUP}
AD_APP_NAME="${VAULT_NAME}-for-${CLUSTER_NAME}"
TARGET_DIR="clusters/${CLUSTER_NAME}/cluster-config/config-post-install/external-secrets"
PLATFORM_OPS_NAMESPACE=external-secrets

# Create Key Vault
az keyvault create --name $VAULT_NAME --resource-group $RESOURCE_GROUP

## Populate Key Vault with secrets
az keyvault secret set --name github-username --vault-name $VAULT_NAME --value "bmoussaud"
az keyvault secret set --name github-username --vault-name $VAULT_NAME --value ${GITHUB_PASSWORD}

# Rerive the the OIDC issuer URL of the newly created cluster
OIDC_ISSUER_URL=$(az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query "oidcIssuerProfile.issuerUrl" -otsv) && echo $OIDC_ISSUER_URL
# Create an AAD application
az ad sp create-for-rbac --name "$AD_APP_NAME"
AD_APP_CLIENT_ID=$(az ad sp list --display-name "$AD_APP_NAME" --query '[0].appId' -otsv) && echo $AD_APP_CLIENT_ID

# Grant permissions to the client to access the key vault
az keyvault set-policy --name "$VAULT_NAME" --secret-permissions get --spn "$AD_APP_CLIENT_ID"

TENANT_ID=$(az account show --query tenantId | tr -d \") && echo $TENANT_ID

# Create a Kubernetes service account for use by ESO
echo "
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    azure.workload.identity/use: true
  annotations:
    azure.workload.identity/client-id: ${AD_APP_CLIENT_ID}
    azure.workload.identity/tenant-id: ${TENANT_ID}
  name: micropets-azure-vault
  namespace: ${PLATFORM_OPS_NAMESPACE}" >${TARGET_DIR}/micropets-azure-vault.yaml

# Establish federated identity credential between the identity and the service account issuer & subject
AD_APP_OBJECT_ID="$(az ad app show --id $AD_APP_CLIENT_ID --query id -otsv)" && echo $AD_APP_OBJECT_ID
ytt -f azure-fed-credential-params.yaml -v platform_ops_namespace=${PLATFORM_OPS_NAMESPACE} -v oidc_issuer_url=$OIDC_ISSUER_URL -ojson >/tmp/fed-credential-params.json
echo "dump fed-credential-params.json"
cat /tmp/fed-credential-params.json
echo "/dump fed-credential-params.json"
az ad app federated-credential create --id $AD_APP_OBJECT_ID --parameters @/tmp/fed-credential-params.json

echo "
---
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: micropets-azure-vault
spec:
  provider:
    azurekv:
      authType: WorkloadIdentity
      vaultUrl: https://${VAULT_NAME}.vault.azure.net
      serviceAccountRef:
        name: micropets-azure-vault
        namespace: ${PLATFORM_OPS_NAMESPACE}" >>${TARGET_DIR}/micropets-azure-vault.yaml
