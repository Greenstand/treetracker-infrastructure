#!/bin/sh

set -e

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source ${__dir}/get-database-uri.sh m_
echo $URI

source ${__dir}/create-secret.sh -r database-migration-connection -k db -s $URI

