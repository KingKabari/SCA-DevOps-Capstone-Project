# Ansible-Driven Environment Provisioner

## Overview
This capstone project demonstrates a real-world DevOps workflow using Terraform and Ansible together.

- Terraform is used to provision infrastructure
- Ansible is used to configure and manage that infrastructure

The project simulates a production-like environment using Docker containers.

---

## Project Architecture

We simulate 3 servers:

- Web Server (Nginx)
- App Server (Application logic)
- Database Server

Infrastructure is provisioned using Terraform and configured using Ansible.

Monitoring is implemented using Prometheus and Grafana.

---

## Tech Stack

- Terraform (Infrastructure provisioning)
- Ansible (Configuration management)
- Docker (Containerized environment)
- Prometheus (Monitoring)
- Grafana (Visualization)
- Bash (Drift detection script)
- GitHub Actions (CI/CD)

---

## Project Components

### 1. Infrastructure (Terraform)
- Create Docker network
- Provision 3 containers (web, app, db)
- Output container IPs for Ansible

---

### 2. Configuration (Ansible)
- Install required packages
- Configure Nginx (web)
- Deploy app (app server)
- Configure database (db)
- Create users
- Set up cron jobs

---

### 3. Ansible Roles
- common (shared setup)
- web (nginx setup)
- app (application deployment)
- db (database setup)

---

### 4. Monitoring
- Install node_exporter on all nodes
- Setup Prometheus server
- Setup Grafana dashboards

---

### 5. Drift Detection
- Bash script to check:
  - Installed packages
  - Running services
  - Open ports

---

### 6. CI/CD
- GitHub Actions:
  - ansible-lint
  - terraform validate

---

### 7. Runbook
Document solutions for:
- Node unreachable
- Config drift
- Playbook failure
- Rollback steps

---

### 8. AWS Design (Theory)
- Terraform → VPC, EC2, RDS
- Ansible → EC2 config
- AWS SSM as alternative to Ansible

---

## Contribution Guide

- Clone the repository
- Create a new branch before working
- Use clear commit messages
- Avoid working directly on main

---

## Project Contributors

- https://github.com/Ddataguru
- https://github.com/KingKabari
- https://github.com/munshakakusi
- https://github.com/Woyengidinipre
- https://github.com/Abbanks


---

## Goal
To demonstrate full DevOps lifecycle:
Provision → Configure → Monitor → Validate → Document
