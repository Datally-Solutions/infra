variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-west9"
}

variable "ingest_token" {
  description = "Secret token to authenticate ESP32 requests"
  type        = string
  sensitive   = true
}