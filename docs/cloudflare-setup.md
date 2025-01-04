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
