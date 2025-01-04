#!/bin/bash
set -e

# Load environment variables
source ../.env

echo "Deploying Traefik..."
cd ../configs/traefik
docker stack deploy -c docker-compose.yml traefik

echo "Waiting for Traefik to start (30s)..."
sleep 30

echo "Deploying Portainer..."
cd ../portainer
docker stack deploy -c docker-compose.yml portainer

echo "Base deployment complete!"
