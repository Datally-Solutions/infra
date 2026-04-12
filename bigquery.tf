# -------------------------------------------------------
# BigQuery — datasets, tables, log sink
# -------------------------------------------------------
resource "google_bigquery_dataset" "litiere" {
  dataset_id    = "litiere"
  friendly_name = "Cat Litter Monitor"
  description   = "Events from the connected cat litter box"
  location      = "EU"

  depends_on = [google_project_service.apis]
}

resource "google_bigquery_table" "classified_events" {
  dataset_id          = google_bigquery_dataset.litiere.dataset_id
  table_id            = "classified_events"
  deletion_protection = false

  time_partitioning {
    type  = "DAY"
    field = "timestamp"
  }

  clustering = ["device_id", "action"]

  schema = jsonencode([
    { name = "timestamp", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "device_id", type = "STRING", mode = "NULLABLE" },
    { name = "chat", type = "STRING", mode = "REQUIRED" },
    { name = "action", type = "STRING", mode = "REQUIRED" },
    { name = "poids", type = "FLOAT64", mode = "NULLABLE" },
    { name = "poids_chat", type = "FLOAT64", mode = "NULLABLE" },
    { name = "duree", type = "INT64", mode = "NULLABLE" },
    { name = "alerte", type = "STRING", mode = "NULLABLE" },
    { name = "raw_session_id", type = "STRING", mode = "NULLABLE" },
    { name = "classifier_version", type = "STRING", mode = "NULLABLE" },
    { name = "action_confirme", type = "STRING", mode = "NULLABLE" },
    { name = "chat_confirme", type = "STRING", mode = "NULLABLE" },
    { name = "session_valide", type = "BOOL", mode = "NULLABLE" }
  ])
}

resource "google_bigquery_table" "raw_sessions" {
  dataset_id          = google_bigquery_dataset.litiere.dataset_id
  table_id            = "raw_sessions"
  deletion_protection = false

  time_partitioning {
    type  = "DAY"
    field = "timestamp"
  }

  schema = jsonencode([
    { name = "timestamp", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "device_id", type = "STRING", mode = "NULLABLE" },
    { name = "entry_weight_kg", type = "FLOAT64", mode = "NULLABLE" },
    { name = "exit_weight_delta_g", type = "FLOAT64", mode = "NULLABLE" },
    { name = "duration_seconds", type = "INT64", mode = "NULLABLE" },
    { name = "raw_session_id", type = "STRING", mode = "NULLABLE" }
  ])
}

resource "google_bigquery_dataset" "logs_dataset" {
  dataset_id  = "device_logs"
  description = "Dataset for device logs"
  location    = var.GCP_REGION
  project     = var.GCP_PROJECT_ID
}

# Routes ERROR+ device logs to BigQuery
resource "google_logging_project_sink" "bigquery_sink_device_logs" {
  name        = "bigquery-sink"
  destination = "bigquery.googleapis.com/projects/${var.GCP_PROJECT_ID}/datasets/${google_bigquery_dataset.logs_dataset.dataset_id}"
  filter      = "logName=~\"projects/${var.GCP_PROJECT_ID}/logs/litiere-device-\" AND severity >= ERROR"

  unique_writer_identity = true
  project                = var.GCP_PROJECT_ID

  bigquery_options {
    use_partitioned_tables = true
  }
}

resource "google_bigquery_dataset_iam_binding" "bigquery_writer" {
  project    = var.GCP_PROJECT_ID
  dataset_id = google_bigquery_dataset.logs_dataset.dataset_id
  role       = "roles/bigquery.dataEditor"
  members = [
    google_logging_project_sink.bigquery_sink_device_logs.writer_identity,
  ]
  depends_on = [google_bigquery_dataset.logs_dataset]
}
