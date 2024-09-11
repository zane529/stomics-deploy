# One-click EKS Deployment with Integrated Services

This project implements a one-click deployment solution for Amazon EKS (Elastic Kubernetes Service) using Terraform. It addresses the challenges of setting up a comprehensive Kubernetes environment by integrating essential AWS services and tools, including VPC, IAM, Karpenter, Amazon EFS, Amazon S3, and Cromwell.

## Project Overview
### One-click deployment of EKS environment with integrated services
- Utilizes Terraform for Infrastructure as Code (IaC), enabling reproducible and version-controlled deployments
- Sets up a fully configured Amazon EKS cluster
- Integrates Karpenter for efficient auto-scaling of Kubernetes nodes
- Deploys AWS Load Balancer Controller for managing Elastic Load Balancers for Kubernetes services
- Configures Amazon EFS for persistent storage solutions with EFS-PVC
- Incorporates Amazon S3 for object storage needs with S3-PVC
- Includes Cromwell 8.5 setup, integrated with EKS for workflow management in bioinformatics pipelines
- Implements necessary IAM roles and policies for secure operations
- Creates a custom VPC tailored for the EKS environment
- Provides a "Hello World" WDL example to demonstrate Cromwell functionality

## Solution Architecture

[Insert architecture diagram here]

## Prerequisites

- AWS account with appropriate permissions
- A EC2 with AL2023 and install Docker.
- Terraform (version 1.9.x or later)
- AWS CLI configured with your credentials (version 2.15.x or later)
- kubectl installed for Kubernetes cluster management

## Quick Start

1. Clone the project repository:

```
sudo yum install -y git
git clone https://github.com/zane529/stomics-deploy.git

```

2. Initialize System Tools:
```
cd stomics-deploy/scripts/
sh setup.sh
```

3. Initialize Terraform:

```
cd ../environments/dev/
terraform init
```

4. Plan the Terraform execution:

```
terraform plan
```

5. Deploy the infrastructure:

```
nohup terraform apply -auto-approve > terraform_apply.log 2>&1 &
```

6. Check the deployment log:
```
tail -f terraform_apply.log
```

7. After successful deployment, use kubectl to interact with your new EKS cluster:

```
kubectl get pods
```

8. Test Cromwell Demo:

```
kubectl exec -it $(kubectl get pods -o name | grep '^pod/cromwell' | head -n 1 | cut -d/ -f2) -- /bin/bash
# In the pod env, run the command
cd /efs-data
java -Dconfig.file=/app/cromwell-k8s.conf -jar /app/cromwell.jar run /app/simple-hello.wdl
```

9. Destroy the ENV:

```
cd ~/stomics-deploy/environments/dev/
nohup terraform destroy -auto-approve > terraform_destroy.log 2>&1 &
```

## Documentation
* [Amazon EKS Documentation](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)
* [Terraform Documentation](https://www.terraform.io/docs)
* [Karpenter Documentation](https://karpenter.sh/docs/)
* [Amazon EFS Documentation](https://docs.aws.amazon.com/efs/latest/ug/whatisefs.html)
* [Amazon S3 Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html)
* [Cromwell Documentation](https://cromwell.readthedocs.io/en/stable/)

## Useful commands

* `terraform init`          Initialize Terraform working directory
* `terraform plan`          Preview the changes Terraform will make
* `terraform apply`         Apply the Terraform configuration
* `terraform destroy`       Destroy the Terraform-managed infrastructure
* `kubectl get nodes`       List all nodes in the EKS cluster
* `kubectl get pods --all-namespaces`  List all pods across all namespaces
* `kubectl get pvc`         List all Persistent Volume Claims (including S3 and EFS)

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information on reporting security issues.

## License

This project is licensed under the Apache 2.0 License. See the [LICENSE](LICENSE) file for details.