provider "google" {
  project = var.project_id
  region  = var.region
}

# 1. Repositório de Imagens (Artifact Registry)
resource "google_artifact_registry_repository" "santander_repo" {
  location      = var.region
  repository_id = "santander-api-repo"
  description   = "Docker repository for Card System Platform"
  format        = "DOCKER"
}

# 2. Serviço Cloud Run (API)
resource "google_cloud_run_service" "card_api" {
  name     = "santander-card-api"
  location = var.region

  template {
    spec {
      containers {
        # Imagem placeholder - será atualizada pelo CI/CD
        image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.santander_repo.repository_id}/card-system-api:latest"
        
        resources {
          limits = {
            cpu    = "1000m" # 1 vCPU (FinOps: limite controlado)
            memory = "512Mi"
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# 3. Tornar a API Pública (IAM)
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.card_api.name
  location = google_cloud_run_service.card_api.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
