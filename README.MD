# CloudDeploy Infrastructure

Production-grade Kubernetes infrastructure for CloudDeploy — a Platform as a Service (PaaS) that automatically deploys user applications from GitHub repositories.

## Overview

CloudDeploy Infrastructure provisions and configures the entire runtime environment where user applications are deployed. Built with Infrastructure as Code principles — a single `terraform apply` provisions everything from scratch with zero manual intervention.(as of yet)

## Architecture

### First Deployment
```
User pastes GitHub repo URL on CloudDeploy
  ↓
FastAPI receives request → generates deployment_id
  ↓
AI scans repo → generates Dockerfile
  ↓
GitHub Actions builds image → pushes to Docker Hub
  ↓
Celery triggers deployment
  ↓
K3s pulls image → Pod runs on EC2
  ↓
Nginx Ingress routes <deployment_id>.<ip>.nip.io → Pod
  ↓
cert-manager issues TLS cert automatically
  ↓
User gets live HTTPS URL
```
### Auto Redeployment (every git push)

```
User pushes new code to their GitHub repo
  ↓
GitHub webhook fires to CloudDeploy ALB
  ↓
Same pipeline repeats automatically
  ↓
Rolling update → zero downtime
  ↓
New version live automatically
```

## Tech Stack

| Tool | Purpose |
|---|---|
| Terraform | Provisions AWS infrastructure |
| Ansible | Configures server and installs K3s |
| K3s | Lightweight Kubernetes for container orchestration |
| Helm | Installs Kubernetes packages |
| Nginx Ingress | Routes domains to correct containers |
| cert-manager | Automatically issues Let's Encrypt TLS certs |
| Prometheus | Scrapes cluster metrics |
| Grafana | Monitoring dashboards and alerts |
| AWS EC2 | Runtime server |
| AWS ASG | Auto scales worker nodes based on CPU |
| AWS EIP | Fixed public IP that never changes |

## AWS Infrastructure

```
AWS Cloud (ap-south-1)
└── VPC (10.0.0.0/16)
    └── Public Subnet (10.0.1.0/24)
        ├── Internet Gateway
        ├── Route Table
        ├── Security Group
        ├── EC2 t3.medium (K3s server) ← fixed, always running
        ├── Elastic IP (fixed public IP)
        └── Auto Scaling Group (K3s workers)
            ├── min: 1 worker
            ├── max: 3 workers
            ├── scale up: CPU > 70%
            └── scale down: CPU < 30%
```

## What Runs on the Cluster

```
K3s Cluster
├── ingress-nginx (Nginx Ingress Controller)
│   └── Routes domains to correct app pods
├── cert-manager
│   └── Auto issues Let's Encrypt TLS for every app
├── monitoring
│   ├── Prometheus (metrics collection)
│   ├── Grafana (dashboards)
│   └── AlertManager (alerts)
└── default namespace
    └── User app pods (yet to be deployed )
```

## Prerequisites

- AWS account with CLI configured
- Terraform installed
- Ansible installed
- kubectl installed
- Helm installed
- SSH key pair created in AWS (ap-south-1)

## Setup

**1. Clone the repos**

```bash
git clone 
cd Cloud-Deploy
```

**2. Configure Terraform variables**

```bash
cd cloud-deploy-infra
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
key_name = "your-aws-key-pair-name"
region   = "ap-south-1"
ami_id   = "ami-xxxxxxxxx"
```

**3. Configure Ansible variables**

```bash
cd cloud-deploy-ansible
cp group_vars/all.yml.example group_vars/all.yml
```

Edit `group_vars/all.yml`:
```yaml
ansible_user: ubuntu
ansible_ssh_private_key_file: ~/.ssh/your-key.pem
ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
dockerhub_username: your-dockerhub-username
dockerhub_token: your-dockerhub-token
```

**4. Deploy everything**

```bash
cd cloud-deploy-infra
terraform apply
```

That's it. Everything runs automatically:
- EC2 provisioned
- Elastic IP attached
- Ansible runs automatically
- K3s installed
- Helm charts installed
- kubeconfig downloaded and fixed
- Docker Hub secret created
- Cluster ready

## Verify Deployment

```bash
# Check cluster
kubectl get nodes

# Check all pods
kubectl get pods --all-namespaces

# Check TLS issuer
kubectl get clusterissuer

# Check monitoring
kubectl get pods -n monitoring
```

## Security Group Ports

| Port | Protocol | Source | Purpose |
|---|---|---|---|
| 22 | TCP | 0.0.0.0/0 | SSH access |
| 80 | TCP | 0.0.0.0/0 | HTTP + Let's Encrypt challenge |
| 443 | TCP | 0.0.0.0/0 | HTTPS user traffic |
| 6443 | TCP | 0.0.0.0/0 | K3s API server |
| 10250 | TCP | 10.0.0.0/16 | Kubelet API |
| 8472 | UDP | 10.0.0.0/16 | Flannel pod networking |
| 2379-2380 | TCP | 10.0.0.0/16 | etcd cluster state |


## Monitoring

Access Grafana:

```bash
kubectl port-forward -n monitoring \
  svc/prometheus-stack-grafana 3000:80
```

Open: `http://localhost:3000`



## Auto Scaling

Workers scale automatically:
- CPU above 70% for 4 minutes → adds 1 worker (max 3)
- CPU below 30% for 4 minutes → removes 1 worker (min 1)
- New workers automatically join K3s cluster via userdata.sh

## Teardown

```bash
terraform destroy
```

## File Structure

```
Cloud-Deploy/
├── README.md
├── cloud-deploy-infra/
│   ├── vpc.tf
│   ├── security_group.tf
│   ├── compute.tf
│   ├── eip.tf
│   ├── ansible.tf
│   ├── outputs.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   └── userdata.sh
└── cloud-deploy-ansible/
    ├── inventory.ini
    ├── playbook.yml
    ├── group_vars/
    │   └── all.yml
    └── roles/
        ├── k3s_server/
        │   └── tasks/
        │       └── main.yml
        └── helm/
            ├── tasks/
            │   └── main.yml
            └── files/
                └── clusterissuer.yml 

```

