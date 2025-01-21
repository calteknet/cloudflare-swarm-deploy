`docs/cloudflare-setup.md`:
```markdown
# Cloudflare Setup Guide

# Successful Base Deployment Steps

## Prerequisites
- Parrot OS on all nodes
- Docker installed
- Fixed IP addresses configured

## Order of Operations
1. Deploy Portainer first
2. Configure Cloudflare tunnel
3. Deploy Traefik
4. Join additional nodes

## Working Configurations
### Portainer Deployment
- Initial manager node setup
- Cloudflare tunnel configuration
- Agent deployment

### Traefik Configuration
- Network configuration
- SSL/TLS settings with Cloudflare
- Working docker-compose.yml

## Verified Steps
1. First manager node initialization
2. Portainer deployment
3. Cloudflare tunnel setup
4. Traefik deployment
5. Additional node joining

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

## Working Versions
- Parrot OS (Debian-based)
- Docker Engine v27.4.1
- Traefik v3.2
- Portainer CE latest
- Cloudflare tunnel latest

## Troubleshooting Steps

### Cloudflare Tunnel Issues
1. Verify SSL/TLS setting in Cloudflare:
   - Set SSL/TLS encryption mode to "Full"
   - Verify CNAME records point to tunnel
   - Check tunnel status in Zero Trust dashboard

### Portainer Access Issues
1. If Portainer UI is inaccessible:
   ```bash
   # Check Portainer service status
   docker service ls
   docker service ps portainer_portainer
