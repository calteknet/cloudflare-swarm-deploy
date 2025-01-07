#!/bin/bash
set -e

# Base directories
CONFIG_DIR="/etc/odoo"
LOG_DIR="/var/log/odoo"
SCRIPT_DIR="/usr/local/bin"

# Create installation script
cat > install-monitor.sh << 'EOF'
#!/bin/bash
set -e

# Create directories
sudo mkdir -p "${CONFIG_DIR}"
sudo mkdir -p "${LOG_DIR}"

# Copy configuration
sudo cp monitor-config.conf "${CONFIG_DIR}/"
sudo cp monitor.sh "${SCRIPT_DIR}/odoo-monitor"
sudo cp backup.sh "${SCRIPT_DIR}/odoo-backup"
sudo cp restore.sh "${SCRIPT_DIR}/odoo-restore"

# Set permissions
sudo chmod 600 "${CONFIG_DIR}/monitor-config.conf"
sudo chmod 755 "${SCRIPT_DIR}/odoo-monitor"
sudo chmod 755 "${SCRIPT_DIR}/odoo-backup"
sudo chmod 755 "${SCRIPT_DIR}/odoo-restore"

# Create log rotation configuration
sudo cat > /etc/logrotate.d/odoo-monitor << 'LOGROTATE'
/var/log/odoo/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
}
LOGROTATE

# Create systemd service for monitoring
sudo cat > /etc/systemd/system/odoo-monitor.service << 'SYSTEMD'
[Unit]
Description=Odoo Monitoring Service
After=docker.service

[Service]
Type=simple
ExecStart=/usr/local/bin/odoo-monitor
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
SYSTEMD

# Create systemd timer for backups
sudo cat > /etc/systemd/system/odoo-backup.timer << 'TIMER'
[Unit]
Description=Daily Odoo Backup

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
TIMER

sudo cat > /etc/systemd/system/odoo-backup.service << 'SERVICE'
[Unit]
Description=Odoo Backup Service
After=docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/odoo-backup

[Install]
WantedBy=multi-user.target
SERVICE

# Reload systemd and enable services
sudo systemctl daemon-reload
sudo systemctl enable odoo-monitor
sudo systemctl enable odoo-backup.timer
sudo systemctl start odoo-monitor
sudo systemctl start odoo-backup.timer

echo "Monitoring installation completed!"
EOF
