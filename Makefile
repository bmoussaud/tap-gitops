SOPS_AGE_KEY_FILE=~/.dotconfig/tapkey.txt
CLUSTER_NAME=aks-eu-tap-6
REGISTRY_NAME=$(shell echo $(subst -,,$(CLUSTER_NAME)-Registry) | tr '[:upper:]' '[:lower:]') 

encrypt:
	SOPS_AGE_RECIPIENTS=`cat ${SOPS_AGE_KEY_FILE} | grep "# public key: " | sed 's/# public key: //'`  && echo ${SOPS_AGE_RECIPIENTS} && sops --encrypt clusters/$(CLUSTER_NAME)/cluster-config/values/tap-sensitive-values.yaml > clusters/$(CLUSTER_NAME)/cluster-config/values/tap-sensitive-values.sops.yaml


decrytp:
	export SOPS_AGE_KEY_FILE=$(SOPS_AGE_KEY_FILE) && sops --decrypt clusters/$(CLUSTER_NAME)/cluster-config/values/tap-sensitive-values.sops.yaml

deploy:	
	./env.sh $(strip $(REGISTRY_NAME)) $(SOPS_AGE_KEY_FILE) && cd ./clusters/${CLUSTER_NAME}/ && ./tanzu-sync/scripts/deploy.sh

undeploy:
	kapp delete -a tanzu-sync