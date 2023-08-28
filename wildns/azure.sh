#https://cert-manager.io/docs/configuration/acme/dns01/azuredns/#managed-identity-using-aad-pod-identity

export DOMAIN_NAME=tanzu.moussaud.org
export CLUSTER_NAME=aks-eu-tap-6

export AZURE_DEFAULTS_GROUP=${CLUSTER_NAME}
export AZURE_DNS_RESOURCE_GROUP="moussaud.org"
# Create a Managed Identity
export IDENTITY_NAME=cert-manager

echo "IDENTITY_NAME: ${IDENTITY_NAME}"
az identity create --name "${IDENTITY_NAME}" -g ${AZURE_DEFAULTS_GROUP}
export IDENTITY_CLIENT_ID=$(az identity show --name "${IDENTITY_NAME}" --query 'clientId' -o tsv -g ${AZURE_DNS_RESOURCE_GROUP})
echo "IDENTITY_CLIENT_ID: ${IDENTITY_CLIENT_ID}"

az role assignment create \
    --role "DNS Zone Contributor" \
    --assignee ${IDENTITY_CLIENT_ID} \
    --scope $(az network dns zone show --name ${DOMAIN_NAME} -o tsv --query id -g ${AZURE_DNS_RESOURCE_GROUP})
    
# Add a Federated Identity
export SERVICE_ACCOUNT_NAME=cert-manager # This is the default Kubernetes ServiceAccount used by the cert-manager controller.
export SERVICE_ACCOUNT_NAMESPACE=cert-manager # This is the default namespace for cert-manager.
export SERVICE_ACCOUNT_ISSUER=$(az aks show --resource-group ${AZURE_DEFAULTS_GROUP} --name ${CLUSTER_NAME} --query "oidcIssuerProfile.issuerUrl" -o tsv)

echo "${SERVICE_ACCOUNT_NAMESPACE}:${SERVICE_ACCOUNT_NAME} ${SERVICE_ACCOUNT_ISSUER}"
az identity federated-credential create \
  --name "cert-manager" \
  --identity-name "${IDENTITY_NAME}" \
  --issuer "${SERVICE_ACCOUNT_ISSUER}" \
  --resource-group ${AZURE_DEFAULTS_GROUP} \
  --subject "system:serviceaccount:${SERVICE_ACCOUNT_NAMESPACE}:${SERVICE_ACCOUNT_NAME}"

export AZURE_SUBSCRIPTION=bmoussaud
export AZURE_SUBSCRIPTION_ID=$(az account show --name ${AZURE_SUBSCRIPTION} --query 'id' -o tsv)
echo "${AZURE_SUBSCRIPTION}:${AZURE_SUBSCRIPTION_ID}"


####
azureDNS2:
          clientID: 44466f39-4857-474f-9609-617334d14a7e
          clientSecretSecretRef:
            name: azure-dns-client-secret
            key: client-secret
          subscriptionID: cbca10bb-6ddc-45bd-8f18-c17d1dd1003f
          tenantID: b39138ca-3cee-4b4a-a4d6-cd83d9dd62f0
          resourceGroupName:  moussaud.org
          hostedZoneName: tanzu.moussaud.org
          environment: AzurePublicCloud