terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "cat-litter-monitor-tfstate"
    prefix = "infra"
  }
}

provider "google" {
  project = var.GCP_PROJECT_ID
  region  = var.GCP_REGION
}

# Data source to get project number
data "google_project" "project" {
  project_id = var.GCP_PROJECT_ID
}

# -------------------------------------------------------
# APIs
# -------------------------------------------------------
resource "google_project_service" "apis" {
  for_each = toset([
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "bigquery.googleapis.com",
    "secretmanager.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudscheduler.googleapis.com",
    "pubsub.googleapis.com"
  ])

  service            = each.key
  disable_on_destroy = false
}

# -------------------------------------------------------
# BigQuery
# -------------------------------------------------------
resource "google_bigquery_dataset" "litiere" {
  dataset_id    = "litiere"
  friendly_name = "Cat Litter Monitor"
  description   = "Events from the connected cat litter box"
  location      = "EU"

  depends_on = [google_project_service.apis]
}

resource "google_bigquery_table" "events" {
  dataset_id          = google_bigquery_dataset.litiere.dataset_id
  table_id            = "events"
  deletion_protection = false

  time_partitioning {
    type  = "DAY"
    field = "timestamp"
  }

  clustering = ["chat", "action"]

  schema = jsonencode([
    { name = "device_id", type = "STRING", mode = "NULLABLE" },
    { name = "timestamp", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "chat", type = "STRING", mode = "REQUIRED" },
    { name = "action", type = "STRING", mode = "REQUIRED" },
    { name = "poids", type = "FLOAT64", mode = "NULLABLE" },
    { name = "poids_chat", type = "FLOAT64", mode = "NULLABLE" },
    { name = "duree", type = "INT64", mode = "NULLABLE" },
    { name = "alerte", type = "STRING", mode = "NULLABLE" }
  ])
}

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


# -------------------------------------------------------
# Workload Identity Federation for GitHub Actions
# -------------------------------------------------------
resource "google_project_service" "wif_api" {
  service            = "iamcredentials.googleapis.com"
  disable_on_destroy = false
}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
  depends_on                = [google_project_service.wif_api]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Provider"

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.repository"       = "assertion.repository"
    "attribute.aud"              = "assertion.aud"
    "attribute.repository_owner" = "assertion.repository_owner"
  }

  # Only allow your GitHub org/repos
  attribute_condition = "assertion.repository_owner == 'Datally-Solutions'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Service Account for Terraform CI/CD
resource "google_service_account" "cicd_sa" {
  account_id   = "terraform-cicd-sa"
  display_name = "Terraform CI/CD SA"
}

