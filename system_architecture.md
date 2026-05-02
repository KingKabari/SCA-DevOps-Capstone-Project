# System Architecture Documentation

## Project Overview

This is a **three-tier DevOps demonstration project** that provisions and configures a complete application stack using Infrastructure as Code (IaC) and Configuration Management principles. The project simulates a production environment using Docker containers as virtual servers, managed by Terraform and Ansible.

### Architecture Pattern: Three-Tier Web Application

![system Architecture](./images/SCA_devops_ansible_system_architecture.png.png)
```
┌─────────────────────────────────────────────────────────────────────┐
│ EXTERNAL ACCESS │
│ (Browser / API Client / cURL) │
└─────────────────┬───────────────────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────────────┐
│ PRESENTATION TIER │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ WEB NODE │ │
│ │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│ │ │ Nginx │ │ Port 80/443 │ │ Reverse Proxy Config│ │ │
│ │ │ Server │ │ (exposed) │ │ Load Balancing │ │ │
│ │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│ │ │ │
│ │ Monitoring: node_exporter (Port 9100) │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────┬───────────────────────────────────────────────────┘
│
│ HTTP/HTTPS (Internal Network)
│
▼
┌─────────────────────────────────────────────────────────────────────┐
│ APPLICATION TIER │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ APP NODE │ │
│ │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│ │ │ Flask │ │ Port 5000 │ │ Python App Logic │ │ │
│ │ │ Application │ │ (internal) │ │ REST API │ │ │
│ │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│ │ │ │
│ │ Dependencies: Flask 3.0.0, psycopg2-binary │ │
│ │ Monitoring: node_exporter (Port 9100) │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────┬───────────────────────────────────────────────────┘
│
│ PostgreSQL Protocol (Port 5432)
│
▼
┌─────────────────────────────────────────────────────────────────────┐
│ DATA TIER │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ DB NODE │ │
│ │ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │ │
│ │ │ PostgreSQL │ │ Port 5432 │ │ Database: myapp │ │ │
│ │ │ Database │ │ (internal) │ │ User: myuser │ │ │
│ │ └─────────────┘ └─────────────┘ └─────────────────────┘ │ │
│ │ │ │
│ │ Configuration: listen_addresses = '*' │ │
│ │ Monitoring: node_exporter (Port 9100) │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## Infrastructure Layer (Terraform)

### Container Provisioning Architecture
```
┌─────────────────────────────────────────────────────────────────────┐
│ DOCKER HOST │
│ │
│ ┌────────────────────────────────────────────────────────────┐ │
│ │ Docker Network: app_network │ │
│ │ Driver: bridge │ │
│ │ Internal: false (configurable) │ │
│ └────────────────────────────────────────────────────────────┘ │
│ │
│ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ │
│ │ web_node │ │ app_node │ │ db_node │ │
│ │ │ │ │ │ │ │
│ │ Image: │ │ Image: │ │ Image: │ │
│ │ ubuntu:22.04 │ │ ubuntu:22.04 │ │ ubuntu:22.04 │ │
│ │ │ │ │ │ │ │
│ │ Command: │ │ Command: │ │ Command: │ │
│ │ sleep inf │ │ sleep inf │ │ sleep inf │ │
│ │ │ │ │ │ │ │
│ │ Ports: │ │ Networks: │ │ Networks: │ │
│ │ 80:8080 │ │ app_network │ │ app_network │ │
│ │ │ │ │ │ │ │
│ │ Healthcheck: │ │ Healthcheck: │ │ Healthcheck: │ │
│ │ curl /health │ │ curl /health │ │ pg_isready │ │
│ └──────────────┘ └──────────────┘ └──────────────┘ │
│ │
│ Restart Policy: unless-stopped │
│ Healthcheck Start Period: 180s (allows Ansible provisioning) │
└─────────────────────────────────────────────────────────────────────┘
```

### Terraform Provisioning Workflow
```
┌─────────────────────────────────────────────────────────────────────┐
│ TERRAFORM ENVIRONMENT │
│ │
│ ┌─────────────────────────┐ ┌─────────────────────────┐ │
│ │ Local Machine / Runner │ │ Terraform State File │ │
│ │ │ │ (terraform.tfstate) │ │
│ │ cd terraform/ │ │ Stores resource metadata │ │
│ │││
│ │ terraform init │─────────────────────────┘
│ │ │ │
│ │ terraform plan │ │
│ │ │ │
│ │ terraform apply │ │
│ └─────────────────────────┘ └─────────────────────────┘
│ │
│ Action │ Result │
│──────────┬──────────┬──────────┬─────────────────────│
│ init │ Initialize │ Downloads │
│ │ Terraform │ provider │
│ ────────────────────────────────────────────────────────── │
│ plan │ Dry-run │ Preview │
│ │ │ infrastructure │
│ │ │ changes │
│ ────────────────────────────────────────────────────────── │
│ apply │ Provision │ Creates Docker │
│ │ Infrastructure │ network, containers, │
│ │ │ ports, and mounts │
│ │ │ │
│ ────────────────────────────────────────────────────────── │
│ destroy │ Clean │ Removes all provisioned │
│ │ Infrastructure │ resources │
│ └──────────────────────────────────────────────────────────┘
```

### Terraform Resources

| Resource Type | Resource Name | Purpose |
|--------------|---------------|---------|
| `docker_network` | `app_network` | Isolated network for inter-container communication |
| `docker_container` | `web_node` | Web server container with port 80 exposed |
| `docker_container` | `app_node` | Application server container |
| `docker_container` | `db_node` | Database server container |

### Terraform Configuration Variables

```yaml
Infrastructure Variables:
  - image: "ubuntu:22.04" (fallback base image)
  - image_web, image_app, image_db: Service-specific overrides
  - network_name: "app_network"
  - network_driver: "bridge"
  - network_internal: false
  - restart_policy: "unless-stopped"
  - web_host_port: 8080 (mapped to container port 80)
  - web_container_port: 80
  - app_container_port: 5000
  - db_container_port: 5432
  - healthcheck_start_period: "180s"
