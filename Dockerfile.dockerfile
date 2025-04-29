FROM quay.io/keycloak/keycloak:23.0.7
COPY Ahssane-voyage-realm.json /opt/keycloak/data/import/
ENV KEYCLOAK_ADMIN=admin
ENV KEYCLOAK_ADMIN_PASSWORD=${ADMIN_PASSWORD}
ENV KC_DB=postgres
ENV KC_DB_URL=${DATABASE_URL}
ENV KC_DB_USERNAME=${DB_USER}
ENV KC_DB_PASSWORD=${DB_PASSWORD}
ENV KC_HOSTNAME=${RAILWAY_STATIC_URL}
ENV KC_PROXY=edge
ENV KC_IMPORT=/opt/keycloak/data/import/Ahssane-voyage-realm.json
RUN /opt/keycloak/bin/kc.sh build --import-realm
CMD ["start"]