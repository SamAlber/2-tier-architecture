terraform {
  # CREATED AFTER EVERYTHING WAS SET UP! 
  # BACKEND REQUIRES STATIC NAMES
  # That's where the terraform.tfstate will be stored 
  backend "s3" {
    bucket         = "terraform.tfstate-bra2hd"      // using a bucket that was created for the site project
    key            = "2-tier-arch/terraform.tfstate" // giving a different path for the tf state in the bucket (The value of key becomes the value of LockID hash_key attribute in DynamoDB)
    region         = "us-east-1"
    dynamodb_table = "tfstate-locks" # using a dynamodb table created for the site project 
    encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.78.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

/*
Key and LockID Relationship in DynamoDB:

The value of key (e.g., 2-tier-arch/terraform.tfstate) becomes the value of LockID in DynamoDB.
This ensures that each Terraform state has a unique lock entry in the table.

Example: 

LockID	                        Info
project1/terraform.tfstate	Lock acquired at ...
project2/terraform.tfstate	Lock acquired at ...

Example DynamoDB Table Entry
When Terraform acquires a lock, it creates an entry in the DynamoDB table like this:

Attribute (Hash Key)            Value
LockID                  project1/terraform.tfstate

*/