```
## Configuration Management Layer (Ansible)
Ansible Architecture

```text
┌─────────────────────────────────────────────────────────────────────┐
│                      ANSIBLE CONTROL NODE                            │
│                                                                      │
│  Inventory: hosts.ini                                                │
│  ├── [web] web_node                                                  │
│  ├── [app] app_node                                                  │
│  ├── [db] db_node                                                    │
│  └── [all:vars] ansible_user=root, ansible_shell_type=sh            │
│                                                                      │
│  Playbook: site.yml                                                  │
│  ├── Base infrastructure setup (common role)                         │
│  ├── Gather facts after Python install                               │
│  ├── Post-bootstrap validation                                       │
│  ├── Configure db node (db role)                                     │
│  ├── Configure app node (app role)                                   │
│  └── Configure web node (web role)                                   │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ SSH (or Docker Connection)
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         MANAGED NODES                                 │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    COMMON ROLE (All Nodes)                   │    │
│  │  • Bootstrap Python installation (raw module)               │    │
│  │  • Configure apt sources (HTTP → HTTPS transition)          │    │
│  │  • Install CA certificates and base dependencies            │    │
│  │  • Create application user (appuser)                        │    │
│  │  • Setup node_exporter for monitoring                       │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │    WEB ROLE      │  │    APP ROLE      │  │    DB ROLE       │  │
│  │                  │  │                  │  │                  │  │
│  │ • Install nginx  │  │ • Install pip    │  │ • Install        │  │
│  │ • Deploy nginx   │  │ • Create venv    │  │   PostgreSQL     │  │
│  │   config (J2)    │  │ • Install Flask  │  │ • Create DB      │  │
│  │ • Start nginx    │  │   & psycopg2     │  │ • Create DB user │  │
│  │ • Restart nginx  │  │ • Deploy app.py  │  │ • Grant          │  │
│  │   handler        │  │ • Create .env    │  │   privileges     │  │
│  │                  │  │ • Start Flask    │  │ • Configure      │  │
│  │                  │  │ • Verify port    │  │   postgresql.conf│  │
│  │                  │  │   5000           │  │ • Configure      │  │
│  │                  │  │                  │  │   pg_hba.conf    │  │
│  │                  │  │                  │  │ • Restart handler│  │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```
Networking Architecture
Container Communication Flow
```text
                    ┌─────────────────────────────────────┐
                    │      Docker Bridge Network          │
                    │        (app_network)                │
                    │       Subnet: 172.x.0.0/16         │
                    └─────────────────────────────────────┘
                                    │
            ┌───────────────────────┼───────────────────────┐
            │                       │                       │
            ▼                       ▼                       ▼
    ┌─────────────┐         ┌─────────────┐         ┌─────────────┐
    │  web_node   │         │  app_node   │         │   db_node   │
    │             │         │             │         │             │
    │ IP: 172.x.1 │◄───────►│ IP: 172.x.2 │◄───────►│ IP: 172.x.3 │
    │             │  Port   │             │  Port   │             │
    │ Port 80     │  5000   │ Port 5000   │  5432   │ Port 5432   │
    │ (internal)  │         │ (internal)  │         │ (internal)  │
    └──────┬──────┘         └─────────────┘         └─────────────┘
           │
           │ Port Mapping: 80:8080
           ▼
    ┌─────────────┐
    │ Host Machine│
    │ Port 8080   │
    └─────────────┘
    ```
## CI/CD Pipeline (GitHub Actions)
![Deployment Sequence Diagram](./images/Deployment_Sequence_Diagram.png)
```text
┌─────────────────────────────────────────────────────────────────────┐
│                        GITHUB ACTIONS CI/CD                          │
│                                                                      │
│  Trigger: Push to main, Pull Requests                                │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    Job 1: Lint Ansible                       │    │
│  │  • Setup Python and Ansible                                  │    │
│  │  • Run ansible-lint on all playbooks and roles              │    │
│  │  • Check YAML syntax and best practices                     │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    Job 2: Validate Terraform                 │    │
│  │  • Setup Terraform                                           │    │
│  │  • Run terraform init                                        │    │
│  │  • Run terraform validate                                    │    │
│  │  • Check infrastructure configuration                        │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
Monitoring Architecture
text
┌─────────────────────────────────────────────────────────────────────┐
│                         MONITORING STACK                             │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    node_exporter (Port 9100)                 │    │
│  │                                                              │    │
│  │  Deployed on: web_node, app_node, db_node                   │    │
│  │  Metrics Collected:                                          │    │
│  │  • CPU usage and load average                                │    │
│  │  • Memory utilization                                        │    │
│  │  • Disk I/O and space                                        │    │
│  │  • Network traffic                                           │    │
│  │  • System uptime and processes                               │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                              │                                       │
│                              │ Scraping (Pull Model)                 │
│                              ▼                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    Prometheus (Port 9090)                    │    │
│  │                                                              │    │
│  │  • Time-series database                                      │    │
│  │  • Metrics aggregation and storage                          │    │
│  │  • Alert management                                          │    │
│  │  • Query language (PromQL)                                   │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                              │                                       │
│                              │ Data Source                           │
│                              ▼                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                     Grafana (Port 3000)                      │    │
│  │                                                              │    │
│  │  • Interactive dashboards                                    │    │
│  │  • Visualization and analytics                               │    │
│  │  • Alerting and notifications                                │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```
## Data Flow Architecture
Request Flow (User → Response)
```text
Step 1: HTTP Request
┌──────────┐    GET /api/data    ┌──────────────┐
│  Client  │ ──────────────────► │ Host :8080   │
└──────────┘                     └──────┬───────┘
                                        │
                                        │ Docker Port Mapping
                                        ▼
