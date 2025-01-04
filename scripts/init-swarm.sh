#!/bin/bash
set -e

# Load environment variables
source ../.env

echo "Initializing Docker Swarm..."
docker swarm init

echo "Creating traefik-public network..."
docker network create --driver=overlay traefik-public

echo "Setting up UFW rules..."
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8080/tcp
sudo ufw allow 2377/tcp
sudo ufw allow 7946/tcp
sudo ufw allow 7946/udp
sudo ufw allow 4789/udp

echo "Swarm initialization complete!"
