output "bigquery_table" {
  description = "Full BigQuery table reference"
  value       = "${var.GCP_PROJECT_ID}.${google_bigquery_dataset.litiere.dataset_id}.${google_bigquery_table.events.table_id}"
}

output "wif_provider" {
  description = "Workload Identity Provider — use in GitHub Actions"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "cicd_sa_email" {
  description = "CI/CD Service Account email — use in GitHub Actions"
  value       = google_service_account.cicd_sa.email
}

output "tfstate_bucket" {
  description = "GCS bucket for Terraform state"
  value       = google_storage_bucket.tfstate.name
}