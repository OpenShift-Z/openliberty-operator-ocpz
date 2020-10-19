#!/bin/bash

unset KUBECONFIG

. ./env

USE_DOCKER=$(which docker 2>/dev/null)
USE_PODMAN=$(which podman 2>/dev/null)
USE_BUILDAH=$(which buildah 2>/dev/null)

echo "Logging into Openshift"
oc login $OPENSHIFT_API_URL \
    --token=$OPENSHIFT_TOKEN \
    --insecure-skip-tls-verify=true

OPENSHIFT_USERNAME=$(oc whoami)
OPENSHIFT_PASSWORD=$(oc whoami -t)
OPENSHIFT_REGISTRY_URL=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')

echo "Logging into Openshift image registry"
if [ ! -z $USE_DOCKER ]; then
  docker login \
      --username $OPENSHIFT_USERNAME \
      --password $OPENSHIFT_PASSWORD \
      $OPENSHIFT_REGISTRY_URL
  if [ $? -ne 0 ]; then "Login failure" ; exit 1 ; fi
elif [ ! -z $USE_PODMAN ]; then
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

echo "Creating $OPENSHIFT_PROJECT project"
oc new-project $OPENSHIFT_PROJECT

echo "Building the container image"
if [ ! -z $USE_DOCKER ]; then
  docker build \
    -t ${OPENSHIFT_REGISTRY_URL}/$OPENSHIFT_PROJECT/app-modernization:v1.0.0 .
  if [ $? -ne 0 ]; then "Build failure" ; exit 1 ; fi
elif [ ! -z $USE_BUILDAH ]; then
  buildah build-using-dockerfile \
    -t ${OPENSHIFT_REGISTRY_URL}/$OPENSHIFT_PROJECT/app-modernization:v1.0.0 .
  if [ $? -ne 0 ]; then "Build failure" ; exit 1 ; fi
else
  echo "Either docker or buildah must be installed to build images."
  exit 1
fi

echo "Pushing the container image to the Openshift image registrry"
if [ ! -z $USE_DOCKER ]; then
  docker push \
    ${OPENSHIFT_REGISTRY_URL}/${OPENSHIFT_PROJECT}/app-modernization:v1.0.0
  if [ $? -ne 0 ]; then "Push failure" ; exit 1 ; fi
elif [ ! -z $USE_PODMAN ]; then
  podman push --tls-verify=false \
    ${OPENSHIFT_REGISTRY_URL}/${OPENSHIFT_PROJECT}/app-modernization:v1.0.0
  if [ $? -ne 0 ]; then "Push failure" ; exit 1 ; fi
else
  echo "Either docker or podman must be installed to push images."
  exit 1 
fi

#docker logout 2>/dev/null
#podman logout 2>/dev/null
#oc logout 2>/dev/null