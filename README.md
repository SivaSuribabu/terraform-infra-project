📘 Terraform Infrastructure Project – Full Documentation
🔧 Goal
To create infrastructure in AWS using modular Terraform scripts with three environments: dev, test, and prod, selected manually at runtime. We'll also include:

backend.tf – to enable remote state storage (like in S3)

outputs.tf – to return resource IDs, names, etc.

✅ Features of Infra
Resource	Description
3 S3 Buckets	Per environment (dev/test/prod)
VPC	Named demo-vpc, with 2 public and 2 private subnets
S3 Endpoint	For private subnet access to S3
Auto Scaling	ASG with 1-2 t3.micro Ubuntu instances in private subnets
CloudWatch	CPU trigger to scale when >60%
Region	Manually provided per execution
No NAT Gateway	Clean, cost-effective demo setup
🧱 Terraform Folder Structure

terraform-infra/
├── modules/
│   ├── s3/
│   │   └── main.tf
│   ├── vpc/
│   │   ├── main.tf
│   │   └── outputs.tf
│   └── asg/
│       └── main.tf
├── envs/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── backend.tf
│   │   └── outputs.tf
│   ├── test/ ...
│   └── prod/ ...
🔁 test and prod folders contain similar files as dev, just changing the env_name.

🧩 Module Breakdown
🔹 modules/s3/main.tf
Creates 3 uniquely named S3 buckets using:


resource "aws_s3_bucket" "buckets" {
  count = 3
  bucket = "${var.env_name}-s3-bucket-${count.index + 1}"
  force_destroy = true
}
🔹 modules/vpc/main.tf
VPC

2 public + 2 private subnets

S3 VPC endpoint

🔹 modules/vpc/outputs.tf

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
🔹 modules/asg/main.tf
Launch template (AMI: Ubuntu, t3.micro)

ASG in private subnets

CloudWatch alarm on 60% CPU

📂 Environment-Specific Code (envs/dev/)
✅ main.tf
hcl
Copy
Edit
provider "aws" {
  region = var.region
}

module "s3" {
  source   = "../../modules/s3"
  env_name = "dev"
}

module "vpc" {
  source   = "../../modules/vpc"
  env_name = "dev"
  region   = var.region
  azs      = ["us-east-1a", "us-east-1b"]
}

module "asg" {
  source             = "../../modules/asg"
  env_name           = "dev"
  private_subnet_ids = module.vpc.private_subnet_ids
}
✅ variables.tf

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}
✅ outputs.tf

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}
✅ backend.tf

terraform {
  backend "s3" {
    bucket         = "terraform-state-backend-demo"      # Replace with your actual bucket
    key            = "dev/terraform.tfstate"              # Change for test/prod
    region         = "us-east-1"                          # Hardcoded backend region
    encrypt        = true
    dynamodb_table = "terraform-locks"                    # Optional for state locking
  }
}
🔒 To use remote state:

Create the S3 bucket (terraform-state-backend-demo)

Optionally create DynamoDB table terraform-locks with LockID as primary key

🚀 Execution Steps
✅ 1. Navigate to environment folder

cd terraform-infra/envs/dev     # or test/prod
✅ 2. Initialize Terraform (will use backend.tf)

terraform init
✅ 3. Plan with region input

terraform plan -var="region=us-east-1"
✅ 4. Apply

terraform apply -auto-approve -var="region=us-east-1"
✅ 5. Destroy

terraform destroy -auto-approve -var="region=us-east-1"

📝 How to Change Environment
Task	What to Do
Switch Environment	cd envs/test or cd envs/prod
Change Region	Pass -var="region=..." in commands
Remote State Paths	Update key = "test/terraform.tfstate" in backend.tf
✅ Jenkins Pipeline for Automation

groovy
pipeline {
  agent any

  environment {
    ENV_DIR = "envs/dev"
    REGION  = "us-east-1"
  }

  triggers {
    pollSCM('* * * * *') // Check every minute for git push
  }

  stages {
    stage('Init') {
      steps {
        dir("${ENV_DIR}") {
          sh 'terraform init'
        }
      }
    }
    stage('Plan') {
      steps {
        dir("${ENV_DIR}") {
          sh "terraform plan -var='region=${REGION}'"
        }
      }
    }
    stage('Apply') {
      steps {
        dir("${ENV_DIR}") {
          sh "terraform apply -auto-approve -var='region=${REGION}'"
        }
      }
    }
  }
}
✅ Validate Infrastructure
Resource	How to Validate
S3 Buckets	AWS Console > S3
VPC/Subnets	AWS Console > VPC
ASG/Instances	EC2 > Auto Scaling Groups
CloudWatch	Check scaling alarms
Outputs	terraform output
