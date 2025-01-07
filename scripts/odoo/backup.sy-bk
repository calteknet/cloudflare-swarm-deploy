#!/bin/bash
set -e

# Configuration
BACKUP_BASE="/opt/odoo/backups"
RETENTION_DAYS=7
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_BASE/$DATE"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Backup host directories
backup_host_dirs() {
    log "Backing up host directories..."
    
    # Backup addons
    if [ -d "/opt/odoo/addons" ]; then
        tar czf "$BACKUP_DIR/addons.tar.gz" -C /opt/odoo addons
    fi

    # Backup configs
    if [ -d "/opt/odoo/config" ]; then
        tar czf "$BACKUP_DIR/config.tar.gz" -C /opt/odoo config
    fi
}

# Backup Docker volumes
backup_volumes() {
    log "Backing up Docker volumes..."
    
    # List of volumes to backup
    volumes=(
        "odoo18-db-data"
        "odoo18-web7-data"
        "odoo18-web8-data"
        "odoo7-config"
        "odoo8-config"
        "odoo-addons"
    )

    for volume in "${volumes[@]}"; do
        if docker volume inspect "$volume" >/dev/null 2>&1; then
            log "Backing up volume: $volume"
            docker run --rm \
                -v "$volume":/source \
                -v "$BACKUP_DIR":/backup \
                alpine tar czf "/backup/$volume.tar.gz" -C /source .
        else
            log "Warning: Volume $volume not found"
        fi
    done
}

# Backup PostgreSQL database
backup_database() {
    log "Backing up PostgreSQL database..."
    docker run --rm \
        --network odoo-internal \
        -e PGPASSWORD="$POSTGRES_PASSWORD" \
        -v "$BACKUP_DIR":/backup \
        postgres:17 \
        pg_dumpall -h postgres -U odoo > "$BACKUP_DIR/full_backup.sql"
}

# Cleanup old backups
cleanup_old_backups() {
    log "Cleaning up old backups..."
    find "$BACKUP_BASE" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \;
}

# Verify backup integrity
verify_backup() {
    log "Verifying backup integrity..."
    
    local failed=0
    
    # Check each backup file
    for file in "$BACKUP_DIR"/*.tar.gz "$BACKUP_DIR"/*.sql; do
        if [ -f "$file" ]; then
            if ! tar tzf "$file" >/dev/null 2>&1; then
                log "Error: Backup file corrupt: $file"
                failed=1
            fi
        fi
    done

    return $failed
}

# Main execution
main() {
    log "Starting backup process..."
    
    backup_host_dirs
    backup_volumes
    backup_database
    verify_backup
    
    if [ $? -eq 0 ]; then
        cleanup_old_backups
        log "Backup completed successfully!"
    else
        log "Backup completed with errors!"
        exit 1
    fi
}

# Run main function
main
