provider "google" {
  credentials = file(var.gcp_credentials_file)
  project     = var.gcp_project_id
  region      = var.gcp_region
}

variable "gcp_credentials_file" {
  type        = string
  description = "Path to the GCP service account key file"
  sensitive   = true
}

variable "gcp_project_id" {
  type        = string
  description = "ID of the GCP project"
}

variable "gcp_region" {
  type        = string
  description = "Region for the GCP resources"
}

variable "gcs_bucket_name" {
  type        = string
  description = "Name of the GCS bucket"
  default     = "sales-data-bucket"
}

variable "bigquery_dataset_name" {
  type        = string
  description = "Name of the BigQuery dataset"
  default     = "sales_data"
}

variable "vortex_notebook_name" {
  type        = string
  description = "Name of the Vortex AI notebook"
  default     = "sales-analytics-notebook"
}

resource "google_storage_bucket" "gcs_bucket" {
  name     = var.gcs_bucket_name
  location = var.gcp_region

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_bigquery_dataset" "bq_dataset" {
  dataset_id                 = var.bigquery_dataset_name
  location                   = var.gcp_region
  default_table_expiration_ms = 2678400000 # 31 days

  access {
    role         = "OWNER"
    user_by_email = google_service_account.vortex_notebook.email
  }
}

resource "google_service_account" "vortex_notebook" {
  account_id   = var.vortex_notebook_name
  display_name = var.vortex_notebook_name
}

resource "google_notebooks_instance" "vortex_notebook_instance" {
  name            = var.vortex_notebook_name
  location        = var.gcp_region
  machine_type    = "n1-standard-4"
  boot_disk_size  = 100
  install_gpu_driver = false

  metadata {
    enable-oslogin = "true"
  }

  service_account {
    email  = google_service_account.vortex_notebook.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
