#!/bin/bash
source .env

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

currentContext="$(kubectl config current-context)"

printf "Kubernetes Context Safety Check...\n"
printf "Current Context: ${CYAN}${currentContext}${NC}\n"

if [[ $currentContext != ${DEV_K8S_CONTEXT} ]]
then
  printf "${RED}Failure${NC}\n"
  printf "Consider changing your k8s context to match the one set in the root .env file.\n"
  printf "Exiting\n"
  exit 1
fi

printf "${GREEN}Success${NC}\n"

