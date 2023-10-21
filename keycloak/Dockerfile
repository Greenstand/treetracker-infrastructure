##FROM quay.io/keycloak/keycloak:latest as builder
#FROM quay.io/keycloak/keycloak:22.0.4 as builder
#
## Copy the theme
#COPY ./themes/treetracker /opt/keycloak/themes/treetracker
#
#RUN /opt/keycloak/bin/kc.sh build
#
#FROM quay.io/keycloak/keycloak:22.0.4
#ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]

FROM quay.io/keycloak/keycloak:latest as builder

# Configure a database vendor
ENV KC_DB=postgres

WORKDIR /opt/keycloak
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:latest
COPY --from=builder /opt/keycloak/ /opt/keycloak/

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
