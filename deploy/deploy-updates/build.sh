#!/bin/bash
set -e

if [ "$1" = "" ]
then
  echo "Usage: $0 <env>"
  exit
fi
ENV=$1

\rm -Rf build/*

ansible localhost -m git -a "repo=git@github.com:Greenstand/treetracker-database.git dest=build/treetracker-database force=yes depth=1"

if [ "$ENV" = "prod" ]
then
  cd build/treetracker-database/pipeline/microservice/
#  npm version patch
#  git push --tags origin master
#  git push -f origin master:production
  cd ../../

  cd build/treetracker-database/pipeline/consumer/
#  npm version patch
#  git push --tags origin master
#  git push -f origin master:production
  cd ../../
fi

./package.sh $ENV


