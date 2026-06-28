# Enterprise GitOps Platform — Infra

> **Part of a 3-repository GitOps system.**
> This repo provisions all AWS infrastructure using Terraform.
> It must be applied **before** the other two repos are used.
>
> | Repo | Purpose |
> |------|---------|
> | [`Enterprise-GitOps-Platform-app`](https://github.com/UsseF-1/Enterprise-GitOps-Platform-app) | Java source, Dockerfiles, CI pipeline |
> | **`Enterprise-GitOps-Platform-infra`** ← you are here | Terraform — EKS, ECR, VPC, SonarQube |
> | [`Enterprise-GitOps-Platform-helm`](https://github.com/UsseF-1/Enterprise-GitOps-Platform-helm) | Helm chart, ArgoCD manifests |

---

## What This Repo Does

Provisions the complete AWS infrastructure for the GitOps platform:

- **VPC** with public/private subnets across 2 availability zones and a NAT gateway
- **EKS cluster** (`GitOps-Platform-EKS`) with a managed node group on private subnets
- **EBS CSI Driver** with IRSA for persistent volume support inside EKS
- **ECR repository** for storing application Docker images
- **SonarQube EC2 instance** for code quality scanning (used by the app repo CI pipeline)
- **Monitoring stack** — kube-prometheus-stack and metrics-server values for Helm deployment

---

## Repository Structure

```
.
├── EKS/
│   ├── provider.tf          # AWS provider (~> 5.95)
│   ├── backend.tf           # Remote state → S3 bucket: eks-gitops-platform
│   ├── variables.tf         # Region, AZs, cluster name
│   ├── vpc.tf               # VPC module — 2 public + 2 private subnets, NAT GW
│   ├── ekscluster.tf        # EKS cluster + managed node group (t3.medium)
│   ├── ebs-csi-irsa.tf      # IRSA role for EBS CSI Driver
│   └── output.tf            # vpc_id, subnet IDs, cluster_name, cluster_endpoint
├── ECR/
│   ├── ecr.tf               # ECR repo with scan_on_push + prevent_destroy
│   └── output.tf            # ecr_app_url, ecr_name
├── monitoring/
│   ├── kube-prometheus-stack/
│   │   └── values.yaml      # Helm values for Prometheus + Grafana
│   └── metrics-server/
│       └── values.yaml      # Helm values for metrics-server
├── sonarqube-EC2/
│   ├── provider.tf
│   ├── backend.tf
│   ├── vars.tf              # Region, instance type, SSH user
│   ├── key-pair.tf          # SSH key pair for EC2 access
│   ├── sg.tf                # Security group — ports 22, 80, 9000
│   ├── instance.tf          # EC2 (t3.medium, Ubuntu) + remote provisioner
│   ├── instanceID.tf        # Data source for AMI lookup
│   ├── output.tf            # sonarqubePublicIP, sonarqubePrivateIP, instance_id
│   └── sonar-setup.sh       # Installs and configures SonarQube on EC2
└── .gitignore
```

---

## Architecture

```
                          ┌─────────────────────────────────────┐
                          │              AWS VPC                 │
                          │          10.0.0.0/16                 │
                          │                                      │
                          │  ┌─────────────┐ ┌───────────────┐  │
          Internet ───────┼──│Public Subnet│ │Public Subnet  │  │
                          │  │10.0.1.0/24  │ │10.0.2.0/24   │  │
                          │  │  (us-east-1a)│ │(us-east-1b)  │  │
                          │  └──────┬──────┘ └───────────────┘  │
                          │         │ NAT GW                     │
                          │  ┌──────▼──────┐ ┌───────────────┐  │
                          │  │Private Subnet│ │Private Subnet │  │
                          │  │10.0.3.0/24  │ │10.0.4.0/24   │  │
                          │  │ EKS Nodes   │ │ EKS Nodes    │  │
                          │  └─────────────┘ └───────────────┘  │
                          └─────────────────────────────────────┘

EKS Node Group:   t3.medium  |  min: 2  desired: 2  max: 3
EKS Version:      1.30
EBS CSI Driver:   enabled via cluster addon + IRSA
```

---

## Prerequisites

- AWS CLI configured with credentials that can create VPCs, EKS, EC2, ECR, IAM roles, and S3 objects
- Terraform >= 1.5
- `kubectl` (for interacting with the cluster after creation)
- Helm 3 (for deploying the monitoring stack)
- An S3 bucket named `eks-gitops-platform` in `us-east-1` (for remote state)
- An SSH key pair file named `sonarqube-key-GitOps-platform` in the `sonarqube-EC2/` directory

---

## Deployment Order

> These modules are independent Terraform roots — apply them in this order.

```
1. EKS/            → VPC + EKS cluster (takes ~15 min)
2. ECR/            → Container registry
3. sonarqube-EC2/  → SonarQube server (needed before first CI run)
4. monitoring/     → Deploy via Helm after cluster is ready
```

---

## Usage

### 1. EKS — VPC + Cluster

```bash
cd EKS/
terraform init
terraform plan
terraform apply
```

After apply, configure kubectl:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name GitOps-Platform-EKS
```

**Outputs:**

| Output | Description |
|--------|-------------|
| `vpc_id` | VPC ID |
| `private_subnet_ids` | Subnets where EKS nodes run |
| `public_subnet_ids` | Subnets where the ALB Ingress lives |
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | Kubernetes API endpoint |

---

### 2. ECR — Container Registry

```bash
cd ECR/
terraform init
terraform apply
```

**Outputs:**

| Output | Description |
|--------|-------------|
| `ecr_app_url` | Full ECR repository URL (used in GitHub Actions) |
| `ecr_name` | Repository name |

> The ECR repo has `prevent_destroy = true` and `scan_on_push = true`.

---

### 3. SonarQube EC2

```bash
cd sonarqube-EC2/
terraform init
terraform apply
```

Terraform will SSH into the instance and run `sonar-setup.sh` automatically.

SonarQube will be available at `http://<sonarqubePublicIP>:9000` after a couple of minutes.

**Outputs:**

| Output | Description |
|--------|-------------|
| `sonarqubePublicIP` | Public IP for browser access |
| `sonarqubePrivateIP` | Private IP |
| `instance_id` | EC2 instance ID |

> **Note:** The instance is created in a `stopped` state after provisioning via `aws_ec2_instance_state`. Start it manually when needed to avoid unnecessary cost.

---

### 4. Monitoring Stack

After the EKS cluster is running and `kubectl` is configured:

**kube-prometheus-stack (Prometheus + Grafana + Alertmanager):**

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f monitoring/kube-prometheus-stack/values.yaml
```

**metrics-server:**

```bash
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update

helm upgrade --install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  -f monitoring/metrics-server/values.yaml
```

> metrics-server is required for HPA to function. The app repo's Helm chart has HPA enabled by default.

---

## ArgoCD Installation

After EKS is up, install ArgoCD before applying the Helm repo manifests:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Expose the ArgoCD UI (an `argocd-ingress.yaml` is provided in `EKS/` for ALB-based access):

```bash
kubectl apply -f EKS/argocd-ingress.yaml
```

Get the initial admin password:

```bash
kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath="{.data.password}" | base64 -d
```

---

## State Management

| Module | Backend | Key |
|--------|---------|-----|
| `EKS/` | S3 — `eks-gitops-platform` | `dev/terraform.tfstate` |
| `sonarqube-EC2/` | S3 (separate backend) | see `sonarqube-EC2/backend.tf` |

> **Known limitation:** DynamoDB state locking is currently disabled in `EKS/backend.tf` to avoid extra cost. Do not run `terraform apply` on this module from multiple terminals simultaneously.

---

## Security Notes

- The SonarQube security group currently opens ports 22 and 9000 to `0.0.0.0/0`. Restrict the SSH rule to your own IP in `sonarqube-EC2/sg.tf` before deploying to production.
- The SSH private key (`sonarqube-key-GitOps-platform`) must never be committed to version control — it is in `.gitignore`.
- EKS nodes run on private subnets and are not directly accessible from the internet.
- ECR has `scan_on_push = true`; review findings in the AWS console after each image push.

---

## Teardown

```bash
# Remove in reverse order
cd monitoring/      # Helm uninstall first
helm uninstall kube-prometheus-stack -n monitoring
helm uninstall metrics-server -n kube-system

cd sonarqube-EC2/
terraform destroy

cd ECR/
# ECR has prevent_destroy = true — remove that block first if you intend to destroy
terraform destroy

cd EKS/
terraform destroy   # Takes ~10 min
```
