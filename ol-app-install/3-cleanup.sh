#!/bin/bash

unset KUBECONFIG

. ./env

USE_DOCKER=$(which docker 2>/dev/null)
USE_PODMAN=$(which podman 2>/dev/null)

echo "Logging into Openshift"
oc login $OPENSHIFT_API_URL \
    --token=$OPENSHIFT_TOKEN \
    --insecure-skip-tls-verify=true

OPENSHIFT_USERNAME=$(oc whoami)
OPENSHIFT_PASSWORD=$(oc whoami -t)

echo "Logging into Openshift image registry"
if [ ! -z $USE_DOCKER ]
then
  docker login \
      --username $OPENSHIFT_USERNAME \
      --password $OPENSHIFT_PASSWORD \
      $OPENSHIFT_REGISTRY_URL
  if [ $? -ne 0 ]; then "Login failure" ; exit 1 ; fi
elif [ ! -z $USE_PODMAN ]
  podman login \
      --username $OPENSHIFT_USERNAME \
      --password $OPENSHIFT_PASSWORD \
      --tls-verify=false \
      $OPENSHIFT_REGISTRY_URL
  if [ $? -ne 0 ]; then "Login failure" ; exit 1 ; fi
else
  echo "Either docker or podman is needed to run this script"
  exit 1
fi

echo "Deleting Openliberty app"
oc -n $OPENSHIFT_PROJECT delete OpenLibertyApplication appmod --wait=true

echo "Deleting $OPENSHIFT_PROJECT project"
oc delete project $OPENSHIFT_PROJECT --wait=true

#docker logout 2>/dev/null
#podman logout 2>/dev/null
#oc logout 2>/dev/null
