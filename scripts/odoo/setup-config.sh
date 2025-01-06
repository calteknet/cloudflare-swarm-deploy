#!/bin/bash
set -e

# Validation functions
validate_domain() {
    local domain=$1
    if [[ ! $domain =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "Invalid domain format: $domain"
        return 1
    fi
}

validate_memory() {
    local mem=$1
    if ! [[ "$mem" =~ ^[0-9]+$ ]] || [ "$mem" -lt 1 ] || [ "$mem" -gt 32 ]; then
        echo "Memory must be between 1 and 32 GB"
        return 1
    fi
}

validate_path() {
    local path=$1
    if [[ ! $path =~ ^/ ]]; then
        echo "Path must be absolute (start with /)"
        return 1
    fi
}

# Enhanced configure function with validation
configure() {
    echo "=== Odoo Stack Configuration Setup ==="
    echo

    # Database configuration with validation
    while true; do
        read -p "PostgreSQL Username [odoo]: " pg_user
        PG_USER=${pg_user:-odoo}
        [[ $PG_USER =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]] && break
        echo "Invalid username format. Use letters, numbers, and underscore only."
    done
    
    while true; do
        read -s -p "PostgreSQL Password: " pg_pass
        echo
        [[ ${#pg_pass} -ge 8 ]] && break
        echo "Password must be at least 8 characters long."
    done
    PG_PASS=${pg_pass:-$(openssl rand -base64 12)}

    # Domain validation
    while true; do
        read -p "Primary Domain (e.g., odoo.example.com): " domain1
        validate_domain "$domain1" && break
    done

    while true; do
        read -p "Secondary Domain (e.g., erp.example.com): " domain2
        validate_domain "$domain2" && break
    done

    # Resource limits with validation
    while true; do
        read -p "PostgreSQL Memory Limit (GB) [4]: " pg_memory
        PG_MEMORY=${pg_memory:-4}
        validate_memory "$PG_MEMORY" && break
    done

    while true; do
        read -p "Odoo Instance Memory Limit (GB) [2]: " odoo_memory
        ODOO_MEMORY=${odoo_memory:-2}
        validate_memory "$ODOO_MEMORY" && break
    done

    # Host paths validation
    read -p "Create host directories for addons? [Y/n]: " create_dirs
    if [[ ${create_dirs,,} != "n" ]]; then
        while true; do
            read -p "Base path for addons [/opt/odoo/addons]: " addons_path
            ADDONS_PATH=${addons_path:-/opt/odoo/addons}
            validate_path "$ADDONS_PATH" && break
        done
        echo "Will create: $ADDONS_PATH"
    fi
}
