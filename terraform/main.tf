terraform {
  # 1. Salva a memória para o botão de DESTROY funcionar
  backend "gcs" {
    bucket  = "santander-repo-tfstate" # Nome que você deve dar ao seu bucket na GCP
    prefix  = "terraform/state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# --- VARIÁVEIS ---
variable "project_id" {}
variable "region"     { default = "us-central1" }
variable "image_name" { default = "card-system-api" }
variable "image_tag"  {}

# 1. Cloud Run (Serverless - Econômico para Free Tier)
resource "google_cloud_run_v2_service" "api" {
  name     = "card-system-api"
  location = var.region

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/santander-repo/${var.image_name}:${var.image_tag}"
      
      ports {
        container_port = 8080
      }
    }
  }
}

# 2. Liberação de acesso público
resource "google_cloud_run_v2_service_iam_member" "noauth" {
  location = google_cloud_run_v2_service.api.location
  name     = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}