# Prerequisites

## Required Services
- Docker (20.10.x or newer)
- Docker Compose v2
- UFW (Uncomplicated Firewall)
- Git

## Required Accounts
- GitHub account
- Cloudflare account with registered domain

## System Requirements
- Ubuntu 22.04 LTS or Debian 12
- 2GB RAM minimum
- 20GB free disk space

## Network Requirements
- Static IP or reliable DHCP reservation
- Open ports (see UFW configuration)
- Internet connectivity

## Pre-Installation Steps
1. Update system packages:
   ```bash
   sudo apt update && sudo apt upgrade -y
`docs/cloudflare-setup.md`:
```markdown
# Cloudflare Setup Guide

## Domain Configuration
1. Add your domain to Cloudflare
2. Update nameservers with your registrar
3. Verify domain is active in Cloudflare

## Tunnel Setup
1. Navigate to Zero Trust > Networks > Tunnels
2. Create new tunnel
3. Copy tunnel token
4. Add to .env file

## DNS Configuration
1. Create A records for:
   - traefik.yourdomain.com
   - portainer.yourdomain.com
2. Set Proxy status (orange cloud)

## API Token
1. Go to Profile > API Tokens
2. Create token with permissions:
   - Zone:DNS:Edit
   - Zone:Zone:Read
3. Copy token to .env file
