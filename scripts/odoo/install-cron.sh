#!/bin/bash
set -e

# Base directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create cron configuration
create_cron() {
    # Backup daily at 1 AM
    echo "0 1 * * * root $SCRIPT_DIR/backup.sh >> /var/log/odoo-backup.log 2>&1" > /etc/cron.d/odoo-backup

    # Monitor every 5 minutes
    echo "*/5 * * * * root $SCRIPT_DIR/monitor.sh >> /var/log/odoo-monitor.log 2>&1" > /etc/cron.d/odoo-monitor

    # Create log files with proper permissions
    touch /var/log/odoo-backup.log /var/log/odoo-monitor.log
    chmod 640 /var/log/odoo-backup.log /var/log/odoo-monitor.log

    # Set up log rotation
    cat > /etc/logrotate.d/odoo-scripts << EOF
/var/log/odoo-*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
}
EOF
}

# Create monitoring configuration
create_monitoring_config() {
    cat > /etc/odoo/monitor-config.conf << EOF
# Monitoring configuration
ALERT_EMAIL="admin@example.com"
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/HERE"

# Thresholds
DISK_THRESHOLD=90
BACKUP_AGE_HOURS=24
EOF
}

# Main installation
main() {
    # Create directories
    mkdir -p /etc/odoo

    # Install required packages
    apt-get update
    apt-get install -y mailutils curl logrotate

    # Create configurations
    create_cron
    create_monitoring_config

    # Set executable permissions
    chmod +x "$SCRIPT_DIR"/*.sh

    echo "Cron jobs installed successfully!"
    echo "Please edit /etc/odoo/monitor-config.conf to set up your alert preferences."
}

main
