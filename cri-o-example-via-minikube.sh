#!/bin/bash
# TO install minikube https://kubernetes.io/docs/tasks/tools/install-minikube/
echo "starting minikube"
minikube start --container-runtime crio || exit $?

echo "Checking the CRI-O Runtime is running."
minikube logs | grep cri-o

echo "Launching a test nginx container "
kubectl run nginx --image=docker.io/nginx

echo "confirming that deployment is using the cri-o runtime"
kubectl describe pods/$(kubectl get pods | grep nginx | awk '{print $1}')

echo "Confirming Docker dameon is no running"
minikube ssh "docker ps"

echo "testing NGINX Endpoint within minikube cluster"
NGINXIP=$(kubectl describe pods/$(kubectl get pods | grep nginx | awk '{print $1}') | grep IP | awk '{print $2}')
minikube ssh "curl -I ${NGINXIP}"

echo "view running containers via runc command"
 minikube ssh "sudo runc list "
