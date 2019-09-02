# Store Terraform state in S3.
terraform {
  backend "s3" {
    bucket = "toolsinfra-tf-state"
    key    = "aws"
    region = "us-west-2"
    dynamodb_table = "terraform-state-lock"
  }
}

# Provision necessary resources for storing Terraform state (s3 and dynamodb).

# Note that if this is the first time running this, comment out the above backend configuration so that Terraform uses
# local state. Once the buckets and tables have been provisioned, it is safe to uncomment the above again.

resource "aws_s3_bucket" "state" {
  bucket = "toolsinfra-tf-state"
  acl    = "private"
  provider = "aws.testinfra"
}

resource "aws_dynamodb_table" "terraform-state-lock" {
  name = "terraform-state-lock"
  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }

  provider = "aws.testinfra"
}
