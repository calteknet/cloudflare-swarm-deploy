#!/bin/bash
set -e

# Load configuration
source /etc/odoo/monitor-config.conf

# Configuration
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_SUBDIR="$BACKUP_DIR/$DATE"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Backup Postgres database
backup_database() {
    log "Starting database backup..."
    mkdir -p "$BACKUP_SUBDIR/db"
    
    docker run --rm \
        --network odoo-internal \
        -v "$BACKUP_SUBDIR/db:/backup" \
        postgres:17 \
        pg_dumpall -h postgres -U odoo > "$BACKUP_SUBDIR/db/full_backup.sql"
    
    log "Database backup completed"
}

# Backup Odoo data volumes
backup_volumes() {
    log "Starting volume backup..."
    mkdir -p "$BACKUP_SUBDIR/volumes"
    
    local volumes=(
        "odoo18-db-data"
        "odoo18-web0-data"
        "odoo18-web1-data"
        "odoo0-config"
        "odoo1-config"
    )
    
    for volume in "${volumes[@]}"; do
        log "Backing up volume: $volume"
        docker run --rm \
            -v "$volume":/data \
            -v "$BACKUP_SUBDIR/volumes":/backup \
            alpine:latest \
            tar czf "/backup/$volume.tar.gz" -C /data .
    done
    
    log "Volume backup completed"
}

# Backup configuration files
backup_configs() {
    log "Backing up configuration files..."
    mkdir -p "$BACKUP_SUBDIR/config"
    
    if [ -d "/opt/odoo" ]; then
        tar czf "$BACKUP_SUBDIR/config/odoo_config.tar.gz" -C /opt/odoo .
    fi
    
    log "Configuration backup completed"
}

# Cleanup old backups
cleanup_old_backups() {
    log "Cleaning up old backups..."
    find "$BACKUP_DIR" -type d -mtime +$BACKUP_RETENTION_DAYS -exec rm -rf {} \;
}

# Verify backup integrity
verify_backup() {
    local status=0
    log "Verifying backup integrity..."

    # Check SQL dump
    if ! [ -s "$BACKUP_SUBDIR/db/full_backup.sql" ]; then
        log "ERROR: Database backup appears to be empty or missing"
        status=1
    fi

    # Check volume backups
    for archive in "$BACKUP_SUBDIR/volumes"/*.tar.gz; do
        if ! tar tzf "$archive" >/dev/null 2>&1; then
            log "ERROR: Archive corruption detected in $archive"
            status=1
        fi
    done

    return $status
}

# Main execution
main() {
    log "Starting backup process..."
    
    mkdir -p "$BACKUP_DIR"
    
    backup_database
    backup_volumes
    backup_configs
    
    if verify_backup; then
        cleanup_old_backups
        log "Backup completed successfully"
    else
        log "Backup completed with errors!"
        return 1
    fi
}

# Run main function with error handling
if ! main; then
    send_alert "Backup failed - check logs at $LOG_FILE"
    exit 1
fi
