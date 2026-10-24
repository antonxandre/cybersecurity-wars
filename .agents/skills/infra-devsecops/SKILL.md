---
name: infra-devsecops
description: Cloud infrastructure, Docker containerization, Nginx reverse proxy with SSL/TLS and Post-Quantum Cryptography (PQC), Fail2Ban SSH hardening, and GitHub Actions CI/CD pipelines. Use when modifying Dockerfiles, docker-compose.yml, Nginx configurations, deployment workflows, or server security settings.
---

# Infrastructure & DevSecOps Guide (Eixo 1 & CI/CD)

This skill documents the cloud infrastructure, containerization, and automated deployment pipeline requirements specified in `docs/arquitetura_e_diretrizes.md`.

## 1. Cloud Architecture (GCP Compute Engine Ubuntu 24.04 LTS)

- **Compute**: VM in GCP Compute Engine (Free Tier eligible: e2-micro or e2-small).
- **Hardening Rules**:
  - SSH root login disabled (`PermitRootLogin no`) and password auth disabled (`PasswordAuthentication no`).
  - Ed25519 or RSA 4096-bit cryptographic keys only.
  - Fail2Ban configured for SSH (`port 22`, `maxretry = 4`, `bantime = 86400` / 24 hours, `findtime = 600`).
  - GCP VPC Firewall: Open only `TCP 80` (HTTP redirect), `TCP 443` (HTTPS), and `TCP 22` (SSH).

## 2. Nginx Reverse Proxy, SSL & Post-Quantum Cryptography (PQC)

- **Nginx configuration**:
  - Redirect all HTTP (`port 80`) to HTTPS (`port 443`) with `301 Moved Permanently`.
  - Proxy `/api` and `/arena` to the NestJS backend container (`http://backend:3000`).
  - Serve Flutter Web static release bundle at root `/`.
  - Security headers:
    - `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`
    - `X-Frame-Options: DENY`
    - `X-Content-Type-Options: nosniff`
  - Post-Quantum Cryptography:
    - Group suites with hybrid quantum-resistant key exchanges: `ssl_ecdh_curve X25519MLKEM768:x25519:secp384r1;`
    - Automated renewal with Certbot for public IP / domain (`certbot renew --quiet`).

## 3. Containerization (Docker & docker-compose)

- Multi-stage builds for NestJS and Flutter Web:
  - Stage 1: Build & test artifacts in a clean Node/Flutter image.
  - Stage 2: Minimal production runtime (Alpine/Distroless). Non-root user execution (`USER node`).
- `docker-compose.yml` orchestrates:
  1. `postgres`: PostgreSQL 16+ database with healthchecks and persistent volumes.
  2. `backend`: NestJS API container connected to `postgres`.
  3. `nginx`: Reverse proxy and TLS terminator.

## 4. GitHub Actions CI/CD Pipeline

- Trigger on push to `main`.
- Secrets configured in GitHub Secrets (`GCP_VM_IP`, `GCP_SSH_USER`, `GCP_SSH_PRIVATE_KEY`).
- Steps:
  1. Checkout repository
  2. Run Flutter analyze & build web
  3. Run NestJS lint & tests
  4. Build Docker container images
  5. Deploy via SSH Action executing `docker compose up -d --build` and zero-downtime Nginx reload.
