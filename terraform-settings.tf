terraform {
  backend "s3" {
      region = "eu-north-1"
      bucket = "terraform-state-files-eu-north-1"
      key = "toptal-test-terraform-fargate.tfstate"
      profile = "pltech-che"
      dynamodb_table = "toptal-test-terraform-fargate.tfstate"
      encrypt        = true
  }
}