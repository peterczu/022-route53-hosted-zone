# Project 022 – AWS Route 53 Hosted Zone with Terraform

## Overview

This project demonstrates how to provision and manage an Amazon Route 53 Hosted Zone using Terraform. It also covers delegating a domain registered with Namecheap to Amazon Route 53 by updating the domain's authoritative nameservers.

By managing DNS as Infrastructure as Code (IaC), the project establishes the foundation for future deployments involving HTTPS, Application Load Balancers, and CloudFront.

---

## Architecture

```text
                Internet
                    │
                    ▼
          Namecheap Domain Registrar
                    │
      (Custom Name Servers)
                    │
                    ▼
        Amazon Route 53 Hosted Zone
                    │
                    ▼
              DNS Records
                    │
                    ▼
        Future AWS Resources
     (ALB, CloudFront, EC2)
```

---

## Project Objectives

* Provision a Route 53 Hosted Zone using Terraform.
* Manage DNS infrastructure as code.
* Delegate a Namecheap domain to Amazon Route 53.
* Configure a dedicated Terraform remote backend.
* Prepare the DNS foundation for future AWS networking projects.

---

## Technologies Used

* Terraform
* Amazon Route 53
* Amazon S3 (Remote Backend)
* AWS IAM
* GitHub
* Namecheap Domain Registrar

---

## Terraform Resources

This project provisions:

* Route 53 Public Hosted Zone

Terraform outputs include:

* Hosted Zone ID
* Route 53 Name Servers

These outputs are used to configure Namecheap with the Route 53 authoritative nameservers.

---

## Repository Structure

```text
.
├── backend.tf
├── provider.tf
├── variables.tf
├── terraform.tfvars
├── main.tf
├── outputs.tf
├── README.md
└── .github/
    └── workflows/
        └── terraform.yml
```

---

## Domain Delegation Process

1. Purchase or own a domain in Namecheap.
2. Create a Public Hosted Zone in Amazon Route 53 using Terraform.
3. Retrieve the Route 53 name servers from Terraform outputs.
4. Update the Namecheap domain to use the Route 53 custom name servers.
5. Wait for DNS propagation.
6. Verify that Route 53 becomes the authoritative DNS provider for the domain.

---

## Terraform Workflow

```text
Terraform Init
        │
        ▼
Terraform Validate
        │
        ▼
Terraform Plan
        │
        ▼
Terraform Apply
        │
        ▼
Route 53 Hosted Zone Created
        │
        ▼
Update Namecheap Name Servers
```

---

## Lessons Learned

During this project I learned:

* The difference between a domain registrar and a DNS hosting service.
* How Route 53 Public Hosted Zones work.
* How domain delegation transfers DNS authority from Namecheap to Route 53.
* The purpose of NS and SOA records.
* Why DNS propagation takes time.
* How to manage DNS infrastructure using Terraform.

---

## Future Improvements

Future projects will build on this foundation by adding:

* Route 53 Alias Records
* AWS Certificate Manager (ACM)
* HTTPS Application Load Balancer
* Amazon CloudFront
* Multi-record DNS management

---

## Author

**Peter Madueke**

Cloud Engineering Portfolio

* AWS
* Terraform
* GitHub Actions
* Infrastructure as Code

