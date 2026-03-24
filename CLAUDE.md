# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a homelab stack repository for deploying various services locally using Docker Compose. Currently contains MinIO S3 storage and Portainer management services.

## Stack Architecture

The homelab stack is organized into modular layers:

### Current Services

#### 1. MinIO S3 Stack (`minio-s3`)
Object storage solution with S3-compatible API.

**Setup**
```bash
cd minio-s3
docker-compose up -d
```

**Access Points**
- **MinIO Console**: http://localhost:9001
- **MinIO Browser**: http://localhost:9002
- **API Endpoint**: http://localhost:9000

**Default Credentials**
- Username: minioadmin
- Password: minioadmin123

**Configuration**
- Edit `.env` file to customize credentials and ports
- Storage volumes: `minio_data1`, `minio_data2`

**Buckets**
- `test-bucket`: General purpose
- `backups`: Backup storage

**Scripts**
- `scripts/create-buckets.sh`: Automates bucket creation

#### 2. Portainer Stack (`portainer`)
Container management and monitoring interface.

**Setup**
```bash
cd portainer
docker-compose up -d
```

**Access Points**
- **HTTPS UI**: https://localhost:9443
- **HTTP UI**: http://localhost:9000
- **Edge Agent**: http://localhost:8000

**Configuration**
- Manages Docker daemon via socket mount
- Persistent storage: `portainer_data` volume
- Customizable via `.env` file

### Planned Services

Based on the modular architecture, the following services are planned:

- **Proxy Layer**: Reverse proxy and load balancing
- **Monitoring Layer**: Prometheus, Grafana, and logging
- **Secrets Layer**: Secure credential management
- **Orchestration Layer**: Advanced container orchestration

## Environment Configuration

All services use `.env` files for configuration. Copy from `.env.example` as needed:

```bash
cp .env.example .env
```

## Git Repository

- **Remote**: git@github.com:ronaldocristover/homelab-stack.git
- **Main branch**: main
- **User**: Ronaldo (ronaldochristover@gmail.com)

## MinIO S3 Stack (`minio-s3`)

### Setup
```bash
cd minio-s3
docker-compose up -d
```

### Access Points
- **MinIO Console**: http://localhost:9001
- **MinIO Browser**: http://localhost:9002
- **API Endpoint**: http://localhost:9000

### Default Credentials
- Username: minioadmin
- Password: minioadmin123

### Configuration
- Edit `.env` file to customize credentials and ports
- Storage volumes: `minio_data1`, `minio_data2`

### Buckets
- `test-bucket`: General purpose
- `backups`: Backup storage

## Git Repository

- **Remote**: git@github.com:ronaldocristover/homelab-stack.git
- **Main branch**: main
- **User**: Ronaldo (ronaldochristover@gmail.com)