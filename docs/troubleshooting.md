## Troubleshooting Steps

### Cloudflare Tunnel Issues
1. Verify SSL/TLS setting in Cloudflare:
   - Set SSL/TLS encryption mode to "Full"
   - Verify CNAME records point to tunnel
   - Check tunnel status in Zero Trust dashboard

### Portainer Access Issues
1. If Portainer UI is inaccessible:
   ```bash
   # Check Portainer service status
   docker service ls
   docker service ps portainer_portainer
   ```
2. If agent connection fails:
   ```bash
   # Remove and redeploy agent
   docker service rm portainer_agent
   docker service create \
     --name portainer_agent \
     --network traefik-public \
     -p 9001:9001/tcp \
     --mode global \
     --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
     portainer/agent:latest
   ```

### Traefik Issues
1. 502 Bad Gateway errors:
   - Verify Cloudflare tunnel is running
   - Check Traefik logs:
   ```bash
   docker service logs traefik_traefik
   ```
2. Authentication issues:
   - Regenerate BASIC_AUTH_STRING:
   ```bash
   export BASIC_AUTH_STRING=$(htpasswd -nb admin yourpassword)
   ```

### Node Joining Issues
1. Network connectivity:
   ```bash
   # Verify ports are open
   sudo ufw status
   ```
2. Docker swarm issues:
   ```bash
   # On manager node
   docker node ls
   # Remove problematic nodes if needed
   docker node rm NODE_ID
   ```

### Common Fixes
1. Network subnet conflicts:
   - Check existing networks:
   ```bash
   docker network ls
   docker network inspect traefik-public
   ```
2. Service not starting:
   - Force update service:
   ```bash
   docker service update --force SERVICE_NAME
   ```
3. Node status issues:
   - Leave and rejoin swarm:
   ```bash
   docker swarm leave --force
   docker swarm join --token TOKEN MANAGER_IP:2377
   ```
```

Would you like me to:
1. Add any specific troubleshooting steps we used that I missed?
2. Include command outputs that indicate success?
3. Add sections for specific error messages we encountered?
