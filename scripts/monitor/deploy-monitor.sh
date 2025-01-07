#!/bin/bash
set -e

# Configuration
STACK_NAME="monitor"
DOMAIN="menlola.net"
GRAFANA_PASSWORD=$(openssl rand -base64 12)

# Create directories
sudo mkdir -p /opt/monitor/{prometheus,grafana}
sudo chown -R 472:472 /opt/monitor/grafana  # 472 is grafana user

# Generate environment file
cat > monitor.env << EOF
GRAFANA_PASSWORD=$GRAFANA_PASSWORD
EOF

echo "Generated Grafana admin password: $GRAFANA_PASSWORD"
echo "Please save this password securely!"

# Deploy stack
docker stack deploy -c docker-compose.monitor.yml $STACK_NAME

# Wait for services to start
echo "Waiting for services to start..."
sleep 30

# Verify deployment
docker stack ps $STACK_NAME

echo "Monitor stack deployed!"
echo "Next steps:"
echo "1. Configure Cloudflare tunnels"
echo "2. Access Grafana at monitor.$DOMAIN"
echo "3. Access Prometheus at prometheus.$DOMAIN"
