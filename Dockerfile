FROM quay.io/keycloak/keycloak:23.0.7

# Copy realm configuration
COPY Ahssane-voyage-realm.json /opt/keycloak/data/import/Ahssane-voyage-realm.json

# Set environment variables
ENV KC_DB=postgres
ENV KC_DB_URL=jdbc:postgresql://ep-gentle-pine-a4segogl-pooler.us-east-1.aws.neon.tech:5432/neondb?sslmode=require
ENV KC_DB_USERNAME=neondb_owner
ENV KC_DB_PASSWORD=npg_tkcfe73ALCWK
ENV KEYCLOAK_ADMIN=admin
ENV KEYCLOAK_ADMIN_PASSWORD=admin123
ENV KC_PROXY=edge
ENV KC_IMPORT=/opt/keycloak/data/import/Ahssane-voyage-realm.json
ENV KC_DB_POOL_INITIAL_SIZE=2
ENV KC_DB_POOL_MIN_SIZE=2
ENV KC_DB_POOL_MAX_SIZE=5
ENV KC_HOSTNAME_STRICT=false
ENV KC_HTTP_ENABLED=true
ENV JAVA_OPTS="-Xms64m -Xmx256m -XX:MetaspaceSize=64m -XX:MaxMetaspaceSize=128m"

# Expose the port
EXPOSE 8080

# Start Keycloak
ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start-dev", "--import-realm", "--optimized-build=false"]