variable "GCP_PROJECT_ID" {
  description = "GCP Project ID"
  type        = string
}

variable "GCP_REGION" {
  description = "GCP region"
  type        = string
  default     = "europe-west9"
}

variable "ingest_token" {
  description = "Secret token to authenticate ESP32 requests"
  type        = string
  sensitive   = true
}