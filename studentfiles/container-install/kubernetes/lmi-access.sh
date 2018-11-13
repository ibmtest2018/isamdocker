#!/bin/bash
# Get docker container ID for isamconfig container
ISAMCONFIG="$(kubectl get --no-headers=true pods -l app=isamconfig -o custom-columns=:metadata.name)"

echo "Setting up tunnel to LMI on isamconfig pod."
echo "Access LMI at https://localhost:9443"
echo "Quit this process to close tunnel."
kubectl port-forward ${ISAMCONFIG} 9443
