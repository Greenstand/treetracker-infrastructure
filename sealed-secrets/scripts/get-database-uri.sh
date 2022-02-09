#!/bin/bash
set -e

echo $1
PREFIX=$1

echo 'Doctl Context:'
read CONTEXT

echo 'Schema:'
read SCHEMA

doctl auth switch --context $CONTEXT
doctl databases list

echo 'Database Id:'
read DATABASE_ID

USER=$PREFIX$SCHEMA
echo $USER
PASSWORD=`doctl databases user get $DATABASE_ID $USER --format Password --no-header`
_URI=`doctl databases get $DATABASE_ID --format URI --no-header`
HOST=`echo $_URI | sed 's/.*@\(.*\):.*/\1/'`
#echo $HOST
#echo $HOST
URI="postgresql://$USER:$PASSWORD@$HOST:25060/treetracker?ssl=no-verify&schema=$SCHEMA"
