#
#RUN /opt/keycloak/bin/kc.sh build
#
#FROM quay.io/keycloak/keycloak:22.0.4
#ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]

FROM quay.io/keycloak/keycloak:22.0.4 as builder
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# Configure a database vendor
ENV KC_DB=postgres

WORKDIR /opt/keycloak

# Copy the theme
COPY ./themes/treetracker /opt/keycloak/themes/treetracker
#RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:latest
COPY --from=builder /opt/keycloak/ /opt/keycloak/

ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start-dev"]
