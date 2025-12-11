# AWS Infrastructure Automation using Terraform & CloudFormation

This project demonstrates the deployment of AWS cloud infrastructure using **Infrastructure as Code (IaC)** with **Terraform** and **CloudFormation**.

## Project Structure

```
aws-iac-final/
│
├── terraform/
│   ├── provider.tf
│   ├── backend.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── .gitignore
│
└── cloudformation/
    ├── s3-buckets.yaml
    ├── ec2-vpc.yaml
    ├── rds-mysql.yaml
    └── README.md
```

## Module 1 — Terraform Deployment

Terraform provisions AWS resources including:

- 4 private S3 buckets with versioning enabled
- VPC, Subnets, Internet Gateway, Route Tables
- EC2 instance with SSH access
- RDS MySQL instance with subnet group

### Deployment Steps

```
cd terraform
terraform init
terraform validate
terraform plan
terraform apply -auto-approve
```

### Outputs

Terraform displays:

- EC2 Public IP
- RDS Endpoint
- S3 Bucket Names

## Module 2 — CloudFormation Deployment

Using AWS Console:

- Upload `s3-buckets.yaml`, `ec2-vpc.yaml`, `rds-mysql.yaml`
- Provide required parameters
- Deploy stacks and verify outputs

## Screenshot Checklist

- S3 Buckets
- VPC
- Subnets
- Internet Gateway
- Route Table
- EC2 Instance
- Security Group
- RDS Subnet Group
- RDS Instance
- Terraform CLI Output

## Cleanup

```
terraform destroy -auto-approve
```

CloudFormation stacks must be deleted manually.

## Conclusion

This project demonstrates end-to-end AWS automation using Terraform and CloudFormation, ensuring modular, scalable cloud infrastructure.
