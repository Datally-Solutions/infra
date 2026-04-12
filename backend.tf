terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Bucket name follows the convention: "${GCP_PROJECT_ID}-tfstate"
  # (matches google_storage_bucket.tfstate in storage.tf)
  # Terraform backend blocks do not support variable interpolation — if the
  # project ID changes, update this value manually and run:
  #   terraform init -migrate-state
  backend "gcs" {
    bucket = "cat-litter-monitor-tfstate"
    prefix = "infra"
  }
}
