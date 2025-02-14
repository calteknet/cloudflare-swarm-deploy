#!/bin/bash
set -e

# Load environment variables
if [ -f ../.env ]; then
    source ../.env
else
    echo "Error: .env file not found"
    exit 1
fi

# Function to check if stack is ready
check_stack() {
    local stack_name=$1
    local expected_services=$2
    local timeout=60
    local count=0
    
    echo "Waiting for $stack_name to be ready..."
    while [ $count -lt $timeout ]; do
        ready_services=$(docker stack services $stack_name --format "{{.Name}}" | wc -l)
        if [ "$ready_services" -eq "$expected_services" ]; then
            echo "$stack_name is ready"
            return 0
        fi
        sleep 1
        ((count++))
    done
    echo "Timeout waiting for $stack_name to be ready"
    return 1
}

# Check if this is the primary manager node
if ! docker node ls | grep -q "Leader"; then
    echo "Error: This script must be run on the primary manager node"
    exit 1
fi

# Deploy Portainer with replication
echo "Deploying Portainer..."
cd ../configs/portainer || exit 1
docker stack deploy -c docker-compose.yml portainer

# Wait for Portainer to be ready
check_stack portainer 3

# Deploy Traefik
echo "Deploying Traefik..."
cd ../traefik || exit 1
docker stack deploy -c docker-compose.yml traefik

# Wait for Traefik to be ready
check_stack traefik 1

echo "Base deployment complete!"

# Print access information
echo "Access URLs:"
echo "Portainer: https://portainer.${DOMAIN_NAME}"
echo "Traefik Dashboard: https://traefik.${DOMAIN_NAME}"

# Show cluster status
echo -e "\nCluster Status:"
docker node ls