# Permissions needed by Terraform to manage infra
# -------------------------------------------------------
# Custom Role for CI/CD SA
# -------------------------------------------------------
resource "google_project_iam_custom_role" "cicd_role" {
  role_id     = "terraformCicdRole"
  title       = "Terraform CI/CD Role"
  description = "Minimal permissions for Terraform CI/CD pipelines"
  stage       = "GA"

  permissions = [

    "resourcemanager.projects.get",
    # APIs
    "serviceusage.services.enable",
    "serviceusage.services.disable",
    "serviceusage.services.get",
    "serviceusage.services.list",

    # IAM
    "iam.roles.create",
    "iam.roles.delete",
    "iam.roles.get",
    "iam.roles.list",
    "iam.roles.update",
    "iam.serviceAccounts.actAs",
    "iam.serviceAccounts.create",
    "iam.serviceAccounts.delete",
    "iam.serviceAccounts.get",
    "iam.serviceAccounts.list",
    "iam.serviceAccounts.update",
    "iam.serviceAccounts.getAccessToken",
    "iam.serviceAccounts.getIamPolicy",
    "iam.serviceAccounts.setIamPolicy",
    "iam.workloadIdentityPoolProviders.create",
    "iam.workloadIdentityPoolProviders.delete",
    "iam.workloadIdentityPoolProviders.get",
    "iam.workloadIdentityPoolProviders.update",
    "iam.workloadIdentityPools.create",
    "iam.workloadIdentityPools.delete",
    "iam.workloadIdentityPools.get",
    "iam.workloadIdentityPools.update",

    # Cloud Build — trigger builds
    "cloudbuild.builds.create",
    "cloudbuild.builds.get",
    "cloudbuild.builds.list",

    # IAM policy bindings
    "resourcemanager.projects.getIamPolicy",
    "resourcemanager.projects.setIamPolicy",

    # BigQuery
    "bigquery.datasets.create",
    "bigquery.datasets.delete",
    "bigquery.datasets.get",
    "bigquery.datasets.update",
    "bigquery.tables.create",
    "bigquery.tables.delete",
    "bigquery.tables.get",
    "bigquery.tables.update",

    # Secret Manager
    "secretmanager.secrets.create",
    "secretmanager.secrets.delete",
    "secretmanager.secrets.get",
    "secretmanager.secrets.getIamPolicy",
    "secretmanager.secrets.list",
    "secretmanager.secrets.setIamPolicy",
    "secretmanager.secrets.update",
    "secretmanager.versions.access",
    "secretmanager.versions.add",
    "secretmanager.versions.destroy",
    "secretmanager.versions.disable",
    "secretmanager.versions.enable",
    "secretmanager.versions.get",
    "secretmanager.versions.list",

    # Storage (for state bucket + function source)
    "storage.buckets.create",
    "storage.buckets.delete",
    "storage.buckets.get",
    "storage.buckets.getIamPolicy",
    "storage.buckets.list",
    "storage.buckets.setIamPolicy",
    "storage.buckets.update",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.update",

    # Cloud Functions v2
    "cloudfunctions.functions.create",
    "cloudfunctions.functions.delete",
    "cloudfunctions.functions.get",
    "cloudfunctions.functions.getIamPolicy",
    "cloudfunctions.functions.list",
    "cloudfunctions.functions.setIamPolicy",
    "cloudfunctions.functions.update",
    "cloudfunctions.operations.get",

    # Cloud Run (functions v2 backend)
    "run.services.create",
    "run.services.delete",
    "run.services.get",
    "run.services.getIamPolicy",
    "run.services.list",
    "run.services.setIamPolicy",
    "run.services.update",
    "run.operations.get",

    # Pub/Sub
    "pubsub.topics.create",
    "pubsub.topics.delete",
    "pubsub.topics.get",
    "pubsub.topics.getIamPolicy",
    "pubsub.topics.list",
    "pubsub.topics.setIamPolicy",
    "pubsub.topics.update",

    # Cloud Scheduler
    "cloudscheduler.jobs.create",
    "cloudscheduler.jobs.delete",
    "cloudscheduler.jobs.get",
    "cloudscheduler.jobs.list",
    "cloudscheduler.jobs.update",
    "cloudscheduler.jobs.enable",

    # Artifact Registry (needed by Cloud Functions v2 build)
    "artifactregistry.repositories.create",
    "artifactregistry.repositories.delete",
    "artifactregistry.repositories.get",
    "artifactregistry.repositories.list",
    "artifactregistry.repositories.update",
    "artifactregistry.repositories.getIamPolicy",
    "artifactregistry.repositories.setIamPolicy",
    "artifactregistry.repositories.downloadArtifacts",

    # Firestore database
    "datastore.databases.get",
    "datastore.databases.list",
    "datastore.databases.update",

    # Firestore indexes
    "datastore.indexes.create",
    "datastore.indexes.delete",
    "datastore.indexes.get",
    "datastore.indexes.list",
    "datastore.indexes.update",

  ]
}

# Assign custom role to CI/CD SA
resource "google_project_iam_member" "cicd_custom_role" {
  project = var.GCP_PROJECT_ID
  role    = google_project_iam_custom_role.cicd_role.id
  member  = "serviceAccount:${google_service_account.cicd_sa.email}"
}

# GCS bucket for Terraform state
resource "google_storage_bucket" "tfstate" {
  name                        = "${var.GCP_PROJECT_ID}-tfstate"
  location                    = "EU"
  force_destroy               = false
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 10
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_artifact_registry_repository" "api" {
  location      = var.GCP_REGION
  repository_id = "${var.GCP_PROJECT_ID}-registry-docker"
  format        = "DOCKER"
}

resource "google_artifact_registry_repository_iam_member" "cloudbuild_push" {
  project    = var.GCP_PROJECT_ID
  location   = var.GCP_REGION
  repository = google_artifact_registry_repository.api.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

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
