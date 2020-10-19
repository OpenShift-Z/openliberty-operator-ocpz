#!/bin/bash

oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')

# test login (switch to docker and remove the --tls-verify)
podman login -u $(oc whoami) -p $(oc whoami -t) --tls-verify=false $HOST