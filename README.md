# infra

Terraform root for the Cat Litter Monitor GCP project. Manages all shared infrastructure consumed by the `backend` and `cicd` repos.

## What this provisions

| Resource | Purpose |
|----------|---------|
| Firestore (named DB) | Real-time data — households, events, box_state, health_alerts |
| BigQuery datasets + tables | Long-term analytics — raw_sessions, classified_events |
| Artifact Registry | Docker images for the litter-api Cloud Run service |
| GCS buckets | Terraform state, firmware binaries |
| Secret Manager | `litter-ingest-token` (shared ESP32/backend secret) |
| Workload Identity Federation | Keyless GCP auth for GitHub Actions |
| CI/CD service account + custom role | Minimal-permission SA for Terraform pipelines |
| Cloud Monitoring + alerting | Error rate alerts, email notifications |
| Cloud Logging sink | Device logs → BigQuery |

## Prerequisites

- Terraform >= 1.5.0
- GCP project with billing enabled
- `gcloud auth application-default login`

## Usage

```bash
# First-time bootstrap (state bucket must exist already)
gcloud storage buckets create gs://cat-litter-monitor-tfstate --location=europe-west9

terraform init \
  -backend-config="bucket=cat-litter-monitor-tfstate" \
  -backend-config="prefix=infra"

terraform plan
terraform apply
```

Required variables (`terraform.tfvars`, gitignored):

```hcl
GCP_PROJECT_ID = "your-project-id"
GCP_REGION     = "europe-west9"
ingest_token   = "your-random-secret"
alert_email    = "you@example.com"
```

## CI/CD

Deployed automatically on push to `main` via [deploy_terraform_firebase.yml](.github/workflows/deploy_terraform_firebase.yml), which calls the shared [cicd reusable workflow](https://github.com/Datally-Solutions/cicd).

GitHub Actions authenticates via Workload Identity Federation — no long-lived service account keys. Access is restricted to the `Datally-Solutions` org (fork PRs cannot obtain GCP credentials).

## Firestore rules & indexes

Firestore security rules and indexes are deployed separately via the Firebase CLI step in the same workflow:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

## Terraform reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_GCP_PROJECT_ID"></a> [GCP\_PROJECT\_ID](#input\_GCP\_PROJECT\_ID) | GCP Project ID | `string` | n/a | yes |
| <a name="input_GCP_REGION"></a> [GCP\_REGION](#input\_GCP\_REGION) | GCP region | `string` | `"europe-west9"` | no |
| <a name="input_alert_email"></a> [alert\_email](#input\_alert\_email) | Email address for monitoring alerts | `string` | n/a | yes |
| <a name="input_ingest_token"></a> [ingest\_token](#input\_ingest\_token) | Secret token to authenticate ESP32 ingest requests | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_wif_provider"></a> [wif\_provider](#output\_wif\_provider) | Workload Identity Provider — use in GitHub Actions secrets |
| <a name="output_cicd_sa_email"></a> [cicd\_sa\_email](#output\_cicd\_sa\_email) | CI/CD service account email |
| <a name="output_firestore_database"></a> [firestore\_database](#output\_firestore\_database) | Firestore database name |
| <a name="output_firmware_bucket"></a> [firmware\_bucket](#output\_firmware\_bucket) | GCS bucket for firmware OTA binaries |
<!-- END_TF_DOCS -->
