output "bigquery_dataset_litiere" {
  description = "BigQuery dataset for Litière project"
  value       = google_bigquery_dataset.litiere.dataset_id
}

output "bigquery_table_classified_events" {
  description = "Full BigQuery table reference"
  value       = "${var.GCP_PROJECT_ID}.${google_bigquery_dataset.litiere.dataset_id}.${google_bigquery_table.classified_events.table_id}"
}

output "bigquery_table_raw_sessions" {
  description = "Full BigQuery table reference"
  value       = "${var.GCP_PROJECT_ID}.${google_bigquery_dataset.litiere.dataset_id}.${google_bigquery_table.raw_sessions.table_id}"
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

output "firestore_database" {
  description = "Firestore database name"
  value       = google_firestore_database.litiere.name
}
