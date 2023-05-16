#!/usr/bin/env bash
kubectl delete clusterrole solr-operator-role solr-operator-zookeeper-operator
kubectl delete clusterrolebinding solr-operator-rolebinding solr-operator-zookeeper-operator
kubectl create -f https://solr.apache.org/operator/downloads/crds/v0.7.0/all-with-dependencies.yaml
