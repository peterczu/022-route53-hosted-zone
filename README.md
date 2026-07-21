# Project 021 – Automated Terraform Apply Pipeline with GitHub Actions

## Overview

This project extends the previous CI pipeline by implementing an automated Terraform deployment workflow using GitHub Actions.

The workflow authenticates to AWS using GitHub OpenID Connect (OIDC), validates the Terraform configuration, generates an execution plan, and automatically applies infrastructure changes after a successful plan stage.

This project demonstrates a basic Continuous Delivery (CD) workflow for Infrastructure as Code.

---

## Architecture

```
Developer
    │
    ▼
Git Push
    │
    ▼
GitHub Actions
    │
    ├───────────────┐
    ▼               │
Terraform Plan      │
    │               │
    ▼               │
Terraform Apply ◄───┘
    │
    ▼
AWS Infrastructure
```

---

## Project Objectives

* Build a multi-job GitHub Actions workflow
* Authenticate securely to AWS using GitHub OIDC
* Validate Terraform configuration automatically
* Generate Terraform execution plans
* Automatically apply approved infrastructure changes
* Eliminate the need for long-lived AWS access keys

---

## Technologies Used

* Terraform
* AWS IAM
* AWS STS
* GitHub Actions
* GitHub OIDC
* Amazon EC2
* Amazon VPC
* Amazon S3 Remote Backend

---

## GitHub Actions Workflow

### Job 1

* Checkout Repository
* Configure AWS Credentials (OIDC)
* Setup Terraform
* Terraform Init
* Terraform Format Check
* Terraform Validate
* Terraform Plan

### Job 2

Runs only after the successful completion of the Plan job.

* Checkout Repository
* Configure AWS Credentials
* Setup Terraform
* Terraform Init
* Terraform Apply

The workflow uses the `needs:` keyword to ensure Terraform Apply executes only after a successful Terraform Plan.

---

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── terraform.yml
├── backend.tf
├── iam.tf
├── main.tf
├── provider.tf
├── secrets.tf
├── variables.tf
├── outputs.tf
└── README.md
```

---

## Security

This project follows several security best practices:

* GitHub OpenID Connect (OIDC) authentication
* No long-lived AWS access keys
* Temporary STS credentials
* GitHub Secrets for sensitive Terraform variables
* Remote Terraform state stored in Amazon S3

---

## Lessons Learned

During development I learned several practical DevOps concepts:

* GitHub Actions jobs execute on separate runners.
* Each job requires its own checkout, authentication, and Terraform initialization.
* Terraform automatically detects changes caused by updated AMIs when using `most_recent = true`.
* Temporary AWS STS credentials are generated for every workflow execution.
* Proper Git repository organization is important when managing multiple Infrastructure as Code projects.

---

## Future Improvements

* Add manual deployment approval using GitHub Environments.
* Introduce reusable GitHub Actions workflows.
* Add Terraform security scanning.
* Integrate automated testing before deployment.

---

## Author

**Peter Madueke**

AWS • Terraform • GitHub Actions • Infrastructure as Code
