# Infrastructure — Cat Litter Monitor
#
# Resources are split by domain:
#   providers.tf  — provider "google" + data sources
#   apis.tf       — google_project_service
#   bigquery.tf   — datasets, tables, log sink
#   firestore.tf  — database, indexes, TTL
#   iam.tf        — WIF, service accounts, custom roles
#   monitoring.tf — notification channels, alert policies
#   secrets.tf    — Secret Manager
#   storage.tf    — GCS buckets, Artifact Registry
