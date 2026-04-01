<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 5.45.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_artifact_registry_repository.api](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository) | resource |
| [google_artifact_registry_repository_iam_member.cloudbuild_push](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository_iam_member) | resource |
| [google_bigquery_dataset.litiere](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset) | resource |
| [google_bigquery_table.classified_events](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_table) | resource |
| [google_bigquery_table.raw_sessions](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_table) | resource |
| [google_firestore_database.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/firestore_database) | resource |
| [google_firestore_field.events_ttl](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/firestore_field) | resource |
| [google_firestore_field.health_alerts_ttl](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/firestore_field) | resource |
| [google_firestore_index.health_alerts_acknowledged_timestamp](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/firestore_index) | resource |
| [google_firestore_index.health_alerts_cat_alert_timestamp](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/firestore_index) | resource |
| [google_iam_workload_identity_pool.github](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool) | resource |
| [google_iam_workload_identity_pool_provider.github](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider) | resource |
| [google_project_iam_custom_role.cicd_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_member.cicd_custom_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.cicd_firebase_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.cicd_firestore_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_service.apis](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project_service.wif_api](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_secret_manager_secret.ingest_token](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret_version.ingest_token](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [google_service_account.cicd_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_storage_bucket.firmware](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket.tfstate](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_iam_member.firmware_public](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_GCP_PROJECT_ID"></a> [GCP\_PROJECT\_ID](#input\_GCP\_PROJECT\_ID) | GCP Project ID | `string` | n/a | yes |
| <a name="input_GCP_REGION"></a> [GCP\_REGION](#input\_GCP\_REGION) | GCP region | `string` | `"europe-west9"` | no |
| <a name="input_ingest_token"></a> [ingest\_token](#input\_ingest\_token) | Secret token to authenticate ESP32 requests | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bigquery_dataset_litiere"></a> [bigquery\_dataset\_litiere](#output\_bigquery\_dataset\_litiere) | BigQuery dataset for Litière project |
| <a name="output_bigquery_table_classified_events"></a> [bigquery\_table\_classified\_events](#output\_bigquery\_table\_classified\_events) | BigQuery classified events table name |
| <a name="output_bigquery_table_raw_sessions"></a> [bigquery\_table\_raw\_sessions](#output\_bigquery\_table\_raw\_sessions) | BigQuery raw sessions table name |
| <a name="output_cicd_sa_email"></a> [cicd\_sa\_email](#output\_cicd\_sa\_email) | CI/CD Service Account email — use in GitHub Actions |
| <a name="output_firestore_database"></a> [firestore\_database](#output\_firestore\_database) | Firestore database name |
| <a name="output_tfstate_bucket"></a> [tfstate\_bucket](#output\_tfstate\_bucket) | GCS bucket for Terraform state |
| <a name="output_wif_provider"></a> [wif\_provider](#output\_wif\_provider) | Workload Identity Provider — use in GitHub Actions |
<!-- END_TF_DOCS -->
