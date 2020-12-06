# Specify the provider and access details
provider "aws" {
  profile                 = "pltech-che"
  region                  = var.aws_region
}