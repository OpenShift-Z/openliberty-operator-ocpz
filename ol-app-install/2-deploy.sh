#!/bin/bash

unset KUBECONFIG

. ./env

echo "Logging into Openshift"
oc login $OPENSHIFT_API_URL \
    --token=$OPENSHIFT_TOKEN \
    --insecure-skip-tls-verify=true

echo "Creating Openliberty Custom Resource Definition"
oc -n $OPENSHIFT_PROJECT create -f app-mod-withroute_cr.yaml

#oc logout 2>/dev/null