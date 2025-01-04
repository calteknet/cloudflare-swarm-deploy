# Cloudflare Swarm Deploy

Docker Swarm deployment using Traefik and Cloudflare tunnels for secure access.

## Prerequisites
- Docker Swarm mode enabled
- Cloudflare account with domain
- Docker and Docker Compose installed

## Quick Start
1. Copy `.env.example` to `.env` and fill in your values
2. Run `./scripts/init-swarm.sh` to initialize the swarm
3. Deploy Traefik and Portainer using `./scripts/deploy-base.sh`

## Documentation
See the [docs](./docs) directory for detailed setup and configuration instructions.
