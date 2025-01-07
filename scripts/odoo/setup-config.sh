cd ~/docker/cloudflare-swarm-deploy/scripts/odoo
cat > setup-config.sh << 'EOF'
#!/bin/bash
set -e

# Configuration output paths
OUTPUT_DIR="generated-config"
mkdir -p $OUTPUT_DIR

# Interactive configuration function
configure() {
    echo "=== Odoo Stack Configuration Setup ==="
    echo

    # Database configuration
    read -p "PostgreSQL Username [odoo]: " pg_user
    PG_USER=${pg_user:-odoo}
    
    read -s -p "PostgreSQL Password: " pg_pass
    echo
    PG_PASS=${pg_pass:-$(openssl rand -base64 12)}

    # Domain configuration
    read -p "Primary Domain (e.g., odoo.example.com): " domain1
    read -p "Secondary Domain (e.g., erp.example.com): " domain2

    # Resource limits
    read -p "PostgreSQL Memory Limit (GB) [4]: " pg_memory
    PG_MEMORY=${pg_memory:-4}

    read -p "Odoo Instance Memory Limit (GB) [2]: " odoo_memory
    ODOO_MEMORY=${odoo_memory:-2}

    # Addons configuration
    read -p "Configure shared addons directory? [Y/n]: " config_addons
    if [[ ${config_addons,,} != "n" ]]; then
        read -p "Addons Directory [/opt/odoo/addons]: " ADDONS_DIR
        ADDONS_DIR=${ADDONS_DIR:-/opt/odoo/addons}
        
        # Create directories if they don't exist
        mkdir -p "$OUTPUT_DIR/setup"
        cat > "$OUTPUT_DIR/setup/prepare-directories.sh" << SETUPEOF
#!/bin/bash
sudo mkdir -p ${ADDONS_DIR}
sudo chown -R 101:101 ${ADDONS_DIR}
sudo chmod 755 ${ADDONS_DIR}
SETUPEOF
        chmod +x "$OUTPUT_DIR/setup/prepare-directories.sh"
    fi
}

# Generate stack.env
generate_env() {
    cat > "$OUTPUT_DIR/stack.env" << ENVEOF
POSTGRES_USER=$PG_USER
POSTGRES_PASSWORD=$PG_PASS
POSTGRES_DB=postgres
ODOO_HOST=postgres
ODOO_PORT=5432
ODOO_USER=$PG_USER
ODOO_PASSWORD=$PG_PASS
DOMAIN1=$domain1
DOMAIN2=$domain2
PG_MEMORY=${PG_MEMORY}G
ODOO_MEMORY=${ODOO_MEMORY}G
ADDONS_DIR=${ADDONS_DIR:-/opt/odoo/addons}
ENVEOF
}

# Generate docker-compose.yml
generate_compose() {
    cat > "$OUTPUT_DIR/docker-compose.yml" << COMPOSEEOF
version: '3.8'
services:
  postgres:
    image: postgres:17
    environment:
      - POSTGRES_USER=\${POSTGRES_USER}
      - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
      - POSTGRES_DB=\${POSTGRES_DB}
      - PGDATA=/var/lib/postgresql/data/pgdata
    command: >
      postgres 
      -c max_connections=500
      -c shared_buffers=1024MB
      -c work_mem=32MB
    volumes:
      - odoo18-db-data:/var/lib/postgresql/data/pgdata
    networks:
      odoo-internal:
        aliases:
          - postgres
    deploy:
      placement:
        constraints:
          - node.role == manager
      resources:
        limits:
          memory: \${PG_MEMORY}
      restart_policy:
        condition: on-failure
        delay: 5s

  odoo7:
    image: odoo:18.0
    depends_on:
      - postgres
    volumes:
      - odoo18-web7-data:/var/lib/odoo
      - odoo7-config:/etc/odoo
      - \${ADDONS_DIR}:/mnt/extra-addons:ro
    environment:
      - HOST=\${ODOO_HOST}
      - PORT=\${ODOO_PORT}
      - USER=\${ODOO_USER}
      - PASSWORD=\${ODOO_PASSWORD}
      - DB_FILTER=^\\${DOMAIN1}.*$
    networks:
      - traefik-public
      - odoo-internal
    deploy:
      mode: replicated
      replicas: 1
      resources:
        limits:
          memory: \${ODOO_MEMORY}
      update_config:
        parallelism: 1
        delay: 10s
        order: start-first
      restart_policy:
        condition: on-failure
        delay: 5s
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.odoo7.rule=Host(\`\${DOMAIN1}\`)"
        - "traefik.http.services.odoo7.loadbalancer.server.port=8069"
        - "traefik.http.services.odoo7.loadbalancer.sticky.cookie=true"
        - "traefik.http.services.odoo7.loadbalancer.sticky.cookie.name=odoo_session"
        - "traefik.http.services.odoo7.loadbalancer.healthcheck.path=/web/health"
        - "traefik.http.services.odoo7.loadbalancer.healthcheck.interval=10s"
        - "traefik.http.services.odoo7.loadbalancer.healthcheck.timeout=5s"

  odoo8:
    image: odoo:18.0
    depends_on:
      - postgres
    volumes:
      - odoo18-web8-data:/var/lib/odoo
      - odoo8-config:/etc/odoo
      - \${ADDONS_DIR}:/mnt/extra-addons:ro
    environment:
      - HOST=\${ODOO_HOST}
      - PORT=\${ODOO_PORT}
      - USER=\${ODOO_USER}
      - PASSWORD=\${ODOO_PASSWORD}
      - DB_FILTER=^\\${DOMAIN2}.*$
    networks:
      - traefik-public
      - odoo-internal
    deploy:
      mode: replicated
      replicas: 1
      resources:
        limits:
          memory: \${ODOO_MEMORY}
      update_config:
        parallelism: 1
        delay: 10s
        order: start-first
      restart_policy:
        condition: on-failure
        delay: 5s
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.odoo8.rule=Host(\`\${DOMAIN2}\`)"
        - "traefik.http.services.odoo8.loadbalancer.server.port=8069"
        - "traefik.http.services.odoo8.loadbalancer.sticky.cookie=true"
        - "traefik.http.services.odoo8.loadbalancer.sticky.cookie.name=odoo_session"
        - "traefik.http.services.odoo8.loadbalancer.healthcheck.path=/web/health"
        - "traefik.http.services.odoo8.loadbalancer.healthcheck.interval=10s"
        - "traefik.http.services.odoo8.loadbalancer.healthcheck.timeout=5s"

volumes:
  odoo18-db-data:
  odoo18-web7-data:
  odoo18-web8-data:
  odoo7-config:
  odoo8-config:

networks:
  odoo-internal:
    driver: overlay
    attachable: true
    internal: true
  traefik-public:
    external: true
COMPOSEEOF
}

# Main execution
main() {
    echo "Starting Odoo configuration setup..."
    mkdir -p "$OUTPUT_DIR"
    
    configure
    generate_env
    generate_compose

    echo
    echo "Configuration generated in $OUTPUT_DIR/"
    echo "Files ready for Portainer deployment:"
    echo "- $OUTPUT_DIR/stack.env"
    echo "- $OUTPUT_DIR/docker-compose.yml"
    if [ -f "$OUTPUT_DIR/setup/prepare-directories.sh" ]; then
        echo "- $OUTPUT_DIR/setup/prepare-directories.sh (run this first on host)"
    fi
}

# Run main function
main
EOF

chmod +x setup-config.sh
