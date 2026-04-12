# -------------------------------------------------------
# Secret Manager
# -------------------------------------------------------
resource "google_secret_manager_secret" "ingest_token" {
  secret_id = "litter-ingest-token"

  replication {
    user_managed {
      replicas {
        location = var.GCP_REGION
      }
    }
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "ingest_token" {
  secret      = google_secret_manager_secret.ingest_token.id
  secret_data = var.ingest_token
}
