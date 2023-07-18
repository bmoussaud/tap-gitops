#!/usr/bin/env bash
source ./env.sh ${1} ${2}
cd ./clusters/${3}
./tanzu-sync/scripts/configure.sh