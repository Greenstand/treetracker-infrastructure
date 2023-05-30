#!/usr/bin/env bash
kubectl delete clusterrole solr-operator-role solr-operator-zookeeper-operator
kubectl delete clusterrolebinding solr-operator-rolebinding solr-operator-zookeeper-operator
