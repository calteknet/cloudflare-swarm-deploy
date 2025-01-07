#!/bin/bash
set -e

echo "Creating Docker volumes for Odoo deployment..."

# Create volumes
docker volume create odoo18-db-data
docker volume create odoo18-web7-data
docker volume create odoo18-web8-data
docker volume create odoo7-config
docker volume create odoo8-config
docker volume create odoo-addons

# Set up initial configuration directories
mkdir -p /tmp/odoo-config/{odoo7,odoo8}

# Create basic odoo configuration files
cat > /tmp/odoo-config/odoo7/odoo.conf << EOF
[options]
addons_path = /mnt/extra-addons
data_dir = /var/lib/odoo
EOF

cat > /tmp/odoo-config/odoo8/odoo.conf << EOF
[options]
addons_path = /mnt/extra-addons
data_dir = /var/lib/odoo
EOF

# Copy configurations to volumes
docker container create --name dummy -v odoo7-config:/config alpine
docker cp /tmp/odoo-config/odoo7/odoo.conf dummy:/config/
docker rm dummy

docker container create --name dummy -v odoo8-config:/config alpine
docker cp /tmp/odoo-config/odoo8/odoo.conf dummy:/config/
docker rm dummy

# Cleanup
rm -rf /tmp/odoo-config

echo "Volumes and initial configurations created successfully!"
