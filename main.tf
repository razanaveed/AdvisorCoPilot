terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

########################
# Providers & Variables
########################

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region (e.g. europe-west1)"
  type        = string
}

variable "cloud_run_location" {
  description = "Cloud Run location (region or multi-region)"
  type        = string
  default     = "europe-west1"
}

variable "service_name" {
  description = "Cloud Run service name"
  type        = string
  default     = "advisor-copilot"
}

variable "image" {
  description = "Container image for the Phoenix app"
  type        = string
  # e.g. "europe-west1-docker.pkg.dev/${var.project_id}/advisor-copilot/phoenix:latest"
}

variable "database_url" {
  description = <<EOF
DATABASE_URL for the app.

For current SQLite-based deployment, you might use a file path the app understands, e.g.:

  sqlite:///data/dev.db

Later, switch to PostgreSQL by setting something like:

  ecto://USER:PASSWORD@HOST:5432/DB_NAME
EOF
  type        = string
  default     = "sqlite:///data/dev.db"
}

variable "cpu" {
  description = "vCPU for Cloud Run container"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory for Cloud Run container"
  type        = string
  default     = "512Mi"
}

variable "max_instances" {
  description = "Max instances for Cloud Run"
  type        = number
  default     = 5
}

variable "min_instances" {
  description = "Min instances for Cloud Run"
  type        = number
  default     = 0
}

########################
# Secrets / Randomness
########################

# Phoenix SECRET_KEY_BASE – strong, random, no special chars
resource "random_password" "secret_key_base" {
  length  = 64
  special = false
}

########################
# Service Account (App)
########################

# Dedicated SA for the Phoenix app, least-privilege
resource "google_service_account" "app" {
  account_id   = "${var.service_name}-sa"
  display_name = "Advisor CoPilot Cloud Run service account"
}

# Logging + future Cloud SQL access (for Postgres later)
resource "google_project_iam_member" "app_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.app.email}"
}

resource "google_project_iam_member" "app_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.app.email}"
}

########################
# Cloud Run Service
########################

resource "google_cloud_run_v2_service" "phoenix" {
  name     = var.service_name
  location = var.cloud_run_location

  template {
    service_account = google_service_account.app.email
    max_instance_request_concurrency = 80

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      image = var.image

      resources {
        cpu_idle = true
        limits = {
          "cpu"    = tostring(var.cpu)
          "memory" = var.memory
        }
      }

      env {
        name  = "DATABASE_URL"
        value = var.database_url
      }

      env {
        name  = "SECRET_KEY_BASE"
        value = random_password.secret_key_base.result
      }

      # Example Phoenix envs you may want:
      # env { name = "PHX_SERVER" value = "true" }
      # env { name = "PHX_HOST"   value = google_cloud_run_v2_service.phoenix.uri }
      # env { name = "PORT"       value = "8080" }
    }

    # HTTP on 8080 is the Cloud Run default; Phoenix should listen there.
    # You can add more annotations or revisions settings here if needed.
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

########################
# Public Access (Optional)
########################

# Allow unauthenticated invocations if this is a public web app.
# For private access, remove this and use IAM / IAP instead.
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  location = google_cloud_run_v2_service.phoenix.location
  name     = google_cloud_run_v2_service.phoenix.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

########################
# API Enablement
########################

resource "google_project_service" "run" {
  project = var.project_id
  service = "run.googleapis.com"
}

resource "google_project_service" "iam" {
  project = var.project_id
  service = "iam.googleapis.com"
}

# For future Cloud SQL Postgres:
resource "google_project_service" "sqladmin" {
  project = var.project_id
  service = "sqladmin.googleapis.com"
}

########################
# Outputs
########################

output "cloud_run_url" {
  description = "URL of the Phoenix Cloud Run service"
  value       = google_cloud_run_v2_service.phoenix.uri
}

output "service_account_email" {
  description = "Service account used by the Phoenix app"
  value       = google_service_account.app.email
}