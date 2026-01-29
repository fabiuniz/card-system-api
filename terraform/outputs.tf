output "repository_url" {
  description = "URL do Artifact Registry"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.santander_repo.repository_id}"
}

output "service_url" {
  description = "URL pública da API no Cloud Run"
  value       = google_cloud_run_service.card_api.status[0].url
}