SOPS_AGE_KEY_FILE=~/.dotconfig/tapkey.txt
CLUSTER_NAME=aks-eu-tap-6
REGISTRY_NAME=$(shell echo $(subst -,,$(CLUSTER_NAME)-Registry) | tr '[:upper:]' '[:lower:]') 

new-instance:
	./setup-repo.sh $(CLUSTER_NAME) sops	
	touch clusters/$(CLUSTER_NAME)/cluster-config/values/tap-non-sensitive-values.yaml

configure:
	source ./env.sh $(strip $(REGISTRY_NAME)) $(SOPS_AGE_KEY_FILE) $(CLUSTER_NAME) && cd ./clusters/$(CLUSTER_NAME) && ./tanzu-sync/scripts/configure.sh

gen-sensitive-values:
	source ./env.sh $(strip $(REGISTRY_NAME)) $(SOPS_AGE_KEY_FILE) $(CLUSTER_NAME) &&  ./gen-sensitive-values.sh

encrypt:
	source ./env.sh $(strip $(REGISTRY_NAME)) $(SOPS_AGE_KEY_FILE) $(CLUSTER_NAME)  && sops --encrypt clusters/$(CLUSTER_NAME)/cluster-config/values/tap-sensitive-values.yaml > clusters/$(CLUSTER_NAME)/cluster-config/values/tap-sensitive-values.sops.yaml

decrypt:
	export SOPS_AGE_KEY_FILE=$(SOPS_AGE_KEY_FILE) && sops --decrypt clusters/$(CLUSTER_NAME)/cluster-config/values/tap-sensitive-values.sops.yaml

deploy:		
	source ./env.sh $(strip $(REGISTRY_NAME)) $(SOPS_AGE_KEY_FILE) $(CLUSTER_NAME) && cd ./clusters/$(CLUSTER_NAME) && ./tanzu-sync/scripts/deploy.sh

undeploy:
	kapp delete -a tanzu-sync

kick:
	kctrl app kick -a sync -n tanzu-sync -yes

tap-gui-ip:
	IP=$(shell kubectl get HTTPProxy  -n tap-gui tap-gui -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
	FQDN=$(shell kubectl get HTTPProxy  -n tap-gui tap-gui -o=jsonpath='{.spec.virtualhost.fqdn}')
	
tap-update-dns:
	./update_tap_dns.sh

encrypt-secret-store:
	SOPS_AGE_RECIPIENTS=`cat ${SOPS_AGE_KEY_FILE} | grep "# public key: " | sed 's/# public key: //'` && sops --encrypt  --encrypted-regex '^(data|stringData|tenantId)$$' ~/.azure/rbac/vault-micropets.yaml >  clusters/$(CLUSTER_NAME)/cluster-config/values/cluster-secret-store.yaml

apply-secret-store:
	kubectl apply -f  ~/.azure/rbac/vault-micropets.yaml 
