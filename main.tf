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
    { name = "timestamp",  type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "chat",       type = "STRING",    mode = "REQUIRED" },
    { name = "action",     type = "STRING",    mode = "REQUIRED" },
    { name = "poids",      type = "FLOAT64",   mode = "NULLABLE" },
    { name = "poids_chat", type = "FLOAT64",   mode = "NULLABLE" },
    { name = "duree",      type = "INT64",     mode = "NULLABLE" },
    { name = "alerte",     type = "STRING",    mode = "NULLABLE" }
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
# Service Account for Cloud Function
# -------------------------------------------------------
resource "google_service_account" "function_sa" {
  account_id   = "litter-function-sa"
  display_name = "Cat Litter Function SA"
}

resource "google_project_iam_member" "function_bigquery_editor" {
  project = var.GCP_PROJECT_ID
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

resource "google_project_iam_member" "function_bigquery_job" {
  project = var.GCP_PROJECT_ID
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "function_secret_access" {
  secret_id = google_secret_manager_secret.ingest_token.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.function_sa.email}"
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
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.aud"       = "assertion.aud" 
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

# Allow GitHub Actions to impersonate the SA
resource "google_service_account_iam_member" "github_wif" {
  service_account_id = google_service_account.cicd_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository_owner/Datally-Solutions"
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
    "iam.workloadIdentityPoolProviders.create",
    "iam.workloadIdentityPoolProviders.delete",
    "iam.workloadIdentityPoolProviders.get",
    "iam.workloadIdentityPoolProviders.update",
    "iam.workloadIdentityPools.create",
    "iam.workloadIdentityPools.delete",
    "iam.workloadIdentityPools.get",
    "iam.workloadIdentityPools.update",

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

    # Artifact Registry (needed by Cloud Functions v2 build)
    "artifactregistry.repositories.create",
    "artifactregistry.repositories.delete",
    "artifactregistry.repositories.get",
    "artifactregistry.repositories.list",
    "artifactregistry.repositories.update",
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
