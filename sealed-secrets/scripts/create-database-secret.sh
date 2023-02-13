#!/bin/sh

set -e

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source ${__dir}/get-database-uri.sh s_
echo $URI

source ${__dir}/create-secret.sh -r database-connection -k db -s $URI

