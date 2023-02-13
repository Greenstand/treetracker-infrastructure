#!/bin/sh 

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source ${__dir}/create-secret.sh -r airflow-database-connection -k database-password


