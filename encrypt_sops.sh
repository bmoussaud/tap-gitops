#set -x
echo "SOPS Encrypt $1"
export SOPS_AGE_KEY_FILE=~/dotconfig/tapkey.txt
export SOPS_AGE_KEY=$(cat ${SOPS_AGE_KEY_FILE})
export SOPS_AGE_RECIPIENTS=$(cat ${SOPS_AGE_KEY_FILE} | grep "# public key: " | sed 's/# public key: //')
echo "$1" >>.gitignore
echo " " >>.gitignore
cat .gitignore | sort -u >.gitignore.temp
mv .gitignore.temp .gitignore
sops --encrypt $1 >$1.sops.yaml
