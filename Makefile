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

apply-secret-store:
	kubectl apply -f  ~/.azure/rbac/vault-micropets.yaml 
