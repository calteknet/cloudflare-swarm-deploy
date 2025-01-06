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
      - odoo-addons:/mnt/extra-addons
    environment:
      - HOST=\${ODOO_HOST}
      - PORT=\${ODOO_PORT}
      - USER=\${ODOO_USER}
      - PASSWORD=\${ODOO_PASSWORD}
      - "DB_FILTER=^\${DOMAIN1}.*$$"
    networks:
      - traefik-public
      - odoo-internal
    deploy:
      mode: replicated
      replicas: 1
      resources:
        limits:
          memory: \${ODOO_MEMORY}
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.odoo7.rule=Host(\`\${DOMAIN1}\`)"
        - "traefik.http.services.odoo7.loadbalancer.server.port=8069"

volumes:
  odoo18-db-data:
  odoo18-web7-data:
  odoo7-config:
  odoo-addons:

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
}

# Run main function
main