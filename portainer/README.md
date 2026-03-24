# Portainer Setup

Portainer is an open-source IT management platform for Docker, Kubernetes, and Azure IoT. This setup deploys Portainer Community Edition.

## Setup

1. Start Portainer:
```bash
cd portainer
docker-compose up -d
```

2. Access Portainer:
- **Web UI (HTTPS)**: https://localhost:9443
- **Web UI (HTTP)**: http://localhost:9000

## Configuration

### Default Credentials
- First time access will require creating an admin account

### Ports
- **9443**: HTTPS web interface
- **9000**: HTTP web interface  
- **8000**: Edge agent communications

### Volumes
- `portainer_data`: Persistent storage for Portainer data
- `/var/run/docker.sock`: Docker socket for container management

### Environment Variables
- Edit `.env` file to customize ports and paths

## Usage

1. Create an admin account on first access
2. Connect to local Docker engine automatically
3. Manage containers, images, networks, and volumes through web UI
4. Set up Edge agents for remote management

## Stop and Cleanup

```bash
# Stop Portainer
docker-compose down

# Remove volumes (data will be lost)
docker-compose down -v
```