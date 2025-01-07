# Odoo Monitoring and Backup System

## Overview
This document describes the monitoring and backup system for the Odoo deployment. The system includes real-time monitoring, automated backups, and restore capabilities.

## Installation

### Prerequisites
- Docker Swarm environment
- Systemd-based Linux system
- Root access or sudo privileges

### Installation Steps

1. Install monitoring system:
```bash
cd scripts/odoo
./install-monitor.sh

Simi complete installation instructions and documentation for the monitoring setup.

First, let's create a monitoring installation script (`scripts/odoo/install-monitor.sh`):

```bash
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
```

Now, let's create comprehensive documentation (`docs/odoo/monitoring.md`):

```markdown
# Odoo Monitoring and Backup System

## Overview
This document describes the monitoring and backup system for the Odoo deployment. The system includes real-time monitoring, automated backups, and restore capabilities.

## Installation

### Prerequisites
- Docker Swarm environment
- Systemd-based Linux system
- Root access or sudo privileges

### Installation Steps

1. Install monitoring system:
```bash
cd scripts/odoo
./install-monitor.sh
```

2. Verify installation:
```bash
systemctl status odoo-monitor
systemctl status odoo-backup.timer
```

## Configuration

### Monitor Configuration File
Location: `/etc/odoo/monitor-config.conf`

Key settings:
- Alert notifications (email/Slack)
- Monitoring thresholds
- Service configurations
- Backup retention

### Customizing Thresholds
Edit `/etc/odoo/monitor-config.conf`:
```bash
# Resource Thresholds
DISK_THRESHOLD=90    # Percentage
MEMORY_THRESHOLD=85  # Percentage
CPU_THRESHOLD=80     # Percentage
```

## Monitoring Features

### Real-time Monitoring
- Service health checks
- Resource usage monitoring
- Database connectivity
- Docker service status

### Automated Alerts
- Email notifications
- Slack integration
- Local logging
- Custom alert thresholds

### Health Checks
- Odoo instances (odoo0/odoo1)
- PostgreSQL database
- Docker services
- System resources

## Backup System

### Automated Backups
- Daily backups via systemd timer
- Database dumps
- Volume backups
- Configuration backups

### Backup Contents
1. Database
   - Full PostgreSQL dump
   - Database configuration

2. Volumes
   - odoo18-db-data
   - odoo18-web0-data
   - odoo18-web1-data
   - odoo0-config
   - odoo1-config

3. Configuration
   - Odoo settings
   - System configurations

### Backup Location
- Default: `/var/backups/odoo`
- Configurable in monitor-config.conf

## Restore Process

### Using Restore Script
```bash
odoo-restore
```

The script will:
1. List available backups
2. Stop Odoo services
3. Restore selected backup
4. Restart services

### Manual Restore
1. Stop services:
```bash
docker service scale odoo18_odoo0=0 odoo18_odoo1=0
```

2. Restore database:
```bash
odoo-backup --restore-db <backup-date>
```

3. Restore volumes:
```bash
odoo-backup --restore-volumes <backup-date>
```

## Maintenance

### Log Rotation
- Location: `/var/log/odoo/`
- Rotation: Daily
- Retention: 7 days

### Monitoring Logs
View monitoring logs:
```bash
journalctl -u odoo-monitor
```

View backup logs:
```bash
journalctl -u odoo-backup
```

### Health Check
Verify monitoring:
```bash
odoo-monitor --check
```

## Troubleshooting

### Common Issues

1. Monitor not running:
```bash
systemctl status odoo-monitor
journalctl -u odoo-monitor -n 50
```

2. Backup failures:
```bash
journalctl -u odoo-backup -n 50
```

3. Permission issues:
```bash
ls -l /etc/odoo
ls -l /var/log/odoo
```

### Recovery Steps

1. Service recovery:
```bash
systemctl restart odoo-monitor
```

2. Backup recovery:
```bash
odoo-backup --verify
odoo-backup --repair
```

## Security Considerations

1. File Permissions
   - Configuration files: 600
   - Scripts: 755
   - Log files: 640

2. Access Control
   - Root-only configuration access
   - Restricted backup access
   - Logged audit trail

3. Network Security
   - Internal network monitoring
   - Encrypted alerts
   - Secure backup storage
```

Would you like me to:
1. Add more specific troubleshooting scenarios?
2. Include monitoring dashboard setup?
3. Add backup verification procedures?
