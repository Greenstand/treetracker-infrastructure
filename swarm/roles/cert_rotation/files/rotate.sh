#!/bin/bash

CERT_DIR=/opt/certbot/conf/live/certs/
TIME=$(date)
echo "Attempt to rotate cert at $TIME"

if [[ ! -f ${CERT_DIR}/fullchain.pem ]]; then
  echo "Cert not updated, exiting"
  exit 0
fi

echo "Recreating Temp secrets"
docker secret rm TEMP-fullchain.pem
docker secret rm TEMP-privkey.pem
docker secret create TEMP-fullchain.pem ${CERT_DIR}/fullchain.pem
docker secret create TEMP-privkey.pem ${CERT_DIR}/privkey.pem


echo "Rotating in temporary secrets"
docker service update \
  --secret-rm fullchain.pem --secret-rm privkey.pem \
  --secret-add source=TEMP-fullchain.pem,target=fullchain.pem \
  --secret-add source=TEMP-privkey.pem,target=privkey.pem \
  reverse-proxy

echo "Updating old secrets"
docker secret rm fullchain.pem
docker secret rm privkey.pem
docker secret create fullchain.pem ${CERT_DIR}/fullchain.pem
docker secret create privkey.pem ${CERT_DIR}/privkey.pem

echo "Rotate secrets back in"
docker service update \
  --secret-rm TEMP-fullchain.pem --secret-rm TEMP-privkey.pem  \
  --secret-add fullchain.pem --secret-add privkey.pem reverse-proxy

docker secret rm TEMP-fullchain.pem
docker secret rm TEMP-privkey.pem

echo "Rotating cert to old-certs folder"
OLD_CERT_DIR=/opt/certbot/conf/live/old_certs
rm -rf $OLD_CERT_DIR
mv $CERT_DIR $OLD_CERT_DIR
