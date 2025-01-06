# Host System Preparation

## Directory Structure
When using host-mounted volumes, the following structure is recommended:

```bash
/opt/odoo/
├── addons/          # Custom addons
├── config/          # Configuration files
│   ├── odoo1/
│   └── odoo2/
└── logs/           # Log files

Permissions
The Odoo container runs with UID 101. Ensure proper permissions:
sudo chown -R 101:101 /opt/odoo
sudo chmod 755 /opt/odoo

Backup Considerations
When using host-mounted volumes:

Include host directories in backup strategy
Consider using bind-mount for read-only directories
Use named volumes for writable data

Security Notes

Restrict directory permissions
Consider SELinux/AppArmor profiles
Regular audit of mounted directories

Usage:
```bash
# Generate configuration
./scripts/odoo/setup-config.sh

# Review generated files in generated-config/
# - docker-compose.yml
# - stack.env
# - prepare-host.sh (if host directories selected)

# Run host preparation if needed
cd generated-config
./prepare-host.sh

# Deploy via Portainer
# Upload the generated files to Portainer stack
