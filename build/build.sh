#!/bin/bash
if [[ -z "$1" ]]; then
  echo "Branch name is required as first argument"
  exit 1
fi
BRANCH=$1
DIR=$(dirname "$0")
SRC_DIR="${DIR}/src"
MOBILE_API_DIR=$SRC_DIR"/mobile-api"
MOBILE_API_CONTAINER_NAME="treetracker-mobile-api"
TIMESTAMP=`date +"%s"`

rm -Rf $MOBILE_API_DIR
git clone --depth 1 git@github.com:Greenstand/treetracker-mobile-api.git -b $BRANCH $MOBILE_API_DIR 
cd $MOBILE_API_DIR
git config advice.detachedHead false
git checkout $TAG
SHA=`git rev-parse --short HEAD`


# images names will be repo + branch + build id + short_sha
docker build . -f ../../docker/TreetrackerMobileApi.Dockerfile -t $MOBILE_API_CONTAINER_NAME:$BRANCH-$TIMESTAMP-$SHA -t $MOBILE_API_CONTAINER_NAME:latest

