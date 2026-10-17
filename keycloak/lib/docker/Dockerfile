#
#RUN /opt/keycloak/bin/kc.sh build
#
#FROM quay.io/keycloak/keycloak:22.0.4
#ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]

# Keycloak version: dev runs 23.0.3, prod runs 22.0.4. Pass --build-arg KC_VERSION=... at build time.
ARG KC_VERSION=23.0.3
FROM quay.io/keycloak/keycloak:${KC_VERSION} AS builder
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# Configure a database vendor
ENV KC_DB=postgres

WORKDIR /opt/keycloak

# Copy the theme
COPY ./themes/treetracker /opt/keycloak/themes/treetracker
#RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:${KC_VERSION}
COPY --from=builder /opt/keycloak/ /opt/keycloak/

ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start-dev"]
