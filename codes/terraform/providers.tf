terraform {
  required_version = ">=1.5.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.53.0"
    }
  }

  backend "s3" {
    bucket         = "derrick-state-space"
    key            = "serverless-pipeline.tfstate"
    region         = "ap-southeast-1"

    profile    = "terra"
  }
}

provider "aws" {
  region  = "ap-southeast-1"
}
