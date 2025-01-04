# Deployment Guide

## Initial Setup
1. Clone repository:
   ```bash
   git clone https://github.com/calteknet/cloudflare-swarm-deploy.git
   cd cloudflare-swarm-deploy
2. 2.Copy and configure environment:
cp .env.example .env
nano .env

Deploy Stack
1. Initialize swarm:
./scripts/init-swarm.sh
2. Deploy base services:
./scripts/deploy-base.sh

Verify Deployment
1, Check services:
docker stack ls
docker service ls
2. Access dashboards:
Traefik: https://traefik.yourdomain.com
Portainer: https://portainer.yourdomain.com

Adding Nodes
1. Get join token:
docker swarm join-token worker
2. Run join command on new nodes


