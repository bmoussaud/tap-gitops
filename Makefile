SOPS_AGE_KEY_FILE=~/dotconfig/tapkey.txt
CLUSTER_NAME=aks-eu-tap-6
REGISTRY_NAME=$(shell echo $(subst -,,$(CLUSTER_NAME)-Registry) | tr '[:upper:]' '[:lower:]') 
TAP_VERSION=1.5.4

check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $2, ($2))))

new-instance:
	./setup-repo.sh $(CLUSTER_NAME) sops	
	touch clusters/$(CLUSTER_NAME)/cluster-config/values/tap-non-sensitive-values.yaml

gen-sensitive-tanzu-sync:
	source ./env.sh $(strip $(REGISTRY_NAME)) $(SOPS_AGE_KEY_FILE) $(CLUSTER_NAME)

configure:
	source ./env.sh $(strip $(REGISTRY_NAME)) $(SOPS_AGE_KEY_FILE) $(CLUSTER_NAME) && cd ./clusters/$(CLUSTER_NAME) && ./tanzu-sync/scripts/configure.sh

clone:
	$(call check_defined, FROM_CLUSTER_NAME)	
	cp clusters/$(FROM_CLUSTER_NAME)/cluster-config/values/tap-values.yaml clusters/$(CLUSTER_NAME)/cluster-config/values/tap-values.yaml
	cp -r clusters/$(FROM_CLUSTER_NAME)/cluster-config/config/extras clusters/$(CLUSTER_NAME)/cluster-config/config
	sed "s/$(FROM_CLUSTER_NAME)/$(CLUSTER_NAME)/g" clusters/$(FROM_CLUSTER_NAME)/cluster-config/config/extras/config-post-install/app.yaml > clusters/$(CLUSTER_NAME)/cluster-config/config/extras/config-post-install/app.yaml
	cp -r clusters/$(FROM_CLUSTER_NAME)/cluster-config/config-post-install clusters/$(CLUSTER_NAME)/cluster-config
	cp -r clusters/$(FROM_CLUSTER_NAME)/cluster-config/namespace-provisioner clusters/$(CLUSTER_NAME)/cluster-config
	sed "s/$(FROM_CLUSTER_NAME)/$(CLUSTER_NAME)/g" clusters/$(FROM_CLUSTER_NAME)/cluster-config/values/tap-values.yaml > clusters/$(CLUSTER_NAME)/cluster-config/values/tap-values.yaml


generate: gen-install-values gen-sensitive-values gen-tap-gui-icon-values gen-lsp-secrets encrypt

gen-install-values:
	source ~/.kube/acr/.$(strip $(REGISTRY_NAME)).config && TAP_VERSION=$(TAP_VERSION) ytt -f templates/tap-install-values.yaml --data-values-env INSTALL_REGISTRY --data-values-env TAP > clusters/$(CLUSTER_NAME)/cluster-config/values/tap-install-values.yaml 	

gen-sensitive-values:
	source ./env.sh $(strip $(REGISTRY_NAME)) $(SOPS_AGE_KEY_FILE) $(CLUSTER_NAME) &&  ytt -f templates/tap-sensitive-values.yaml --data-values-env INSTALL_REGISTRY > clusters/$(CLUSTER_NAME)/cluster-config/values/tap-sensitive-values.yaml 

tap-gui-icon: 
	cp templates/tap-logo.png clusters/$(CLUSTER_NAME)/cluster-config/tap-logo.png

gen-tap-gui-icon-values: tap-gui-icon
	TAP_ICON_BASE64=$(shell base64 -i clusters/$(CLUSTER_NAME)/cluster-config/tap-logo.png) ytt -f templates/tap-gui-icon-values.yaml --data-values-file clusters/$(CLUSTER_NAME)/cluster-config/values/tap-install-values.yaml --data-values-env TAP > clusters/$(CLUSTER_NAME)/cluster-config/values/tap-gui-icon-values.yaml

gen-lsp-secrets:
	source ./env.sh $(strip $(REGISTRY_NAME)) $(SOPS_AGE_KEY_FILE) $(CLUSTER_NAME) &&  ytt -f templates/tap-lsp-registry-secrets.yaml --data-values-env INSTALL_REGISTRY > clusters/$(CLUSTER_NAME)/cluster-config/config-post-install/lsp/lsp-sensitive-values.yaml

encrypt:
	find clusters/$(CLUSTER_NAME) -name "*-sensitive-values.yaml" -exec ./encrypt_sops.sh {} \;

decrypt:
	export SOPS_AGE_KEY_FILE=$(SOPS_AGE_KEY_FILE) && sops --decrypt clusters/$(CLUSTER_NAME)/cluster-config/values/tap-sensitive-values.sops.yaml

deploy: tanzu-cluster-essentials
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

availables_version:
	imgpkg tag list -i registry.tanzu.vmware.com/tanzu-application-platform/tap-packages | sort -V



encrypt-secret-store:
	SOPS_AGE_RECIPIENTS=`cat ${SOPS_AGE_KEY_FILE} | grep "# public key: " | sed 's/# public key: //'` && sops --encrypt  --encrypted-regex '^(data|stringData|tenantId)$$' ~/.azure/rbac/vault-micropets.yaml >  clusters/$(CLUSTER_NAME)/cluster-config/values/cluster-secret-store.yaml


TDS_VERSION=1.12.1
copy_pgsql_package:
	source ./env.sh $(strip $(REGISTRY_NAME)) $(SOPS_AGE_KEY_FILE) $(CLUSTER_NAME) && ./copy_package.sh packages-for-vmware-tanzu-data-services/tds-packages $(TDS_VERSION) 


CLUSTER_ESSENTIAL_INSTALL_BUNDLE=tanzu-cluster-essentials/cluster-essentials-bundle@sha256:ca8584ff2ad4a4cf7a376b72e84fd9ad84ac6f38305767cdfb12309581b521f5
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

