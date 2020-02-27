#!/bin/bash
set -e

if [ "$1" = "" ]
then
  echo "Usage: $0 <env>"
  exit
fi
ENV=$1

find ./build/ -name *.spec.js -exec rm {} \;

cp ../config/$ENV/pipeline-consumer/* build/treetracker-database/pipeline/consumer/config/
cp ../config/$ENV/pipeline-microservice/* build/treetracker-database/pipeline/microservice/config/
cp ../config/$ENV/pipeline-cron/* build/treetracker-database/pipeline/cron/config/

cd build/treetracker-database/pipeline/consumer/
npm ci &
cd ../../../../
cd build/treetracker-database/pipeline/microservice/
npm ci &
cd ../../../../
cd build/treetracker-database/pipeline/cron/
npm ci &
cd ../../../../

wait

tar -cvzf build/treetracker-pipeline-consumer.tar.gz --directory build/treetracker-database/pipeline/consumer/ . &
tar -cvzf build/treetracker-pipeline-microservice.tar.gz --directory build/treetracker-database/pipeline/microservice/ . &
tar -cvzf build/treetracker-pipeline-cron.tar.gz --directory build/treetracker-database/pipeline/cron/ . &

wait

echo "Done"
