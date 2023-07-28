SOPS_AGE_KEY_FILE=~/.dotconfig/tapkey.txt
CLUSTER_NAME=aks-eu-tap-6
REGISTRY_NAME=$(shell echo $(subst -,,$(CLUSTER_NAME)-Registry) | tr '[:upper:]' '[:lower:]') 
TAP_VERSION=1.5.4

new-instance:
	./setup-repo.sh $(CLUSTER_NAME) sops	
	touch clusters/$(CLUSTER_NAME)/cluster-config/values/tap-non-sensitive-values.yaml

configure:
	source ./env.sh $(strip $(REGISTRY_NAME)) $(SOPS_AGE_KEY_FILE) $(CLUSTER_NAME) && cd ./clusters/$(CLUSTER_NAME) && ./tanzu-sync/scripts/configure.sh

generate: gen-install-values gen-sensitive-values gen-tap-gui-icon-values encrypt

gen-install-values:
	source ~/.kube/acr/.$(strip $(REGISTRY_NAME)).config && TAP_VERSION=$(TAP_VERSION) ytt -f templates/tap-install-values.yaml --data-values-env INSTALL_REGISTRY --data-values-env TAP > clusters/$(CLUSTER_NAME)/cluster-config/values/tap-install-values.yaml 	

gen-sensitive-values:
	source ./env.sh $(strip $(REGISTRY_NAME)) $(SOPS_AGE_KEY_FILE) $(CLUSTER_NAME) &&  ytt -f templates/tap-sensitive-values.yaml --data-values-env INSTALL_REGISTRY > clusters/$(CLUSTER_NAME)/cluster-config/values/tap-sensitive-values.yaml 

gen-tap-gui-icon-values:
	TAP_ICON_BASE64=$(shell base64 -i clusters/$(CLUSTER_NAME)/cluster-config/tap-logo.png) ytt -f templates/tap-gui-icon-values.yaml --data-values-file clusters/$(CLUSTER_NAME)/cluster-config/values/tap-install-values.yaml --data-values-env TAP > clusters/$(CLUSTER_NAME)/cluster-config/values/tap-gui-icon-values.yaml

encrypt:
	find clusters/$(CLUSTER_NAME) -name "*-sensitive.yaml" -exec ./encrypt_sops.sh {} \;

decrypt:
	export SOPS_AGE_KEY_FILE=$(SOPS_AGE_KEY_FILE) && sops --decrypt clusters/$(CLUSTER_NAME)/cluster-config/values/tap-sensitive-values.sops.yaml

deploy:		
	source ./env.sh $(strip $(REGISTRY_NAME)) $(SOPS_AGE_KEY_FILE) $(CLUSTER_NAME) && cd ./clusters/$(CLUSTER_NAME) && ./tanzu-sync/scripts/deploy.sh

undeploy:
	kapp delete -a tanzu-sync

kick:
	kctrl app kick -a sync -n tanzu-sync -y

tap-gui-ip:
	IP=$(shell kubectl get HTTPProxy  -n tap-gui tap-gui -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
	FQDN=$(shell kubectl get HTTPProxy  -n tap-gui tap-gui -o=jsonpath='{.spec.virtualhost.fqdn}')
	
tap-update-dns:
	./update_tap_dns.sh

encrypt-secret-store:
	SOPS_AGE_RECIPIENTS=`cat ${SOPS_AGE_KEY_FILE} | grep "# public key: " | sed 's/# public key: //'` && sops --encrypt  --encrypted-regex '^(data|stringData|tenantId)$$' ~/.azure/rbac/vault-micropets.yaml >  clusters/$(CLUSTER_NAME)/cluster-config/values/cluster-secret-store.yaml


CLUSTER_ESSENTIAL_INSTALL_BUNDLE=tanzu-cluster-essentials/cluster-essentials-bundle@sha256:54e516b5d088198558d23cababb3f907cd8073892cacfb2496bb9d66886efe15

tanzu-cluster-essentials:		
	source ~/.kube/acr/.$(strip $(REGISTRY_NAME)).config
	echo "## Test$(strip $(REGISTRY_NAME)) Registry..."
	source ~/.kube/acr/.$(strip $(REGISTRY_NAME)).config && test_registry_$(strip $(REGISTRY_NAME))
	imgpkg copy -b  registry.tanzu.vmware.com/$(CLUSTER_ESSENTIAL_INSTALL_BUNDLE) --to-repo $(strip $(REGISTRY_NAME)).azurecr.io/tanzu-cluster-essentials/cluster-essentials-bundle --include-non-distributable-layers --concurrency 5
	echo "## create namespace tanzu-cluster-essentials"
	kubectl create namespace tanzu-cluster-essentials --dry-run=client -o yaml | kubectl apply -f -
	echo "## pull the bundle"
	imgpkg pull -b $(strip $(REGISTRY_NAME)).azurecr.io/$(CLUSTER_ESSENTIAL_INSTALL_BUNDLE) -o /tmp/bundle/

	echo "## Deploying kapp-controller"
	ytt -f /tmp/bundle/kapp-controller/config/ -f /tmp/bundle/registry-creds/ --data-value-yaml registry.server=${INSTALL_REGISTRY_HOSTNAME} --data-value-yaml registry.username=${INSTALL_REGISTRY_USERNAME} --data-value-yaml registry.password=${INSTALL_REGISTRY_PASSWORD} --data-value-yaml kappController.deployment.concurrency=10 | kbld -f- -f /tmp/bundle/.imgpkg/images.yml | kapp deploy --yes -a kapp-controller -n tanzu-cluster-essentials -f-

	echo "## Deploying secretgen-controller"
	ytt -f /tmp/bundle/secretgen-controller/config/ -f /tmp/bundle/registry-creds/ --data-value-yaml registry.server=${INSTALL_REGISTRY_HOSTNAME} --data-value-yaml registry.username=${INSTALL_REGISTRY_USERNAME} --data-value-yaml registry.password=${INSTALL_REGISTRY_PASSWORD}| kbld -f- -f /tmp/bundle/.imgpkg/images.yml | kapp deploy --yes -a secretgen-controller -n tanzu-cluster-essentials -f-

	@rm  -rf /tmp/bundle/



