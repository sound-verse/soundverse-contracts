#!/usr/bin/env bash

set -eo pipefail

CONTRACT_TO_DEPLOY=${1}
ENVIRONMENT=${2}

echo "Deploying ${CONTRACT_TO_DEPLOY} to ${ENVIRONMENT}"

if [[ "${CONTRACT_TO_DEPLOY}" == "all" ]] && [[ ! -z ${ENVIRONMENT} ]] ; then
    npx hardhat compile && npx hardhat run scripts/deploy.js --network "${ENVIRONMENT}"
else
    echo "Error:contract to deploy or environment missing"
fi