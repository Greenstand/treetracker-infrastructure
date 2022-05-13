#!/bin/bash
helm uninstall elasticsearch
helm uninstall elasticsearch-exporter
helm uninstall kibana
helm uninstall filebeat
helm uninstall elasticsearch-curator
kubectl delete pvc elasticsearch-master-elasticsearch-master-0 elasticsearch-master-elasticsearch-master-1 elasticsearch-master-elasticsearch-master-2
