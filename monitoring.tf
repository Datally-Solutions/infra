# -------------------------------------------------------
# Monitoring — notification channel + alert policies
# -------------------------------------------------------

resource "google_monitoring_notification_channel" "email" {
  display_name = "Alerts Email"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }

  depends_on = [google_project_service.apis]
}

# Log-based metric: ERROR logs from ESP32 devices
resource "google_logging_metric" "device_error_count" {
  name        = "device_error_count"
  description = "Number of ERROR+ log entries from litiere-device-* logs"
  filter      = "logName=~\"projects/${var.GCP_PROJECT_ID}/logs/litiere-device-\" AND severity >= ERROR"

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    display_name = "Device Error Count"
  }

  depends_on = [google_project_service.apis]
}

# Alert: device error rate
# Triggers when more than 5 device ERROR logs are received in a 1-hour window.
resource "google_monitoring_alert_policy" "device_errors" {
  display_name = "[litiere] Device Error Rate"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Device error logs > 5 / hour"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/device_error_count\" resource.type=\"global\""
      duration        = "0s"
      comparison      = "COMPARISON_GT"
      threshold_value = 5

      aggregations {
        alignment_period   = "3600s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  alert_strategy {
    auto_close = "604800s" # 7 days
  }

  depends_on = [google_logging_metric.device_error_count]
}

# Alert: Cloud Function execution errors (litter-ingest, litter-health-checker, etc.)
# Triggers on any non-ok execution (error, timeout, out_of_memory, etc.)
resource "google_monitoring_alert_policy" "function_errors" {
  display_name = "[litiere] Cloud Function Errors"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Function non-ok executions > 0 in 10 min"

    condition_threshold {
      filter          = "metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" resource.type=\"cloud_function\" metric.labels.status!=\"ok\""
      duration        = "0s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0

      aggregations {
        alignment_period   = "600s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  alert_strategy {
    auto_close = "604800s"
  }
}
