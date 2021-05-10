#! /bin/bash 

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source ${__dir}/create-secret.sh -r sqs-url -k sqsUrl


