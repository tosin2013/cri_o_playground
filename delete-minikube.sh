#!/bin/bash
minikube stop || exit $?
minikube delete || exit $?
