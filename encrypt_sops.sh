export SOPS_AGE_KEY_FILE=~/.dotconfig/tapkey.txt
export SOPS_AGE_KEY=$(cat ${SOPS_AGE_KEY_FILE})
export SOPS_AGE_RECIPIENTS=`cat ${SOPS_AGE_KEY_FILE} | grep "# public key: " | sed 's/# public key: //'`
sops --encrypt $1 > $1.sops.yaml