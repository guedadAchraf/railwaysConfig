# Use official Keycloak image
FROM quay.io/keycloak/keycloak:23.0.7

# Set working directory
WORKDIR /opt/keycloak

# Optional: Copy a realm JSON file (remove if not importing)
# COPY my-realm.json /opt/keycloak/data/import/

# Optional JVM memory settings (adjust as needed)
ENV JAVA_OPTS="-Xms64m -Xmx256m -XX:MetaspaceSize=64m -XX:MaxMetaspaceSize=128m"

# Expose default Keycloak port
EXPOSE 8080

# Start Keycloak in development mode (no import)
ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start-dev"]
