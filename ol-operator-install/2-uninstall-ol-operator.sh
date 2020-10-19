#!/bin/bash

#
# See https://github.com/OpenLiberty/open-liberty-operator/tree/master/deploy/releases/0.5.1#installation
#
echo "Setting environment variables.."
unset KUBECONFIG

. ./env

if [ $OPENSHIFT_API_URL == "api.<SUB_DOMAIN>.<BASE_DOMAIN>:<PORT>" ]; then
      echo "Please set the variables in the env file."
      exit 1
fi

echo "OPERATOR_NAMESPACE=$OPERATOR_NAMESPACE"
echo "WATCH_NAMESPACE=$WATCH_NAMESPACE"

oc login $OPENSHIFT_API_URL \
    --username=$OPENSHIFT_USERNAME \
    --password=$OPENSHIFT_PASSWORD \
    --insecure-skip-tls-verify=true

if [[ ! $? == 0 ]]
then
  echo "oc login failed"
  exit 1
fi

echo "Uninstalling the Openliberty Operator"
curl -L https://raw.githubusercontent.com/OpenLiberty/open-liberty-operator/master/deploy/releases/$OPENLIBERTY_OPERATOR_VERSION/openliberty-app-operator.yaml \
      | sed -e "s/OPEN_LIBERTY_WATCH_NAMESPACE/${WATCH_NAMESPACE}/" \
      | oc delete -n ${OPERATOR_NAMESPACE} -f -

echo "Deleting cluster roles"
curl -L https://raw.githubusercontent.com/OpenLiberty/open-liberty-operator/master/deploy/releases/$OPENLIBERTY_OPERATOR_VERSION/openliberty-app-cluster-rbac.yaml \
      | sed -e "s/OPEN_LIBERTY_OPERATOR_NAMESPACE/${OPERATOR_NAMESPACE}/" \
      | kubectl delete -f -

echo "Deleting CRDs"
oc delete -f https://raw.githubusercontent.com/OpenLiberty/open-liberty-operator/master/deploy/releases/$OPENLIBERTY_OPERATOR_VERSION/openliberty-app-crd.yaml

echo "Deleting ConfigMaps"
oc delete -n ${OPERATOR_NAMESPACE} cm open-liberty-operator
