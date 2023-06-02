#!/bin/sh 

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source ${__dir}/create-secret.sh -r aws-key-id -k accessKeyId


