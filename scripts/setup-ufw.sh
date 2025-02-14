#!/bin/bash
set -e

echo "Setting up UFW rules for Docker Swarm..."
sudo ufw status verbose
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Array of rules
declare -A rules=(
    ["SSH"]="22/tcp"
    ["HTTP"]="80/tcp"
    ["HTTPS"]="443/tcp"
    ["Traefik Dashboard"]="8080/tcp"
    ["Swarm management"]="2377/tcp"
    ["Node TCP communication"]="7946/tcp"
    ["Node UDP communication"]="7946/udp"
    ["Overlay network"]="4789/udp"
)

# Apply rules
for name in "${!rules[@]}"; do
    echo "Adding rule for $name: ${rules[$name]}"
    sudo ufw allow "${rules[$name]}"
done

# Enable UFW if not already enabled
if ! sudo ufw status | grep -q "Status: active"; then
    echo "Enabling UFW..."
    sudo ufw --force enable
fi

echo "UFW setup complete!"
sudo ufw status numbered
