FROM quay.io/keycloak/keycloak:23.0.7

# Set working directory
WORKDIR /opt/keycloak

# Copy realm export file for import during startup
COPY realm-export.json /opt/keycloak/data/import/realm-export.json

# Set environment variables
ENV KEYCLOAK_ADMIN=admin
ENV KEYCLOAK_ADMIN_PASSWORD=admin
ENV KC_DB=postgres
ENV KC_DB_URL=jdbc:postgresql://ep-gentle-pine-a4segogl-pooler.us-east-1.aws.neon.tech/neondb?sslmode=require
ENV KC_DB_USERNAME=neondb_owner
ENV KC_DB_PASSWORD=npg_tkcfe73ALCWK
ENV KC_HOSTNAME_STRICT=false
ENV KC_HTTP_ENABLED=true
ENV KC_PROXY=edge

# JVM memory settings
ENV JAVA_OPTS="-Xms64m -Xmx256m -XX:MetaspaceSize=64m -XX:MaxMetaspaceSize=128m"

# Expose default Keycloak port
EXPOSE 8080

# Start Keycloak in development mode
CMD ["sh", "-c", "/opt/keycloak/bin/kc.sh start-dev --import-realm"]