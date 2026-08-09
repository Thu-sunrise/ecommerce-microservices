<p align="center">
  <picture>
    <source media="(prefers-color-scheme: light)" srcset="https://socialify.git.ci/hoangtien2k3/ecommerce-microservices/image?description=1&descriptionEditable=%E2%9A%A1%EF%B8%8F%2013%20Microservices%20%E2%80%A2%20Spring%20Boot%203%20%E2%80%A2%20Kubernetes&font=Inter&forks=1&language=1&logo=https%3A%2F%2Fi.ibb.co%2FN366vtQ%2Fhoangtien2k3.png&owner=1&pattern=Floating%20Cogs&pulls=1&stargazers=1&theme=Light"/>
    <source media="(prefers-color-scheme: dark)" srcset="https://socialify.git.ci/hoangtien2k3/ecommerce-microservices/image?description=1&descriptionEditable=%E2%9A%A1%EF%B8%8F%2013%20Microservices%20%E2%80%A2%20Spring%20Boot%203%20%E2%80%A2%20Kubernetes&font=Inter&forks=1&language=1&logo=https%3A%2F%2Fi.ibb.co%2FN366vtQ%2Fhoangtien2k3.png&owner=1&pattern=Floating%20Cogs&pulls=1&stargazers=1&theme=Dark"/>
    <img alt="ecommerce-microservices" src="https://socialify.git.ci/hoangtien2k3/ecommerce-microservices/image?description=1&descriptionEditable=%E2%9A%A1%EF%B8%8F%2013%20Microservices%20%E2%80%A2%20Spring%20Boot%203%20%E2%80%A2%20Kubernetes&font=Inter&forks=1&language=1&logo=https%3A%2F%2Fi.ibb.co%2FN366vtQ%2Fhoangtien2k3.png&owner=1&pattern=Floating%20Cogs&pulls=1&stargazers=1&theme=Auto"/>
  </picture>
</p>

<p align="center">
  <a href="https://sonarcloud.io/project/configuration?id=hoangtien2k3_ecommerce-microservices">
    <img src="https://sonarcloud.io/api/project_badges/measure?project=hoangtien2k3_ecommerce-microservices&metric=alert_status" alt="Quality Gate">
  </a>
  <a href="https://sonarcloud.io/project/configuration?id=hoangtien2k3_ecommerce-microservices">
    <img src="https://sonarcloud.io/api/project_badges/measure?project=hoangtien2k3_ecommerce-microservices&metric=sqale_index" alt="Maintainability">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License">
  </a>
  <a href="https://github.com/hoangtien2k3/ecommerce-microservices/releases">
    <img src="https://img.shields.io/github/v/release/hoangtien2k3/ecommerce-microservices" alt="Release">
  </a>
  <a href="https://github.com/hoangtien2k3/ecommerce-microservices/stargazers">
    <img src="https://img.shields.io/github/stars/hoangtien2k3/ecommerce-microservices?style=social" alt="Stars">
  </a>
</p>

---

## 📋 Overview

**ecommerce-microservices** is a production-grade, cloud-native e-commerce platform built with a microservice architecture. It consists of **13 Spring Boot 3** backend services, an **Apache APISIX** API Gateway, a **Next.js 16** frontend, and a full suite of infrastructure — all deployable on **Kubernetes (k3d/K3s)**.

This forked version introduces a robust **Monorepo structure**, advanced **Infrastructure as Code (Terraform)**, and extensive **Automated Testing & Chaos Engineering** using Istio and K6.

|                   |                                                    |
|-------------------|----------------------------------------------------|
| ⚡ **Backend**     | 13 microservices · Java 21 · Spring Boot 3.3.5     |
| 🚪 **Gateway**    | Apache APISIX 3.9 · Istio Service Mesh             |
| 🗄️ **Databases** | PostgreSQL 16 · Redis 7 · Elasticsearch 8          |
| 📨 **Messaging**  | Apache Kafka 3.9 (KRaft mode, no Zookeeper)        |
| 🔐 **Auth**       | Keycloak 26 · OAuth2 / OIDC · JWT                  |
| ☁️ **Storage**    | RustFS (S3-compatible)                             |
| 🐳 **Deploy**     | Terraform · k3d / Kubernetes · ArgoCD              |
| 🧪 **Testing**    | Chaos Engineering (Istio) · K6 Load Testing        |

