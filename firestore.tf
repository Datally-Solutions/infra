# -------------------------------------------------------
# Firestore — database, indexes, TTL
# -------------------------------------------------------
resource "google_firestore_database" "main" {
  project     = var.GCP_PROJECT_ID
  name        = "${var.GCP_PROJECT_ID}-firestore"
  location_id = var.GCP_REGION
  type        = "FIRESTORE_NATIVE"

  deletion_policy = "ABANDON"
}

resource "google_firestore_index" "health_alerts_cat_alert_timestamp" {
  project    = var.GCP_PROJECT_ID
  database   = google_firestore_database.main.name
  collection = "health_alerts"

  fields {
    field_path = "alert_type"
    order      = "ASCENDING"
  }

  fields {
    field_path = "cat_id"
    order      = "ASCENDING"
  }

  fields {
    field_path = "timestamp"
    order      = "ASCENDING"
  }

  fields {
    field_path = "__name__"
    order      = "ASCENDING"
  }

  query_scope = "COLLECTION"
}

resource "google_firestore_index" "health_alerts_acknowledged_timestamp" {
  project    = var.GCP_PROJECT_ID
  database   = google_firestore_database.main.name
  collection = "health_alerts"

  fields {
    field_path = "acknowledged"
    order      = "ASCENDING"
  }

  fields {
    field_path = "timestamp"
    order      = "DESCENDING"
  }

  fields {
    field_path = "__name__"
    order      = "DESCENDING"
  }

  query_scope = "COLLECTION"
}

# Auto-expire events documents via Firestore TTL
resource "google_firestore_field" "events_ttl" {
  project    = var.GCP_PROJECT_ID
  database   = google_firestore_database.main.name
  collection = "events"
  field      = "expire_at"

  ttl_config {}
}

# Auto-expire health_alerts documents via Firestore TTL
resource "google_firestore_field" "health_alerts_ttl" {
  project    = var.GCP_PROJECT_ID
  database   = google_firestore_database.main.name
  collection = "health_alerts"
  field      = "expire_at"

  ttl_config {}
}
