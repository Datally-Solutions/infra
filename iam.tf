# -------------------------------------------------------
# IAM — Workload Identity Federation + CI/CD Service Account
# -------------------------------------------------------

# iamcredentials must stay separate: disable_on_destroy=false (never disable it accidentally)
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

  attribute_condition = "assertion.repository in ['Datally-Solutions/backend', 'Datally-Solutions/infra', 'Datally-Solutions/firmware', 'Datally-Solutions/cicd'] && assertion.repository_owner == 'Datally-Solutions'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "cicd_sa" {
  account_id   = "terraform-cicd-sa"
  display_name = "Terraform CI/CD SA"
}

# -------------------------------------------------------
# Custom Role — minimal permissions for Terraform CI/CD
# (covers both infra and backend repos)
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

    # Cloud Build
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

    # Storage (state bucket + function source)
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

    # Cloud Scheduler (jobs managed in backend repo)
    "cloudscheduler.jobs.create",
    "cloudscheduler.jobs.delete",
    "cloudscheduler.jobs.get",
    "cloudscheduler.jobs.list",
    "cloudscheduler.jobs.update",
    "cloudscheduler.jobs.enable",

    # Artifact Registry
    "artifactregistry.repositories.create",
    "artifactregistry.repositories.delete",
    "artifactregistry.repositories.get",
    "artifactregistry.repositories.list",
    "artifactregistry.repositories.update",
    "artifactregistry.repositories.getIamPolicy",
    "artifactregistry.repositories.setIamPolicy",
    "artifactregistry.repositories.downloadArtifacts",

    # Firebase / Firestore
    "firebase.projects.get",
    "firebase.projects.update",
    "datastore.databases.get",
    "datastore.databases.getMetadata",
    "datastore.databases.list",
    "datastore.databases.update",
    "datastore.indexes.create",
    "datastore.indexes.delete",
    "datastore.indexes.get",
    "datastore.indexes.list",
    "datastore.indexes.update",

    # Logging
    "logging.sinks.create",
    "logging.sinks.delete",
    "logging.sinks.get",
    "logging.sinks.list",
    "logging.sinks.update",

    # Monitoring
    "monitoring.alertPolicies.create",
    "monitoring.alertPolicies.delete",
    "monitoring.alertPolicies.get",
    "monitoring.alertPolicies.list",
    "monitoring.alertPolicies.update",
    "monitoring.notificationChannels.create",
    "monitoring.notificationChannels.delete",
    "monitoring.notificationChannels.get",
    "monitoring.notificationChannels.list",
    "monitoring.notificationChannels.update",
    "logging.logMetrics.create",
    "logging.logMetrics.delete",
    "logging.logMetrics.get",
    "logging.logMetrics.list",
    "logging.logMetrics.update",
  ]
}

resource "google_project_iam_member" "cicd_firestore_admin" {
  project = var.GCP_PROJECT_ID
  role    = "roles/datastore.owner"
  member  = "serviceAccount:${google_service_account.cicd_sa.email}"
}

resource "google_project_iam_member" "cicd_firebase_admin" {
  project = var.GCP_PROJECT_ID
  role    = "roles/firebase.admin"
  member  = "serviceAccount:${google_service_account.cicd_sa.email}"
}

resource "google_project_iam_member" "cicd_custom_role" {
  project = var.GCP_PROJECT_ID
  role    = google_project_iam_custom_role.cicd_role.id
  member  = "serviceAccount:${google_service_account.cicd_sa.email}"
}