---

## 🛠️ Technology Stack

### Backend

|                   |                                                                  |
|-------------------|------------------------------------------------------------------|
| **Runtime**       | Java 21 (Virtual Threads)                                        |
| **Framework**     | Spring Boot 3.3.5, Spring Security 6, Spring Data JPA            |
| **Database**      | PostgreSQL 16, Liquibase migrations                              |
| **Search**        | Elasticsearch 8, Spring Data Elasticsearch                       |
| **Messaging**     | Apache Kafka 3.9 (KRaft), Spring Kafka                           |
| **Security**      | Keycloak 26, OAuth2 / OIDC, JWT, Spring Security Resource Server |
| **Gateway**       | Apache APISIX 3.9 (OpenID Connect, rate limiting, CORS)          |
| **Storage**       | RustFS (S3-compatible), AWS SDK v2                               |
| **Observability** | Micrometer, Prometheus, Spring Boot Actuator                     |
| **API Docs**      | Springdoc OpenAPI 3, Swagger UI w/ PKCE                          |
| **Resilience**    | Resilience4j (circuit breaker, retry)                            |
| **Build**         | Maven, Jib (Dockerless containerization)                         |

### Frontend

|               |                              |
|---------------|------------------------------|
| **Framework** | Next.js 16.2, React 19.2     |
| **State**     | Zustand 5, TanStack Query 5  |
| **Styling**   | Tailwind CSS 4, Lucide icons |
| **HTTP**      | Axios                        |

### Infrastructure & QA (New Additions)

|                |                                               |
|----------------|-----------------------------------------------|
| **Local K8s**  | k3d (K3s in Docker), NGINX Ingress Controller |
| **IaC**        | Terraform (AWS Provider configuration)        |
| **Mesh/Proxy** | Istio 1.23.0, HA-Proxy                        |
| **Chaos/QA**   | Istio Fault Injection, K6 (HPA testing)       |

---

## 🚀 Quick Start

### Prerequisites

