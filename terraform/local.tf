# Definindo que o Terraform vai falar com o seu Docker local
provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Criando a imagem localmente (equivalente ao build do compose)
resource "docker_image" "api_image" {
  name = "card-system-api:local"
  build {
    context = ".." # Sobe um nível para pegar o Dockerfile na raiz
  }
}

# Criando o container
resource "docker_container" "api_container" {
  name  = "santander-api-dev"
  image = docker_image.api_image.image_id
  
  ports {
    internal = 8080
    external = 8080
  }

  env = [
    "SPRING_PROFILES_ACTIVE=dev",
    "TRANSACTION_LIMIT=5000"
  ]
}
