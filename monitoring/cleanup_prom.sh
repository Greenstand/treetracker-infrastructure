#!/usr/bin/env bash
helm uninstall --namespace monitoring prom
kubectl delete statefulset loki --namespace monitoring
kubectl delete daemonset loki-promtail --namespace monitoring
