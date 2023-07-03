SOPS_AGE_KEY_FILE=~/.dotconfig/tapkey.txt
CLUSTER=aks-eu-tap-6
encrypt:
	SOPS_AGE_RECIPIENTS=`cat ${SOPS_AGE_KEY_FILE} | grep "# public key: " | sed 's/# public key: //'`  && echo ${SOPS_AGE_RECIPIENTS} && sops --encrypt clusters/$(CLUSTER)/cluster-config/values/tap-sensitive-values.yaml > clusters/$(CLUSTER)/cluster-config/values/tap-sensitive-values.sops.yaml


decrytp:
	export SOPS_AGE_KEY_FILE=$(SOPS_AGE_KEY_FILE) && sops --decrypt clusters/$(CLUSTER)/cluster-config/values/tap-sensitive-values.sops.yaml