Step 2: Nginx Reverse Proxy
┌──────────┐    Proxy Pass       ┌──────────────┐
│ web_node │ ──────────────────► │ app_node:5000│
│ Port 80  │    /api/*           └──────┬───────┘
└──────────┘                            │
                                        │
                                        ▼
Step 3: Flask Application
┌──────────┐    SQL Query        ┌──────────────┐
│ app_node │ ──────────────────► │ db_node:5432 │
│ Flask    │    SELECT * FROM    └──────┬───────┘
└──────────┘    users                  │
                                        │
                                        ▼
Step 4: Database Response
┌──────────┐    JSON Response    ┌──────────────┐
│ app_node │ ◄────────────────── │   PostgreSQL │
│ Flask    │    Row Data         │   Database   │
└────┬─────┘                     └──────────────┘
     │
     │ HTTP Response
     ▼
┌──────────┐    JSON Response    ┌──────────────┐
│  Client  │ ◄────────────────── │   web_node   │
└──────────┘    via Nginx        │   (reverse   │
                                  │    proxy)    │
                                  └──────────────┘
Database Connection Flow
text
                    app_node                          db_node
                ┌─────────────┐                   ┌─────────────┐
                │   Flask     │                   │ PostgreSQL  │
                │ Application │                   │   Server    │
                └──────┬──────┘                   └──────▲──────┘
                       │                                 │
                       │ 1. psycopg2.connect()           │
                       │    (host=db_node, port=5432)    │
                       │ ──────────────────────────────► │
                       │                                 │
                       │ 2. Authentication               │
                       │    (user/password from .env)    │
                       │ ──────────────────────────────► │
                       │                                 │
                       │ 3. SQL Query Execution          │
                       │    (SELECT, INSERT, UPDATE)     │
                       │ ──────────────────────────────► │
                       │                                 │
                       │ 4. Result Set Returned          │
                       │ ◄────────────────────────────── │
                       │                                 │
                       │ 5. Connection Closed            │
                       │ ──────────────────────────────► │
                       │                                 │
                ┌──────┴──────┐                   ┌──────┴──────┐
                │ Response    │                   │ Transaction │
                │ Formatted   │                   │   Log       │
                │ as JSON     │                   │             │
                └─────────────┘                   └─────────────┘
```
## Security Architecture
```text
┌─────────────────────────────────────────────────────────────────────┐
│                         SECURITY LAYERS                              │
│                                                                      │
│  Layer 1: Network Isolation                                         │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │ • Docker bridge network isolates containers from host       │    │
│  │ • No direct external access to app and db containers       │    │
│  │ • Only web container exposes port to host                   │    │
│  │ • Internal network mode configurable (network_internal)     │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  Layer 2: Secrets Management                                        │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │ • Database credentials stored in .env file                  │    │
│  │ • .env file permissions: 0600 (owner read/write only)       │    │
│  │ • Credentials passed via Ansible variables (encrypted)      │    │
│  │ • No hardcoded secrets in source code                       │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  Layer 3: Access Control                                            │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │ • Dedicated application user (appuser) for file ownership   │    │
│  │ • PostgreSQL authentication via md5 method                  │    │
│  │ • pg_hba.conf restricts database access to app_node only    │    │
│  │ • No root processes running applications (except Ansible)   │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  Layer 4: Package Security                                          │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │ • HTTPS apt sources for secure package downloads            │    │
│  │ • ca-certificates package ensures trusted connections       │    │
│  │ • Version-pinned dependencies (Flask==3.0.0)                │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```
## Deployment Flow
```text
┌─────────────────────────────────────────────────────────────────────┐
│                    COMPLETE DEPLOYMENT PROCESS                       │
│                                                                      │
│  Phase 1: Infrastructure Provisioning (Terraform)                   │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │ 1. terraform init                                            │    │
│  │ 2. terraform plan                                            │    │
│  │ 3. terraform apply                                           │    │
│  │    → Creates Docker network                                  │    │
│  │    → Creates web_node container (sleep infinity)             │    │
│  │    → Creates app_node container (sleep infinity)             │    │
│  │    → Creates db_node container (sleep infinity)              │    │
│  │ 4. Outputs container IP addresses                            │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                              │                                       │
│                              ▼                                       │
│  Phase 2: Pre-Configuration Setup                                   │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │ 1. Activate Python virtual environment                      │    │
│  │ 2. Install Ansible and dependencies                         │    │
│  │ 3. Update inventory hosts.ini with container IPs           │    │
│  │ 4. Test connectivity: ansible all -m ping                  │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                              │                                       │
│                              ▼                                       │
│  Phase 3: Configuration Management (Ansible)                        │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │ 1. ansible-playbook playbooks/site.yml                      │    │
│  │                                                              │    │
│  │    [common role - all nodes]                                │    │
│  │    → Python installation and apt configuration              │    │
│  │    → App user creation                                       │    │
│  │                                                              │    │
│  │    [db role - db_node]                                      │    │
│  │    → PostgreSQL installation and configuration              │    │
│  │    → Database and user creation                             │    │
│  │                                                              │    │
│  │    [app role - app_node]                                    │    │
│  │    → Virtual environment and dependencies                   │    │
│  │    → Flask application deployment                           │    │
│  │                                                              │    │
│  │    [web role - web_node]                                    │    │
│  │    → Nginx installation and reverse proxy config            │    │
│  │                                                              │    │
│  │ 2. Post-deployment validation                               │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                              │                                       │
│                              ▼                                       │
│  Phase 4: Validation (Drift Detection)                              │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │ 1. bash scripts/drift-check.sh                              │    │
│  │    → Verify containers running                               │    │
│  │    → Check nginx installation and status                    │    │
│  │    → Verify app port 5000                                    │    │
│  │    → Verify PostgreSQL port 5432                             │    │
│  │ 2. Manual verification                                      │    │
│  │    → curl http://localhost:8080/health                      │    │
│  │    → curl http://localhost:8080/db-check                    │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```
## File Structure Architecture
```text
SCA-DevOps-Capstone-Project/
│
├── .github/                         # CI/CD Configuration
│   ├── workflows/
│   │   └── ci.yml                  # GitHub Actions pipeline
│   ├── ISSUE_TEMPLATE/              # Issue templates
│   └── PULL_REQUEST_TEMPLATE.md    # PR template
│
├── terraform/                       # Infrastructure as Code
│   ├── main.tf                     # Container definitions
│   ├── variables.tf                # Input variables
│   ├── outputs.tf                  # Output values (IPs)
│   ├── providers.tf                # Provider configuration
│   ├── terraform.tfvars.example    # Variable examples
│   └── .terraform.lock.hcl         # Dependency lock file
│
├── ansible/                         # Configuration Management
│   ├── ansible.cfg                 # Ansible configuration
│   ├── inventory/
│   │   └── hosts.ini               # Dynamic inventory
│   ├── playbooks/
│   │   └── site.yml                # Main playbook
│   └── roles/
│       ├── common/                 # Base setup for all nodes
│       │   └── tasks/main.yml
│       ├── web/                    # Nginx configuration
│       │   ├── tasks/main.yml
│       │   ├── handlers/main.yml
│       │   └── templates/nginx.conf.j2
│       ├── app/                    # Flask application
│       │   ├── tasks/main.yml
│       │   ├── handlers/main.yml
│       │   ├── files/app.py
│       │   └── vars/main.yml.example
│       └── db/                     # PostgreSQL database
│           ├── tasks/main.yml
│           ├── handlers/main.yml
│           └── vars/main.yml
│
├── scripts/
│   └── drift-check.sh              # Drift detection script
│
├── README.md                        # Project documentation
├── RUNBOOK.md                       # Operations runbook
├── requirements.txt                 # Python dependencies
├── .gitignore                      # Git ignore rules
├── .editorconfig                   # Editor configuration
└── LICENSE 
```                   # MIT License
## Technology Stack Summary
```
Layer	Technology	Version/Purpose
Infrastructure	Terraform	v1.10+ (Docker provider v4.2.0)
Infrastructure	Docker	Container runtime
Configuration	Ansible	v13.5.0 (Configuration management)
Web Server	Nginx	Reverse proxy and static file serving
Application	Python/Flask	v3.0.0 (REST API framework)
Database	PostgreSQL	v14 (Relational database)
Monitoring	node_exporter	v1.x (System metrics)
Monitoring	Prometheus	Metrics collection (planned)
Monitoring	Grafana	Visualization (planned)
CI/CD	GitHub Actions	Linting and validation
Language	Python	v3.x (Application and tooling)
Language	Bash	Drift detection scripts
```