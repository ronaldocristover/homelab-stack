# Homelab Stack

A comprehensive, modular Docker Compose homelab stack for self-hosting various services. Each layer is managed independently through its own Docker Compose file, allowing for granular control over service management.

## Prerequisites

### Operating System
- Linux (Ubuntu 20.04+ recommended)
- Docker installed
- Docker Compose v2.0+ installed

### Install Docker
```bash
# Update apt package index
sudo apt update

# Install prerequisites
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Add user to docker group
sudo usermod -aG docker $USER

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Log out and back in for group changes to take effect
```

### Install Docker Compose
```bash
# Download Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make it executable
sudo chmod +x /usr/local/bin/docker-compose
```

## First Run Order

When setting up your homelab for the first time, start the layers in the following order:

1. **Layer 1 - Proxy** (Nginx Proxy Manager + MariaDB)
   - Required for all externally accessible services
   - Provides HTTPS certificates and routing

2. **Layer 6 - Database** (Shared PostgreSQL + Redis)
   - Required by most other layers
   - Shared databases for multiple services

3. **Layer 3 - Secrets** (Gitea + Infisical)
   - Gitea for code repository
   - Infisical for secret management

4. **Layer 8 - CICD** (Woodpecker Server + Agent)
   - Connect to Gitea for CI/CD
   - Requires SSH key for deployment

5. **Layer 2 - Orchestration** (Portainer)
   - Management interface
   - Required for agent setup

6. **Layer 4 - Monitoring** (Prometheus + Grafana + Uptime Kuma)
   - Observability stack
   - Monitor all services

7. **Layer 5 - Logging** (Loki + Promtail + Tempo)
   - Centralized logging and tracing
   - Collects all container logs

8. **Layer 7 - Backup** (Restic with rclone)
   - Automated backups
   - Backs up all important data

9. **Layer 9 - Ops** (Ntfy + Vaultwarden + Vikunja)
   - Operational tools
   - Notification manager, password manager, task manager

## Usage

### Initialize the Stack
```bash
# Copy environment template and edit
make update-env
nano .env

# Initialize networks and volumes
make init
```

### Start All Layers
```bash
# Start all layers in order
make up-all
```

### Manage Individual Layers
```bash
# Start specific layer
make up-proxy
make up-monitoring
make up-ops

# Stop specific layer
make down-monitoring
make down-proxy

# View logs for specific layer
make logs-monitoring -f
make logs-ops

# Restart specific layer
make restart-monitoring
```

### Check Status
```bash
# Show status of all containers
make status
```

### Update All Images
```bash
# Pull latest images for all layers
make pull-all
```

## Adding a Client Server as Portainer Agent

1. **Install Portainer Agent on client server**:
```bash
# On client server
docker run -d -p 9443:9443 --name=agent --restart=unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  portainer/agent:2.21.4
```

2. **Add Agent to Portainer**:
   - Access Portainer at https://portainer.example.com
   - Go to "Agents" → "Add agent"
   - Use the displayed access key
   - Select "Edge agent"
   - Paste the access key and click "Connect"

3. **Configure Agent**:
   - Set up environment variables for the agent
   - Configure volume mounts for SSH keys (for Woodpecker deployments)

## Setting Up Woodpecker ↔ Gitea OAuth

1. **Create OAuth Application in Gitea**:
   - Navigate to Gitea → Settings → OAuth Applications → New OAuth Application
   - Redirect URI: `https://ci.example.com/api/oauth/callback`
   - Application Name: `Woodpecker CI`
   - Home Page URL: `https://ci.example.com`

2. **Create `woodpecker.env` in config directory**:
```bash
echo "WOODPECKER_GITEA=true" >> config/woodpecker/woodpecker.env
echo "WOODPECKER_GITE_URL=https://git.example.com" >> config/woodpecker/woodpecker.env
echo "WOODPECKER_GITE_CLIENT_ID=your_client_id" >> config/woodpecker/woodpecker.env
echo "WOODPECKER_GITE_CLIENT_SECRET=your_client_secret" >> config/woodpecker/woodpecker.env
```

3. **Restart Woodpecker**:
```bash
make restart-cicd
```

