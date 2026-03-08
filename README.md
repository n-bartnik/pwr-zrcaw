# Infrastructure comparison: AWS native vs. open source on AWS

This project compares two infrastructure approaches for deploying a chat application on AWS:
1.  **Vendor:** A fully AWS-native solution using services like AWS Lambda, Amazon Cognito, etc.
2.  **Open Source:** An open-source alternative deployed on AWS infrastructure, utilizing tools like Keycloak, MinIO, etc.

## Prerequisites

Before running the code, ensure you have the following installed and configured:

*   **Terraform**.
*   **AWS CLI:** configured with AWS credentials (`aws configure`).
*   **Docker:** required for building and pushing container images; ensure the Docker daemon is running.
*   **Bash:** the Terraform scripts use `local-exec` with `/bin/bash`, so a Bash environment (Linux) is required.

## How to start

### Vendor version

This version deploys the application using AWS managed services.

1.  Navigate to the Terraform directory:
    ```bash
    cd vendor/terraform
    ```

2.  Initialize Terraform:
    ```bash
    terraform init
    ```

3.  Review the deployment plan:
    ```bash
    terraform plan
    ```

4.  Apply the configuration. Set the `lab_role` variable in `variables.tf`:
    ```bash
    terraform apply -var="lab_role=arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_ROLE"
    ```

### Open Source Version

This version deploys open-source alternatives on AWS infrastructure.

1.  Navigate to the Terraform directory:
    ```bash
    cd open-source/terraform
    ```

2.  Initialize Terraform:
    ```bash
    terraform init
    ```

3.  Review the deployment plan:
    ```bash
    terraform plan
    ```

4.  Apply the configuration. You must provide values for `auth_domain`, `app_domain` and `lab_role`:
    ```bash
    terraform apply -var="auth_domain=auth.example.com" -var="app_domain=app.example.com"
    ```
    *   `auth_domain`: The domain for Keycloak authentication.
    *   `app_domain`: The domain for the main application.
        ```bash
        terraform apply -var="auth_domain=..." -var="app_domain=..." -var="lab_role=arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_ROLE"
        ```

## Architecture Overview

*   **Vendor:**
    *   **Frontend/Backend:** ECS Fargate
    *   **Auth:** Amazon Cognito
    *   **Database:** Amazon RDS with PostgreSQL
    *   **Storage:** Amazon S3
    *   **Compute:** AWS Lambda
    * **Monitoring:** AWS CloudWatch

*   **Open Source:**
    *   **Frontend/Backend:** Dockerized services
    *   **Auth:** Keycloak
    *   **Database:** PostgreSQL
    *   **Storage:** MinIO
    *   **Monitoring:** Grafana & Prometheus
