#!/bin/bash
set -e

# Load configuration
source /etc/odoo/monitor-config.conf

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Select backup to restore
select_backup() {
    local backups=($BACKUP_DIR/*/)
    if [ ${#backups[@]} -eq 0 ]; then
        log "No backups found in $BACKUP_DIR"
        exit 1
    fi

    echo "Available backups:"
    select backup in "${backups[@]}"; do
        if [ -n "$backup" ]; then
            RESTORE_POINT=$backup
            break
        fi
        echo "Invalid selection"
    done
}

# Restore database
restore_database() {
    log "Restoring database..."
    docker service scale ${STACK_NAME}_odoo0=0 ${STACK_NAME}_odoo1=0
    
    docker run --rm \
        --network odoo-internal \
        -v "$RESTORE_POINT/db:/backup" \
        postgres:17 \
        psql -h postgres -U odoo -f /backup/full_backup.sql
        
    log "Database restore completed"
}

# Restore volumes
restore_volumes() {
    log "Restoring volumes..."
    local volumes=(
        "odoo18-db-data"
        "odoo18-web0-data"
        "odoo18-web1-data"
        "odoo0-config"
        "odoo1-config"
    )
    
    for volume in "${volumes[@]}"; do
        if [ -f "$RESTORE_POINT/volumes/$volume.tar.gz" ]; then
            log "Restoring volume: $volume"
            docker volume rm "$volume" || true
            docker volume create "$volume"
            docker run --rm \
                -v "$volume":/data \
                -v "$RESTORE_POINT/volumes":/backup \
                alpine:latest \
                sh -c "cd /data && tar xzf /backup/$volume.tar.gz"
        fi
    done
}

# Main execution
main() {
    log "Starting restore process..."
    select_backup
    
    read -p "This will stop the Odoo services. Continue? [y/N] " confirm
    if [[ ${confirm,,} != "y" ]]; then
        log "Restore cancelled"
        exit 0
    fi

    restore_database
    restore_volumes
    
    log "Restarting services..."
    docker service scale ${STACK_NAME}_odoo0=1 ${STACK_NAME}_odoo1=1
    
    log "Restore completed"
}

# Run main function with error handling
if ! main; then
    send_alert "Restore failed - check logs at $LOG_FILE"
    exit 1
fi
