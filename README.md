# HMCTS Dev Test Backend
This will be the backend for the brand new HMCTS case management system. As a potential candidate we are leaving
this in your hands. Please refer to the brief for the complete list of tasks! Complete as much as you can and be
as creative as you want.

You should be able to run `./gradlew build` to start with to ensure it builds successfully. Then from that you
can run the service in IntelliJ (or your IDE of choice) or however you normally would.

There is an example endpoint provided to retrieve an example of a case. You are free to add/remove fields as you
wish.


# HMCTS DevOps Technical Test

## Overview

This repository contains my solution to the HMCTS DevOps Technical Test.

The solution demonstrates:

- Database integration with PostgreSQL
- Containerisation using Docker
- Local development with Docker Compose
- CI/CD using GitHub Actions
- Container vulnerability scanning using Trivy
- Infrastructure as Code using Terraform on Azure
- Secure secret management using Azure Key Vault

The application is a Spring Boot service running on port **4000**.

---

# Running the application locally

## Prerequisites

- Java 21
- Docker Desktop
- Docker Compose
- Git

Clone the repository:

```bash
git clone https://github.com/Rasheed-10/hmcts-dev-test-backend.git
cd hmcts-dev-test-backend
```

Create a local environment file from the example:

```bash
cp .env.example .env
```

Start the application and PostgreSQL:

```bash
docker compose up --build
```

Verify the application:

```bash
curl http://localhost:4000/
```

Expected output:

```
Welcome to test-backend
```

Retrieve the sample case:

```bash
curl http://localhost:4000/get-example-case
```

Verify database connectivity:

```bash
curl http://localhost:4000/health
```

The health endpoint should report:

- Application status UP
- PostgreSQL database status UP
- Readiness UP

To stop the application:

```bash
docker compose down
```

---

# CI/CD Pipeline

GitHub Actions is used to automate the build, validation and security checks.

The workflow performs the following stages.

## 1. Build & Test

- Checkout repository
- Install Java 21
- Restore Gradle cache
- Build the application
- Execute unit tests
- Execute Checkstyle

This ensures every commit produces a working build.

---

## 2. Docker Image Build

The workflow builds a production Docker image using the multi-stage Dockerfile.

The image is tagged using the Git commit SHA to provide immutable versioning.

Example:

```
hmcts-dev-test-backend:<git-sha>
```

Using the commit SHA guarantees every image is uniquely traceable to a specific commit.

---

## 3. Container Security Scan

Trivy scans the Docker image.

Two scans are performed:

- HIGH vulnerabilities (warning only)
- CRITICAL vulnerabilities (pipeline fails)

This allows developers to remain aware of HIGH issues while preventing deployment of images containing CRITICAL vulnerabilities.

---

## 4. Terraform Validation

Terraform validation includes:

```bash
terraform fmt -check
terraform validate
```

These checks ensure the infrastructure code is correctly formatted and syntactically valid before deployment.

---

# Terraform Infrastructure

Terraform provisions the Azure infrastructure required for the application.

Resources include:

- Azure Resource Group
- Azure Log Analytics Workspace
- Azure Container Apps Environment
- Azure Container App
- Azure PostgreSQL Flexible Server
- PostgreSQL Database
- Azure Key Vault
- User Assigned Identity
- RBAC Role Assignments

Application configuration is supplied through environment variables.

Database credentials are stored securely inside Azure Key Vault and injected into the Container App as secrets.

Sensitive values are never committed into source control.

---

# Terraform Project Structure

```
terraform/

├── versions.tf
├── variables.tf
├── locals.tf
├── main.tf
├── outputs.tf
├── terraform.tfvars.example
└── .terraform.lock.hcl
```

Each file has a specific responsibility:

- **versions.tf** – Terraform and provider versions
- **variables.tf** – input variables
- **locals.tf** – reusable local values
- **main.tf** – Azure resources
- **outputs.tf** – exported outputs
- **terraform.tfvars.example** – example variable values

---

# Terraform State Management

For this exercise, the backend configuration is intentionally omitted so the project can be validated without Azure credentials.

In a production environment I would configure a remote Azure backend using:

- Azure Storage Account
- Blob Container
- State locking
- RBAC permissions

Example backend configuration:

```hcl
terraform {
  backend "azurerm" {}
}
```

This prevents state corruption, enables collaboration and provides a single source of truth for infrastructure state.

---

# Security

Security controls implemented include:

- Non-root Docker container
- Azure Key Vault for secrets
- Sensitive Terraform variables
- Trivy vulnerability scanning
- Database password excluded from Git
- Environment variables used instead of hardcoded credentials

---

# Assumptions

The following assumptions were made:

- Azure resources are created in a single region.
- Networking components (Virtual Network, Private Endpoints and Firewall rules) are outside the scope of the exercise.
- Azure authentication is handled by an existing service principal or managed identity.
- The container image is available from an external container registry.

---

# Trade-offs

To keep the solution focused on the assessment requirements:

- Azure Container Apps was selected instead of AKS because it provides a simpler managed runtime for a single containerised application.
- Terraform validates locally but is not applied because Azure authentication is not required for the exercise.
- PostgreSQL uses default sizing suitable for demonstration purposes rather than production sizing.

---

# Improvements With More Time

If additional time were available I would implement:

- Separate environments (dev, test and production)
- Remote Terraform backend with Azure Storage
- Reusable Terraform modules
- Private networking using VNets and Private Endpoints
- GitHub OIDC authentication to Azure
- Automated deployment to Azure Container Apps
- SonarQube quality gates
- SBOM generation
- Dependency-Track integration
- Branch protection rules
- Blue/Green deployment strategy
- Monitoring dashboards and alerting with Azure Monitor

---

# Verification

Application build:

```bash
./gradlew clean build
```

Docker:

```bash
docker compose up --build
```

Terraform:

```bash
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
```

All commands complete successfully.
