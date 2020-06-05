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

echo "Creating $OPENSHIFT_PROJECT project"
oc new-project $OPENSHIFT_PROJECT

echo "Building the container image"
if [ ! -z $USE_DOCKER ]
then
  docker build \
    -t ${OPENSHIFT_REGISTRY_URL}/$OPENSHIFT_PROJECT/app-modernization:v1.0.0 \
    .
else
  buildah build-using-dockerfile \
    -t ${OPENSHIFT_REGISTRY_URL}/$OPENSHIFT_PROJECT/app-modernization:v1.0.0 \
    .
fi

echo "Pushing the container image to the Openshift image registrry"
if [ ! -z $USE_DOCKER ]
then
  docker push \
    ${OPENSHIFT_REGISTRY_URL}/${OPENSHIFT_PROJECT}/app-modernization:v1.0.0
else
  podman push --tls-verify=false \
    ${OPENSHIFT_REGISTRY_URL}/${OPENSHIFT_PROJECT}/app-modernization:v1.0.0
fi

