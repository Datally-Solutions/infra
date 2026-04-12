provider "google" {
  project = var.GCP_PROJECT_ID
  region  = var.GCP_REGION
}

data "google_project" "project" {
  project_id = var.GCP_PROJECT_ID
}
