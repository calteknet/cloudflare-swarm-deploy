#!/bin/bash
set -e

# Configuration
BACKUP_BASE="/opt/odoo/backups"
RESTORE_POINT=""

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to select backup to restore
select_backup() {
    local backups=($BACKUP_BASE/*/)
    if [ ${#backups[@]} -eq 0 ]; then
        log "No backups found in $BACKUP_BASE"
        exit 1
    }

    echo "Available backups:"
    select backup in "${backups[@]}"; do
        if [ -n "$backup" ]; then
            RESTORE_POINT=$backup
            break
        fi
        echo "Invalid selection"
    done
}

# Restore host directories
restore_host_dirs() {
    log "Restoring host directories..."
    
    if [ -f "$RESTORE_POINT/addons.tar.gz" ]; then
        log "Restoring addons..."
        sudo rm -rf /opt/odoo/addons/*
        sudo tar xzf "$RESTORE_POINT/addons.tar.gz" -C /opt/odoo
    fi

    if [ -f "$RESTORE_POINT/config.tar.gz" ]; then
        log "Restoring config..."
        sudo rm -rf /opt/odoo/config/*
        sudo tar xzf "$RESTORE_POINT/config.tar.gz" -C /opt/odoo
    fi
}

# Restore Docker volumes
restore_volumes() {
    log "Restoring Docker volumes..."
    
    # List of volumes to restore
    volumes=(
        "odoo18-db-data"
        "odoo18-web7-data"
        "odoo18-web8-data"
        "odoo7-config"
        "odoo8-config"
        "odoo-addons"
    )

    for volume in "${volumes[@]}"; do
        if [ -f "$RESTORE_POINT/$volume.tar.gz" ]; then
            log "Restoring volume: $volume"
            docker volume rm "$volume" || true
            docker volume create "$volume"
            docker run --rm \
                -v "$volume":/dest \
                -v "$RESTORE_POINT":/backup \
                alpine sh -c "cd /dest && tar xzf /backup/$volume.tar.gz"
        fi
    done
}

# Restore PostgreSQL database
restore_database() {
    log "Restoring PostgreSQL database..."
    if [ -f "$RESTORE_POINT/full_backup.sql" ]; then
        docker run --rm \
            --network odoo-internal \
            -e PGPASSWORD="$POSTGRES_PASSWORD" \
            -v "$RESTORE_POINT":/backup \
            postgres:17 \
            psql -h postgres -U odoo -f /backup/full_backup.sql
    fi
}

# Verify restore
verify_restore() {
    log "Verifying restore..."
    
    # Check volume restoration
    for volume in "${volumes[@]}"; do
        if ! docker volume inspect "$volume" >/dev/null 2>&1; then
            log "Error: Volume $volume not restored properly"
            return 1
        fi
    done

    # Check database connection
    if ! docker exec $(docker ps -q -f name=postgres) pg_isready -U odoo; then
        log "Error: Database not responding after restore"
        return 1
    fi

    return 0
}

# Main execution
main() {
    log "Starting restore process..."
    
    select_backup
    
    read -p "This will stop the Odoo stack. Continue? [y/N] " confirm
    if [[ ${confirm,,} != "y" ]]; then
        log "Restore cancelled"
        exit 0
    fi

    # Stop services
    docker stack rm odoo || true
    sleep 30  # Wait for services to stop

    restore_host_dirs
    restore_volumes
    restore_database
    
    if verify_restore; then
        log "Restore completed successfully!"
    else
        log "Restore completed with errors!"
        exit 1
    fi
}

# Run main function
main
