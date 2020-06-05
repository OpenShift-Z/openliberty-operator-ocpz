#!/bin/bash

unset KUBECONFIG

. ./env

USE_DOCKER=$(which docker 2>/dev/null)

echo "Logging into Openshift"
oc login $OPENSHIFT_API_URL \
    --username=$OPENSHIFT_USERNAME \
    --password=$OPENSHIFT_PASSWORD \
    --insecure-skip-tls-verify=true

echo "Logging into Openshift image registry"
if [ ! -z $USE_DOCKER ]
then
  docker login \
      --username $OPENSHIFT_USERNAME \
      --password $(oc whoami -t) \
      $OPENSHIFT_REGISTRY_URL
else
  podman login \
    --username $OPENSHIFT_USERNAME \
    --password $(oc whoami -t) \
    --tls-verify=false \
    $OPENSHIFT_REGISTRY_URL
fi

echo "Deleting Openliberty app"
oc -n $OPENSHIFT_PROJECT delete OpenLibertyApplication appmod

sleep 5

echo "Deleting $OPENSHIFT_PROJECT project"
oc delete project $OPENSHIFT_PROJECT

