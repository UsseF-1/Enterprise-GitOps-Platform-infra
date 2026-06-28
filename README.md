# Enterprise GitOps Platform Infra

## Overview

This repository contains the Terraform infrastructure code for an Enterprise GitOps platform hosted on AWS. It is organized into discrete infrastructure domains:

- `EKS/`: Amazon EKS cluster and supporting networking
- `ECR/`: Amazon ECR container registry
- `monitoring/`: observability configuration for Kubernetes
- `sonarqube-EC2/`: AWS EC2 deployment for SonarQube

The architecture is designed to support GitOps workflows, container image management, continuous inspection, and cluster monitoring.

## Architecture

- A managed Amazon EKS cluster running Kubernetes workloads.
- A VPC with public and private subnets, NAT gateway, and cluster-specific tags.
- A private EKS node group for application workloads.
- An AWS ECR repository for storing container images.
- A dedicated EC2 instance running SonarQube for code quality scanning.
- Monitoring support via Kubernetes Prometheus stack and metrics-server configuration.

## Repository Structure

### `EKS/`

Contains Terraform code that provisions the EKS cluster and network resources.

- `provider.tf`: AWS provider configuration.
- `backend.tf`: Terraform remote state backend configured for S3.
- `variables.tf`: Inputs for region, availability zones, cluster name, and VPC settings.
- `vpc.tf`: Creates a VPC using the `terraform-aws-modules/vpc/aws` module with public/private subnets and a NAT gateway.
- `ebs-csi-irsa.tf`: Configures IAM role and permissions for the AWS EBS CSI driver (used by EKS storage).
- `ekscluster.tf`: Provisions the EKS cluster using `terraform-aws-modules/eks/aws` and attaches an EKS managed node group.
- `output.tf`: Exposes VPC IDs and EKS cluster information for use by other automation.

### `ECR/`

Contains Terraform code for the Elastic Container Registry.

- `ecr.tf`: Creates an `aws_ecr_repository` with image scanning enabled and destroy protection.
- `output.tf`: Exposes the repository URL and name.

### `monitoring/`

Contains Kubernetes monitoring configuration.

- `kube-prometheus-stack/`: Helm or manifest values for deploying Prometheus/Grafana and cluster monitoring.
- `metrics-server/`: Kubernetes metrics-server configuration and output manifests.

### `sonarqube-EC2/`

Contains Terraform code to deploy a SonarQube server on EC2.

- `provider.tf`: AWS provider configuration.
- `backend.tf`: Local or remote backend configuration for SonarQube Terraform state.
- `vars.tf`: Defines instance variables such as region, instance type, AMI selection, and SSH user.
- `key-pair.tf`: Creates an SSH key pair for EC2 access.
- `sg.tf`: Defines a security group for SonarQube access.
- `instance.tf`: Launches an EC2 instance with remote provisioners to run `sonar-setup.sh`.
- `instanceID.tf`: Looks up and outputs the SonarQube instance ID.
- `output.tf`: Exposes key outputs for the SonarQube deployment.
- `sonar-setup.sh`: Setup script executed on the EC2 host to install and configure SonarQube.

## Prerequisites

- AWS account with permissions to create VPCs, EKS clusters, EC2, ECR, IAM roles, and S3 objects.
- AWS CLI configured with the proper credentials and default region.
- Terraform installed (compatible with the required provider versions in the modules).
- `kubectl` configured if you need to interact with the EKS cluster after creation.
- Optional: Helm if applying the monitoring stack via Helm charts.

## Deployment Order

The recommended deployment order is:

1. `EKS/` - Create networking and cluster infrastructure.
2. `ECR/` - Create the image registry for application containers.
3. `monitoring/` - Deploy monitoring components into the Kubernetes cluster.
4. `sonarqube-EC2/` - Provision the SonarQube server on AWS EC2.

## Usage

### EKS

1. Change into `EKS/`.
2. Initialize Terraform:
   ```bash
   terraform init
   ```
3. Review the plan:
   ```bash
   terraform plan
   ```
4. Apply the infrastructure:
   ```bash
   terraform apply
   ```

### ECR

1. Change into `ECR/`.
2. Initialize Terraform and apply.

### SonarQube

1. Change into `sonarqube-EC2/`.
2. Initialize Terraform.
3. Apply the configuration to launch the EC2 instance.

## Notes

- The EKS backend is configured to use an S3 bucket named `eks-gitops-platform` and key `dev/terraform.tfstate`.
- The SonarQube EC2 instance uses an SSH key pair named `sonarqube-key-GitOps-platform`.
- The ECR repository is protected with `prevent_destroy` and has image scanning enabled on push.
- The EKS VPC is tagged for Kubernetes load balancer discovery and cluster resource sharing.

## Outputs

### EKS outputs

- `vpc_id`
- `private_subnet_ids`
- `public_subnet_ids`
- `cluster_name`
- `cluster_endpoint`

### ECR outputs

- `ecr_app_url`
- `ecr_name`

## Monitoring

The `monitoring/` folder contains configuration for Prometheus and metrics-server, intended to provide cluster observability. Deploy these after EKS is ready and `kubectl` is pointed at the cluster.

## Security and Best Practices

- Keep Terraform state secured, especially the S3 backend and any DynamoDB locks if enabled.
- Rotate SSH keys and avoid committing private SSH keys to version control.
- Consider using IAM roles for service accounts and stricter security group rules for SonarQube.
- Review and update AWS provider versions periodically to remain compatible with AWS API changes.

## Improvements

Potential improvements for this repository include:

- Adding Terraform workspaces for multiple environments (dev/test/prod).
- Enabling DynamoDB locking for the EKS backend.
- Moving monitoring manifests into a Helm chart deployment script.
- Adding a dedicated Bastion host or VPN for secure SonarQube access.
- Implementing GitOps automation to apply the cluster and application manifests automatically.

---

## Contact

If you need help or want to extend this infrastructure, review the Terraform module documentation and AWS provider docs for the modules used.
