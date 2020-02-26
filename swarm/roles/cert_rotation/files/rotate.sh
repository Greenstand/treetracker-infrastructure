#!/bin/bash

CERT_DIR=/opt/certbot/conf/live/certs/
TIME=$(date)
DOMAIN=
echo "Attempt to rotate cert at $TIME"

echo "Rotating cert to old-certs folder"
RENEWAL_DIR=/opt/certbot/conf/renewal
mv ${RENEWAL_DIR}/certs.conf ${RENEWAL_DIR}/certs_old.conf
ARCHIVE_DIR=/opt/certbot/conf/archive
mv ${ARCHIVE_DIR}/certs ${RENEWAL_DIR}/certs_old
mv $CERT_DIR /opt/certbot/conf/live/certs_old


NODENAME=$(docker node inspect self --format '{{ .Description.Hostname}}')

docker service update --constraint-add "node.hostname == $NODENAME" reverse-proxy

docker service rm certbot-runner || 0

docker service create --name certbot-runner \
  --restart-condition none \
  --detach \
  --mount type=bind,source=/opt/certbot/conf,destination=/etc/letsencrypt \
  --mount type=bind,source=/opt/certbot/lib,destination=/var/lib/letsencrypt \
  --constraint "node.hostname == $NODENAME" \
  certbot/certbot:v0.33.1 \
  certonly --webroot --register-unsafely-without-email --agree-tos \
  --webroot-path /var/lib/letsencrypt/webroot \
  --cert-name certs \
  --force-renewal \
  -d REPLACE_ME

timeout 15 docker service logs -f certbot-runner

docker service rollback reverse-proxy

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

