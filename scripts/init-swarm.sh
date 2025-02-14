#!/bin/bash
set -e

# Function to check if swarm is already initialized
check_swarm() {
    if docker info --format '{{.Swarm.LocalNodeState}}' | grep -q "active"; then
        echo "Swarm is already initialized"
        return 0
    fi
    return 1
}

# Function to check if network exists
check_network() {
    if docker network ls | grep -q "traefik-public"; then
        echo "traefik-public network already exists"
        return 0
    fi
    return 1
}

# Load environment variables
if [ -f ../.env ]; then
    source ../.env
else
    echo "Error: .env file not found"
    exit 1
fi

# Initialize first manager node if not already initialized
if ! check_swarm; then
    echo "Initializing first manager node..."
    docker swarm init
    
    # Store the manager and worker join tokens
    echo "Saving join tokens..."
    docker swarm join-token manager -q > manager_token.txt
    docker swarm join-token worker -q > worker_token.txt
    
    # Get the IP address of the first manager
    MANAGER_IP=$(hostname -I | awk '{print $1}')
    echo "$MANAGER_IP" > manager_ip.txt
    
    echo "First manager node initialized"
    echo "Manager IP: $MANAGER_IP"
    echo "Use these tokens to join other nodes:"
    echo "Manager token saved to: manager_token.txt"
    echo "Worker token saved to: worker_token.txt"
fi

# Create traefik-public network if it doesn't exist
if ! check_network; then
    echo "Creating traefik-public network..."
    docker network create --driver=overlay traefik-public
fi

# Set up UFW rules
echo "Setting up UFW rules..."
bash ./setup-ufw.sh

echo "Swarm initialization complete!"