- [Docker Desktop](https://www.docker.com/get-started) (macOS / Windows) or Docker Engine (Linux)
- 8 GB+ RAM allocated to Docker
- **Terraform** & **AWS CLI** (Only required for Production Deployment)

### 1. Local Development Setup (k3d)

The fastest way to test the platform locally using `k3d`.

```bash
git clone https://github.com/hoangtien2k3/ecommerce-microservices.git
cd ecommerce-microservices
bash scripts/start-ecommerce.sh
```

The script automatically:
1. Installs k3d and kubectl (if missing)
2. Creates a local Kubernetes cluster
3. Deploys NGINX Ingress Controller
4. Applies secrets, config maps, and infrastructure (PostgreSQL, Redis, Kafka, Elasticsearch, Keycloak)
5. Deploys APISIX gateway + all 13 backend services + frontend
6. Updates `/etc/hosts`

Wait ~5 minutes for all pods to become ready:
```bash
kubectl get pods -n ecommerce -w
```

### 2. Production Deployment Setup (Terraform + K3s)

This project supports automated cloud infrastructure provisioning via **Terraform** (AWS EC2 instances) and a robust **K3s** cluster deployment for a production-like environment.

**Step 1: Provision Cloud Infrastructure (AWS)**
```bash
cd infrastructure/terraform
terraform init
terraform apply
```

**Step 2: Deploy K3s Cluster & Services**
Once Terraform successfully provisions the EC2 instances, use the deployment script to setup the K3s cluster and deploy all microservices:
```bash
cd ../../
bash scripts/deploy-k3s-cluster.sh
```

### URLs

| Service               | URL                                                                                           |
|-----------------------|-----------------------------------------------------------------------------------------------|
| 🏠 **Frontend**       | [http://ecommerce.local](http://ecommerce.local)                                              |
| 🚪 **API Gateway**    | [http://api.ecommerce.local](http://api.ecommerce.local)                                      |
| 🔐 **Keycloak Admin** | [http://keycloak.ecommerce.local](http://keycloak.ecommerce.local/admin/master/console)       |

---

## 📁 Project Structure (Monorepo)

```
ecommerce-microservices/
├── apps/                           # Microservices & Frontend
│   ├── auth-service/               #   Port 8088
│   ├── frontend/                   #   Next.js 16 application
│   ├── order-service/              #   Port 8084
│   ├── product-service/            #   Port 8086
│   └── ... (13 services total)
├── infrastructure/                 # Deployment & Infrastructure configs
│   ├── k8s/                        #   Kubernetes manifests (ArgoCD, gateway, ingress)
│   ├── terraform/                  #   Terraform IaC modules
│   ├── docker/                     #   Docker configs (Postgres, Keycloak, etc.)
│   └── istio-1.23.0/               #   Istio Service Mesh configurations
├── packages/                       # Shared libraries
│   └── common-lib/                 #   Core, security, logging, kafka, storage modules
├── scripts/                        # Automation & deployment scripts
│   ├── start-ecommerce.sh          #   Entry point for local cluster
│   ├── k3d-setup.sh                #   One-shot K8s deployment script
│   └── deploy-k3s-cluster.sh       #   Production K3s deployment script
├── tests/                          # Automated testing & Chaos Engineering
│   ├── ha-proxy/                   #   HA Proxy & Load balancing tests
│   ├── hpa/                        #   Horizontal Pod Autoscaling tests with k6
│   ├── istio-chaos/                #   Istio chaos engineering (Fault Injection)
│   ├── istio-routing/              #   Istio traffic routing & split tests
│   └── security/                   #   mTLS & security tests
├── docker-compose.yml              # Full-stack local orchestration
├── Makefile                        # Build & deploy automation
└── pom.xml                         # Parent POM
```

---

## 🧪 Automated Testing & Chaos Engineering

This repository includes a comprehensive suite of tests to ensure system resilience, scalability, and security. Navigate to the `tests/` directory to explore:

1. **Chaos Engineering (`istio-chaos`)**: Uses Istio's fault injection to simulate network delays and HTTP 500 Abort errors. Ensures frontend and backend gracefully handle degraded service.
2. **Horizontal Pod Autoscaling (`hpa`)**: Utilizes `k6` to generate massive concurrent traffic, triggering Kubernetes HPA to scale pods up and down automatically based on CPU/Memory metrics.
3. **Traffic Routing (`istio-routing`)**: Validates Istio's ability to perform A/B testing, Canary deployments, and premium user traffic shaping.
4. **High Availability (`ha-proxy`)**: Tests load balancing and failover mechanisms across multiple pod replicas.
5. **Security (`security`)**: Verifies Istio strict mTLS (Mutual TLS) enforcing encrypted communication between microservices.

---

## 📊 Observability

Every service exposes:

- **Health:** `/actuator/health` (liveness + readiness on port 9000)
- **Metrics:** `/actuator/prometheus` (Micrometer + Prometheus)
- **Distributed Tracing:** Correlation ID (`X-Correlation-Id`) propagated across all services
- **APISIX Metrics:** Prometheus metrics on port 9091

---

## 📈 Stats

<a href="https://star-history.com/#hoangtien2k3/ecommerce-microservices&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=hoangtien2k3/ecommerce-microservices&type=Date&theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=hoangtien2k3/ecommerce-microservices&type=Date" />
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=hoangtien2k3/ecommerce-microservices&type=Date" />
  </picture>
</a>

## 👥 Contributors & Modifications

- **Original Author:** [Hoàng Anh Tiến](https://github.com/hoangtien2k3)
- **Modified by:** [Thu-sunrise](https://github.com/Thu-sunrise) - Refactored project structure into a Monorepo, added infrastructure configurations (Terraform, Istio), chaos engineering, and extensive test scripts.

## Contributing

If you would like to contribute to the development of this project, please follow our contribution guidelines.

<a href="https://repobeats.axiom.co/api/embed/1897bc523b54b43aefb19c65195f32377f8aab85.svg">
  <img src="https://repobeats.axiom.co/api/embed/1897bc523b54b43aefb19c65195f32377f8aab85.svg" alt="Repo analytics" width="600">
</a>

---

## 📄 License

```
MIT License
Copyright (c) 2026 Hoàng Anh Tiến (Original Author)
Copyright (c) 2026 Thu-sunrise (Modifications)
```
