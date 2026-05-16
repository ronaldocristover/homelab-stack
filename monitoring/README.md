# Monitoring Stack

Full observability stack for the homelab: **Prometheus** (metrics) + **Loki** (logs) + **Grafana Alloy** (log shipper) + **Grafana** (dashboards) + **Alertmanager** (Discord alerts).

Automatically discovers and monitors **every running Docker container** on the host — no per-container config needed.

## Components

| Service | Purpose | Default Port |
|---|---|---|
| Grafana | Dashboards & visualization | 3000 |
| Prometheus | Metrics storage & alert rules | 9090 |
| Loki | Log aggregation | 3100 |
| Alertmanager | Alert routing → Discord | 9093 |
| Grafana Alloy | Log shipper (Promtail successor) | 12345 |
| cAdvisor | Per-container metrics | 8081 |
| Node Exporter | Host-level metrics | 9100 |

## Setup

1. **Create your Discord webhook**
   - Discord → Server Settings → Integrations → Webhooks → New Webhook → Copy Webhook URL

2. **Configure env**
   ```bash
   cd monitoring
   cp .env.example .env
   # Edit .env, paste DISCORD_WEBHOOK_URL and set GRAFANA_ADMIN_PASSWORD
   ```

3. **Start the stack**
   ```bash
   docker-compose up -d
   ```

4. **Access**
   - Grafana → http://localhost:3000 (login with `.env` credentials)
   - Prometheus → http://localhost:9090
   - Alertmanager → http://localhost:9093

Grafana comes pre-provisioned with:
- **Prometheus** and **Loki** datasources
- **Homelab — Container Overview** dashboard (CPU/Mem/Network + live error logs)
- **Homelab — Host Overview** dashboard

## How it discovers your containers

- **Metrics**: cAdvisor reads `/var/run/docker.sock` and exposes per-container metrics for *everything* running on the host. Prometheus scrapes it every 15s.
- **Logs**: Alloy reads the Docker socket and tails `/var/lib/docker/containers/*/*-json.log` for every container. Logs are auto-labeled with `container`, `image`, `compose_project`, `compose_service`.

This means **your MinIO, Portainer, etc. stacks are monitored automatically** — they don't need to share a network with the monitoring stack.

## Alerts

Pre-configured rules (`prometheus/rules/alerts.yml`, `loki/rules/alerts.yml`):

| Alert | Trigger | Severity |
|---|---|---|
| ContainerDown | Container missing >2m | critical |
| ContainerHighCPU | >85% for 5m | warning |
| ContainerHighMemory | >90% of limit for 5m | warning |
| ContainerRestarting | Restart in last 15m | warning |
| HostHighCPU | >85% for 5m | warning |
| HostHighMemory | >90% for 5m | warning |
| HostDiskSpaceLow | >85% full for 5m | warning |
| HostDown | node-exporter unreachable >2m | critical |
| HighErrorLogRate | >10 error logs in 5m per container | warning |
| ContainerLoggingPanic | Any `panic`/`fatal` in logs | critical |

All alerts → Alertmanager → **Discord** (critical alerts get a 🚨 prefix).

### Test the Discord webhook

```bash
docker exec alertmanager amtool alert add \
  alertname="TestAlert" severity="warning" \
  --annotation=summary="Test from homelab" \
  --annotation=description="If you see this in Discord, alerting works"
```

### Adding alerts

- **Metric-based** → edit `prometheus/rules/alerts.yml`, then `docker-compose restart prometheus` (or `curl -X POST http://localhost:9090/-/reload`).
- **Log-based** → edit `loki/rules/alerts.yml`, then `docker-compose restart loki`.

## Customization

- **Retention**: tweak `PROMETHEUS_RETENTION` and `LOKI_RETENTION_HOURS` in `.env`.
- **Add a generic webhook (Slack, custom)**: add a `webhook_configs:` block in `alertmanager/alertmanager.yml` and route to it. `GENERIC_WEBHOOK_URL` is already wired through env.
- **Dashboards**: drop any JSON into `grafana/dashboards/` — auto-loaded every 30s.

## Troubleshooting

- **No container metrics?** → cAdvisor needs `/sys/fs/cgroup`. On cgroup v2 hosts it just works; on cgroup v1 you may need `--volume=/cgroup:/cgroup:ro`.
- **Port 8080 conflict?** → cAdvisor is mapped to host port `8081` by default (change `CADVISOR_PORT`).
- **Discord not receiving alerts?** → Check `docker logs alertmanager`. The webhook URL is written to `/etc/alertmanager/discord_webhook` at startup from `DISCORD_WEBHOOK_URL` env.
- **WSL2 host metrics look weird** → Node Exporter inside WSL only sees the WSL kernel, not Windows host. That's expected.
