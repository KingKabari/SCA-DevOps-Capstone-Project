# RUNBOOK.md

> Closes #16
> Maintainer: [@Woyengidinipre](https://github.com/Woyengidinipre)
> Label: `documentation`

This runbook documents diagnosis steps, recovery commands, and verification checks for common failures in the SCA DevOps Capstone Project.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Docker Containers Not Running](#2-docker-containers-not-running)
3. [Network Communication Issues](#3-network-communication-issues)
4. [Nginx / Reverse Proxy Errors](#4-nginx--reverse-proxy-errors)
5. [App Service Failures](#5-app-service-failures)
6. [PostgreSQL Connection Issues](#6-postgresql-connection-issues)
7. [Monitoring Failures](#7-monitoring-failures)
8. [GitHub Actions / CI Failures](#8-github-actions--ci-failures)
9. [Configuration Drift](#9-configuration-drift)
10. [Rollback Procedures](#10-rollback-procedures)
11. [Quick Reference](#11-quick-reference)

---

## 1. Project Overview

This project provisions three Docker containers using Terraform and configures them using Ansible.

| Node | Role |
|------|------|
| `web_node` | Nginx web server |
| `app_node` | Application server |
| `db_node` | Database server (PostgreSQL) |

**Monitoring:** Prometheus + Grafana via `node_exporter` on all nodes.  
**CI/CD:** GitHub Actions runs `ansible-lint` and `terraform validate` on every push.

---

## 2. Docker Containers Not Running

### Symptoms
- `ansible all -m ping` returns `UNREACHABLE`
- `docker ps` shows one or more nodes missing or with status `Exited`

### Diagnosis

```bash
# Check which containers are running
docker ps

# Check all containers including stopped ones
docker ps -a

# View exit logs for a stopped container
docker logs web_node
docker logs app_node
docker logs db_node
```

### Recovery

```bash
# Start a stopped container
docker start web_node
docker start app_node
docker start db_node

# If containers are missing entirely, re-provision with Terraform
cd terraform
terraform apply
```

### Verification

```bash
docker ps
# Expected: web_node, app_node, db_node all showing status 'Up'

ansible all -m ping
# Expected: all nodes return pong
```

---

## 3. Network Communication Issues

### Symptoms
- Containers cannot reach each other
- Ansible tasks fail with connection timeout
- Services on one node cannot connect to another

### Diagnosis

```bash
# Check Docker network exists
docker network ls
# Expected: a network named after the project (e.g. vpronet) should be listed

# Inspect the network and connected containers
docker network inspect vpronet

# Test connectivity between containers
docker exec web_node ping app_node
docker exec app_node ping db_node
```

### Recovery

```bash
# If the network is missing, destroy and re-provision
cd terraform
terraform destroy
terraform apply
```

If Ansible inventory IPs are stale after re-provisioning:

```bash
# Get current container IPs
docker inspect web_node | grep IPAddress
docker inspect app_node | grep IPAddress
docker inspect db_node | grep IPAddress

# Update ansible/inventory/hosts.ini with the new IPs
```

### Verification

```bash
docker exec web_node ping -c 2 app_node
docker exec app_node ping -c 2 db_node
ansible all -m ping
```

---

## 4. Nginx / Reverse Proxy Errors

### Symptoms
- HTTP requests to `web_node` return 502 Bad Gateway or 404
- Nginx service is not running
- Browser cannot connect on port 80

### Diagnosis

```bash
# Check Nginx service status
docker exec web_node systemctl status nginx

# View Nginx error logs
docker exec web_node cat /var/log/nginx/error.log

# Check Nginx config is valid
docker exec web_node nginx -t
```

### Recovery

```bash
# Restart Nginx
docker exec web_node systemctl restart nginx

# If config is broken, re-apply the web role
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/site.yml --limit web_node --tags web

# If the service won't start due to a port conflict
docker exec web_node ss -tlnp | grep :80
```

### Verification

```bash
# Check Nginx is active
docker exec web_node systemctl is-active nginx

# Test HTTP response
curl -I http://<web_node_ip>
# Expected: HTTP/1.1 200 OK
```

---

## 5. App Service Failures

### Symptoms
- Application is not responding
- Nginx returns 502 (upstream not available)
- App service is stopped or crashing

### Diagnosis

```bash
# Check app service status
docker exec app_node systemctl status <app-service-name>

# View application logs
docker exec app_node journalctl -u <app-service-name> --no-pager -n 50

# Check if the app process is running
docker exec app_node ps aux | grep <app-process>
```

### Recovery

```bash
# Restart the app service
docker exec app_node systemctl restart <app-service-name>

# Re-deploy the application via Ansible
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/site.yml --limit app_node --tags app
```

### Verification

```bash
docker exec app_node systemctl is-active <app-service-name>

# Confirm Nginx can reach the app upstream
curl -I http://<web_node_ip>
```

---

## 6. PostgreSQL Connection Issues

### Symptoms
- App logs show database connection errors
- `psql` connection refused or authentication failed
- `db_node` service is stopped

### Diagnosis

```bash
# Check PostgreSQL service status
docker exec db_node systemctl status postgresql

# Check PostgreSQL is listening
docker exec db_node ss -tlnp | grep 5432

# Test connection from app_node
docker exec app_node psql -h db_node -U <db_user> -d <db_name> -c '\conninfo'

# View PostgreSQL logs
docker exec db_node cat /var/log/postgresql/postgresql-*.log | tail -50
```

### Recovery

```bash
# Restart PostgreSQL
docker exec db_node systemctl restart postgresql

# If credentials or config are wrong, re-run the db role
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/site.yml --limit db_node --tags db
```

### Verification

```bash
docker exec db_node systemctl is-active postgresql

# Confirm port is open
docker exec db_node ss -tlnp | grep 5432

# Test connection from app_node
docker exec app_node psql -h db_node -U <db_user> -d <db_name> -c 'SELECT 1;'
# Expected: returns 1
```

---

## 7. Monitoring Failures

### Symptoms
- Grafana UI not loading on port 3000
- Prometheus targets showing `DOWN`
- No metrics data in dashboards

### Diagnosis

```bash
# Check node_exporter on each node
docker exec web_node systemctl status node_exporter
docker exec app_node systemctl status node_exporter
docker exec db_node systemctl status node_exporter

# Check Prometheus targets
# Open in browser: http://<prometheus_host>:9090/targets

# Check Grafana service
docker exec <monitoring_node> systemctl status grafana-server
```

### Recovery

```bash
# Restart node_exporter on a node
docker exec web_node systemctl restart node_exporter

# Restart Grafana
docker exec <monitoring_node> systemctl restart grafana-server

# Re-apply the common role to restore monitoring agents
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/site.yml --tags common
```

### Verification

```bash
# Confirm node_exporter is exposing metrics
docker exec web_node curl -s http://localhost:9100/metrics | head -10

# Confirm Prometheus can scrape targets
# Open: http://<prometheus_host>:9090/targets
# All targets should show state: UP

# Confirm Grafana is accessible
curl -I http://<grafana_host>:3000
```

**Default ports:**

| Service | Port |
|---------|------|
| node_exporter | 9100 |
| Prometheus | 9090 |
| Grafana | 3000 |

---

## 8. GitHub Actions / CI Failures

### Symptoms
- Push or PR triggers a failing workflow
- `ansible-lint` or `terraform validate` step is red

### Diagnosis

1. Go to the repository → **Actions** tab
2. Click the failing workflow run
3. Expand the failed step to read the error output

### Recovery — ansible-lint failures

```bash
# Install and run locally before pushing
pip install ansible-lint
ansible-lint ansible/playbooks/site.yml

# Fix any reported violations, then commit and push
```

### Recovery — terraform validate failures

```bash
cd terraform
terraform init
terraform validate
# Fix any reported errors, then commit and push
```

### Common causes

| Error | Fix |
|-------|-----|
| YAML indentation wrong | Check spacing — YAML requires consistent 2-space indent |
| Undefined variable in template | Add the variable to `role/defaults/main.yml` or `host_vars` |
| Deprecated Ansible module | Replace with the current module name from Ansible docs |
| Missing Terraform provider | Run `terraform init` to download required providers |

### Verification

Push the fix and confirm the workflow run goes green in the Actions tab.

---

## 9. Configuration Drift

### Symptoms
- Drift detection script reports `FAIL` or `MISSING`
- Service behaviour differs from expected baseline

### Diagnosis

```bash
# Run drift detection script
bash scripts/drift_detection.sh
```

The script checks:
- Installed packages
- Running services
- Open ports

### Recovery

```bash
# Re-apply Ansible to the affected node
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/site.yml --limit <node_name>

# Or re-apply everything (safe — Ansible is idempotent)
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/site.yml
```

### Verification

```bash
bash scripts/drift_detection.sh
# Expected: all checks return PASS / OK
```

---

## 10. Rollback Procedures

### Roll back an Ansible change

```bash
# Find the last known-good commit
git log --oneline ansible/

# Revert the Ansible files to that commit
git checkout <good-commit-hash> -- ansible/

# Re-run the playbook
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/site.yml
```

### Roll back infrastructure (Terraform)

```bash
cd terraform

# Destroy current infrastructure
terraform destroy

# Revert Terraform files if needed
git checkout <good-commit-hash> -- terraform/

# Re-provision
terraform init
terraform apply
```

> ⚠️ `terraform destroy` stops and removes all containers. In-container data will be lost. Use only when container state is unrecoverable.

### Full environment reset

```bash
# Step 1: Destroy all containers
cd terraform && terraform destroy && cd ..

# Step 2: Pull latest main
git checkout main && git pull origin main

# Step 3: Re-provision
cd terraform && terraform apply && cd ..

# Step 4: Re-configure
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/site.yml

# Step 5: Verify
bash scripts/drift_detection.sh
```

---

## 11. Quick Reference

### Common commands

| Task | Command |
|------|---------|
| Activate virtualenv | `source ansible-env/bin/activate` |
| Test all nodes reachable | `ansible all -m ping` |
| Run full playbook | `ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/site.yml` |
| Target a single node | `... --limit web_node` |
| Provision infrastructure | `cd terraform && terraform apply` |
| Destroy infrastructure | `cd terraform && terraform destroy` |
| Check running containers | `docker ps` |
| Run drift detection | `bash scripts/drift_detection.sh` |
| Verbose playbook debug | `ansible-playbook ... -vvv` |
| Lint playbooks locally | `ansible-lint ansible/playbooks/site.yml` |
| Validate Terraform | `cd terraform && terraform validate` |

### Default ports

| Service | Port | Node |
|---------|------|------|
| Nginx (HTTP) | 80 | web_node |
| node_exporter | 9100 | All nodes |
| Prometheus | 9090 | Monitoring node |
| Grafana | 3000 | Monitoring node |
| PostgreSQL | 5432 | db_node |

---

*Resolves [#16](https://github.com/KingKabari/SCA-DevOps-Capstone-Project/issues/16)*
