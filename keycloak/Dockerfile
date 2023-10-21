FROM quay.io/keycloak/keycloak:latest as builder

# Copy the theme
COPY ./themes/treetracker /opt/keycloak/themes/treetracker


ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