4. **Finalize OAuth**:
   - Open https://ci.example.com
   - Gitea will prompt you to authorize the application
   - Click "Authorize"

## Port Reference Table

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| Nginx Proxy Manager | 80, 443 | HTTP/HTTPS | Web proxy |
| Nginx Proxy Manager Admin | 81 | HTTP | Admin interface |
| Portainer | 9443 | HTTPS | Management interface |
| Prometheus | 9090 | HTTP | Metrics collection |
| Grafana | 3000 | HTTP | Dashboard UI |
| Uptime Kuma | 3001 | HTTP | Monitoring dashboard |
| Loki | 3100 | HTTP | Logs aggregation |
| Tempo | 4317, 4318 | gRPC/HTTP | Traces collection |
| Woodpecker | 8000 | HTTP | CI/CD interface |
| Vaultwarden | 80 | HTTP | Password manager |
| Vikunja | 3456 | HTTP | Task management |
| Gitea | 3000 | HTTP | Git repository |
| Infisical | 80 | HTTP | Secret management |
| Ntfy | 80 | HTTP | Notifications |

## Common Docker Compose Commands

### Per Layer
```bash
# Navigate to layer directory
cd layers/1-proxy

# Up services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Restart services
docker-compose restart

# View resource usage
docker-compose ps

# Update images
docker-compose pull && docker-compose up -d
```

### Cross-Layer Commands
```bash
# Stop and restart all layers
make down-all && make up-all

# Check health of all databases
docker exec -it postgres pg_isready -U homelab
docker exec -it redis redis-cli ping

# View Prometheus targets
curl http://localhost:9090/api/v1/targets

# View Grafana dashboards
open http://localhost:3000
```

## Backup Verification

### Restic Backups
```bash
# Check snapshot list
docker exec restic restic snapshots -r ${RESTIC_REPOSITORY}

# Check backup integrity
docker exec restic restic check -r ${RESTIC_REPOSITORY}

# List individual files
docker exec restic restic ls latest -r ${RESTIC_REPOSITORY}

# Mount backup for inspection
docker run --rm -it --entrypoint=restic \
  -v ${RESTIC_CACHE}:/cache \
  -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
  -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
  restic/restic:latest \
  mount -r ${RESTIC_REPOSITORY} /mnt
```

### Database Backups
```bash
# PostgreSQL backup
docker exec postgres pg_dump -U homelab homelab > backup.sql

# Gitea backup
docker exec gitea gitea dump --config /data/gitea/conf/app.ini

# Woodpecker backup
docker exec postgres-database pg_dump -U woodpecker woodpecker > woodpecker-backup.sql
```

## Troubleshooting

### Common Issues

1. **Services not starting**:
   - Check environment variables in `.env`
   - Verify all required networks and volumes exist
   - Check Docker logs: `docker logs <container_name>`

2. **Network connectivity issues**:
   - Verify services are on correct networks
   - Check firewall rules on host
   - Use `docker network inspect` to verify connectivity

3. **Permission issues**:
   - Ensure user is in docker group
   - Check volume mount permissions
   - Verify file ownership in mounted directories

4. **Memory/CPU limits**:
   - Monitor resource usage with `docker stats`
   - Adjust resource limits in compose files if needed

### Health Checks

```bash
# Check database health
docker exec -it postgres pg_isready -U homelab

# Check Redis health
docker exec -it redis redis-cli ping

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Check Grafana health
curl http://localhost:3000/api/health
```

## Security Considerations

1. **Environment Variables**:
   - Never commit `.env` to version control
   - Use strong passwords for all services
   - Rotate secrets regularly

2. **Network Security**:
   - Use separate networks for different layers
   - Implement firewall rules as needed
   - Monitor network traffic

3. **Access Control**:
   - Use strong authentication for Portainer
   - Enable two-factor authentication where available
   - Regularly audit user permissions

4. **Data Protection**:
   - Enable encryption for sensitive volumes
   - Regular backups are configured automatically
   - Test backup restoration procedures

## Contributing

1. Follow the existing directory structure
2. Update environment template when adding new services
3. Add health checks to database services
4. Document any changes in this README

## License

This project is for personal use only.