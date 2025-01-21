#!/bin/bash
set -e

# Check if required files exist
if [ ! -f manager_ip.txt ] || [ ! -f manager_token.txt ] || [ ! -f worker_token.txt ]; then
    echo "Error: Required token files not found"
    exit 1
fi

MANAGER_IP=$(cat manager_ip.txt)
MANAGER_TOKEN=$(cat manager_token.txt)
WORKER_TOKEN=$(cat worker_token.txt)

# Function to join as manager
join_manager() {
    echo "Joining as manager node..."
    docker swarm join --token $MANAGER_TOKEN $MANAGER_IP:2377
}

# Function to join as worker
join_worker() {
    echo "Joining as worker node..."
    docker swarm join --token $WORKER_TOKEN $MANAGER_IP:2377
}

# Ask user for node type
echo "Join as:"
echo "1) Manager node"
echo "2) Worker node"
read -p "Enter choice (1 or 2): " choice

case $choice in
    1) join_manager ;;
    2) join_worker ;;
    *) echo "Invalid choice"; exit 1 ;;
esac

# Set up UFW rules
echo "Setting up UFW rules..."
bash ./setup-ufw.sh

echo "Node joined successfully!"
