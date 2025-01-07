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

   # Domain and DB filter configuration
   read -p "Primary Domain (e.g., odoo.example.com): " domain1
   read -p "DB Filter for Primary Domain [${domain1}.*]: " db_filter1
   DB_FILTER1=${db_filter1:-${domain1}.*}
   
   read -p "Secondary Domain (e.g., erp.example.com): " domain2
   read -p "DB Filter for Secondary Domain [${domain2}.*]: " db_filter2
   DB_FILTER2=${db_filter2:-${domain2}.*}

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
       
       mkdir -p "$OUTPUT_DIR/setup"
       cat > "$OUTPUT_DIR/setup/prepare-directories.sh" << 'ENDSETUP'
#!/bin/bash
sudo mkdir -p ${ADDONS_DIR}
sudo chown -R 101:101 ${ADDONS_DIR}
sudo chmod 755 ${ADDONS_DIR}
ENDSETUP
       chmod +x "$OUTPUT_DIR/setup/prepare-directories.sh"
   fi
}

# Generate stack.env
generate_env() {
   cat > "$OUTPUT_DIR/stack.env" << ENDENV
POSTGRES_USER=$PG_USER
POSTGRES_PASSWORD=$PG_PASS
POSTGRES_DB=postgres
ODOO_HOST=postgres
ODOO_PORT=5432
ODOO_USER=$PG_USER
ODOO_PASSWORD=$PG_PASS
DOMAIN1=$domain1
DOMAIN2=$domain2
DB_FILTER1=$DB_FILTER1
DB_FILTER2=$DB_FILTER2
PG_MEMORY=${PG_MEMORY}G
ODOO_MEMORY=${ODOO_MEMORY}G
ADDONS_DIR=${ADDONS_DIR:-/opt/odoo/addons}
ENDENV
}

# Generate docker-compose.yml
generate_compose() {
   cat > "$OUTPUT_DIR/docker-compose.yml" << ENDCOMPOSE
version: '3.8'
services:
 postgres:
   image: postgres:17
   environment:
     - POSTGRES_USER=\${POSTGRES_USER}
     - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
     - POSTGRES_DB=\${POSTGRES_DB}
     - PGDATA=/var/lib/postgresql/data/pgdata
   command: postgres -c max_connections=500 -c shared_buffers=1024MB -c work_mem=32MB
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

 odoo0:
   image: odoo:18.0
   depends_on:
     - postgres
   volumes:
     - odoo18-web0-data:/var/lib/odoo
     - odoo0-config:/etc/odoo
     - \${ADDONS_DIR}:/mnt/extra-addons:ro
   environment:
     - HOST=\${ODOO_HOST}
     - PORT=\${ODOO_PORT}
     - USER=\${ODOO_USER}
     - PASSWORD=\${ODOO_PASSWORD}
     - "DB_FILTER=^$${DB_FILTER1}$$"
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
       - "traefik.http.routers.odoo0.rule=Host(\`\${DOMAIN1}\`)"
       - "traefik.http.services.odoo0.loadbalancer.server.port=8069"
       - "traefik.http.services.odoo0.loadbalancer.sticky.cookie=true"
       - "traefik.http.services.odoo0.loadbalancer.sticky.cookie.name=odoo_session"
       - "traefik.http.services.odoo0.loadbalancer.healthcheck.path=/web/health"
       - "traefik.http.services.odoo0.loadbalancer.healthcheck.interval=10s"
       - "traefik.http.services.odoo0.loadbalancer.healthcheck.timeout=5s"

 odoo1:
   image: odoo:18.0
   depends_on:
     - postgres
   volumes:
     - odoo18-web1-data:/var/lib/odoo
     - odoo1-config:/etc/odoo
     - \${ADDONS_DIR}:/mnt/extra-addons:ro
   environment:
     - HOST=\${ODOO_HOST}
     - PORT=\${ODOO_PORT}
     - USER=\${ODOO_USER}
     - PASSWORD=\${ODOO_PASSWORD}
     - "DB_FILTER=^$${DB_FILTER2}$$"
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
       - "traefik.http.routers.odoo1.rule=Host(\`\${DOMAIN2}\`)"
       - "traefik.http.services.odoo1.loadbalancer.server.port=8069"
       - "traefik.http.services.odoo1.loadbalancer.sticky.cookie=true"
       - "traefik.http.services.odoo1.loadbalancer.sticky.cookie.name=odoo_session"
       - "traefik.http.services.odoo1.loadbalancer.healthcheck.path=/web/health"
       - "traefik.http.services.odoo1.loadbalancer.healthcheck.interval=10s"
       - "traefik.http.services.odoo1.loadbalancer.healthcheck.timeout=5s"

volumes:
 odoo18-db-data:
 odoo18-web0-data:
 odoo18-web1-data:
 odoo0-config:
 odoo1-config:

networks:
 odoo-internal:
   driver: overlay
   attachable: true
   internal: true
 traefik-public:
   external: true
ENDCOMPOSE
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
