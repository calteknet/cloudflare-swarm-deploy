#!/bin/bash
set -e

echo "Setting up UFW rules for Docker Swarm..."
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH
sudo ufw allow 22/tcp

# HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Traefik Dashboard
sudo ufw allow 8080/tcp

# Docker Swarm ports
sudo ufw allow 2377/tcp  # cluster management
sudo ufw allow 7946/tcp  # node communication
sudo ufw allow 7946/udp  # node communication
sudo ufw allow 4789/udp  # overlay network

sudo ufw enable

echo "UFW setup complete!"
