# Odoo Setup Guide

## Prerequisites
- Docker Swarm cluster with Traefik and Cloudflare tunnel configured
- Access to Cloudflare DNS management
- Sufficient resources (minimum 8GB RAM recommended)

## Configuration

### 1. Environment Variables
Copy `stack.env.example` to `stack.env` and configure:
```env
POSTGRES_USER=odoo          # PostgreSQL user
POSTGRES_PASSWORD=myodoo    # PostgreSQL password
POSTGRES_DB=postgres        # PostgreSQL database name
ODOO_HOST=postgres         # Database host
ODOO_PORT=5432            # Database port
ODOO_USER=odoo            # Odoo database user
ODOO_PASSWORD=myodoo      # Odoo database password
DOMAIN1=menlola.net       # First Odoo instance domain
DOMAIN2=ctn.menlola.net   # Second Odoo instance domain
