#!/bin/bash
set -e

# Configuration
CONFIG_FILE="/etc/odoo/monitor-config.conf"
ALERT_EMAIL=""
SLACK_WEBHOOK=""

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Monitoring metrics
check_disk_space() {
    local threshold=90
    local usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$usage" -gt "$threshold" ]; then
        return 1
    fi
    return 0
}

check_backup_status() {
    local backup_dir="/opt/odoo/backups"
    find "$backup_dir" -type f -mtime -1 | grep -q .
    return $?
}

check_services() {
    docker stack services odoo | grep -q "0/1"
    if [ $? -eq 0 ]; then
        return 1
    fi
    return 0
}

send_alert() {
    local message="$1"
    
    # Email alert
    if [ -n "$ALERT_EMAIL" ]; then
        echo "$message" | mail -s "Odoo Alert" "$ALERT_EMAIL"
    fi
    
    # Slack alert
    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$message\"}" "$SLACK_WEBHOOK"
    fi
}

# Main monitoring loop
main() {
    local status=0
    
    if ! check_disk_space; then
        send_alert "Disk space critical"
        status=1
    fi
    
    if ! check_backup_status; then
        send_alert "Backup check failed"
        status=1
    fi
    
    if ! check_services; then
        send_alert "Service check failed"
        status=1
    fi
    
    exit $status
}

main
