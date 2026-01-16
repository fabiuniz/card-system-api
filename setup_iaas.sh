echo "🏗️ Configurando Camada de IaaS e Infraestrutura..."
#cat <<EOF > .idx/dev.nix
#EOF

#cat <<EOF > clear_all_service.sh
#EOF

# --- DOCUMENTAÇÃO TÉCNICA (Mermaid Flow) ---
cat <<EOF > flow.md
flowchart LR
    subgraph "Fontes de Dados (Ecossistema F1RST)"
        A1["☕ Java API: Microserviços"]
        A2["📜 Logs: Eventos de Sistema"]
        A3["📈 Métricas: CPU/Memória/Negócio"]
    end

    subgraph "Camada de Ingestão e Inteligência (AIOps)"
        B1{{"🛠️ Python Script: Integrador/Coletor"}}
        B2["📥 Pipeline: Kafka / Logstash"]
        B3["🧠 Modelo de IA: Detecção de Anomalias"]
    end

    subgraph "Visualização e Ação (Dashboard/SRE)"
        C1["📊 Grafana / Kibana: Dashboards"]
        C2["⚠️ Alerta Automático: Webhook/Teams"]
        C3["☸️ Kubernetes: Auto-Scaling"]
    end

    A1 & A2 & A3 -->|Telemetria Raw| B1
    B1 -->|Dados Estruturados| B2
    B2 --> B3
    B3 -->|Insight de Falha| C1 & C2
    C2 -->|Trigger de Resiliência| C3

    style B1 fill:#ffd700,stroke:#333,stroke-width:2px,color:#000
    style B3 fill:#f94144,stroke:#333,color:#fff
    style C3 fill:#90be6d,stroke:#333,color:#000


    T["💳 Card System Platform - Santander/F1RST Evolution"]
    
    subgraph "Camada de Processamento e Observabilidade"
        P1(1. ☕ Microserviço: Processamento de Transações - **Java 11 / Spring Boot**<br>Arquitetura Hexagonal: Validação de Limites e Persistência MySQL)
        P2(2. 📊 Telemetria: Coleta de Métricas - **Micrometer / Actuator**<br>Exposição de dados para Prometheus: Status, Latência e Volume)
        P3(3. 🤖 Agente AIOps: Automação de Saúde - **Python AI Agent**<br>Análise de telemetria em tempo real e detecção de anomalias)
        P4(4. ☁️ Orquestração: Gestão de Containers - **Kubernetes / Cloud Run**<br>Auto-cura via Liveness Probes e Escalonamento HPA)
    end
    
    style T fill:#ec1c24,stroke:#333,stroke-width:2px,color:white
    
    D1[📁 Entrada: Transações de Cartão - **API REST**<br>Inputs: Número do Cartão e Valor da Compra]
    D2[📉 Dashboard de Operações: Visão SRE - **Grafana**<br>Visualização de Aprovações vs Rejeições e Saúde da JVM]
    D3[💾 Persistência de Dados - **MySQL / Hibernate**<br>Storage de histórico de transações e logs de auditoria]

    D1 -->|Requisição JSON| P1
    P1 -->|Métricas de Negócio| P2
    P2 -->|Feed de Dados| D2
    P1 -->|Entidade de Domínio| D3
    
    P2 -->|Status da API| P3
    P3 -->|Ações Corretivas / Alertas| P4
    P4 -->|Garante Disponibilidade| P1    

    T["**Projeto Card System API**<br/>Arquitetura e Entrega Nível III"]
    
    T --> Fase1

    subgraph Fase1 ["**Fase 1: Core Domain**"]
        direction TB
        A["💎 **Business Rules**:<br/>Validação de Limite R$ 10k"] 
        B["🔒 **Domain Isolation**:<br/>POJOs sem Framework Leak"]
        C["🧪 **Unit Testing**:<br/>JUnit 5 & AssertJ"]
        A --> B --> C
    end

    subgraph Fase2 ["**Fase 2: Adapters & Documentation**"]
        direction TB
        D["🌐 **REST API**:<br/>Spring Boot 2.7"]
        E["📖 **Swagger/OpenAPI**:<br/>Docs Interativas v3"]
        F["🛡️ **Resilience**:<br/>Global Exception Handler"]
        D --> E --> F
    end
    
    subgraph Fase3 ["**Fase 3: Cloud & SRE**"]
        direction TB
        G["🐳 **Dockerization**:<br/>Amazon Corretto 11 Alpine"]
        H["📊 **Observability**:<br/>UUID Trace & Logs"]
        I["🚀 **GitOps**:<br/>Semantic Versioning & Hooks"]
        G --> H --> I
    end

    Fase1 --> Fase2
    Fase2 --> Fase3
    
    style T fill:#f9f9f9,stroke:#333,stroke-width:2px,color:#000
    style A fill:#fb6c10,stroke:#333,color:#fff
    style E fill:#85ea2d,stroke:#333,color:#000
    style G fill:#005f73,stroke:#333,color:#fff
    style I fill:#0fa9a0,stroke:#333,color:#fff
    
    style Fase1 fill:#fff5f5,stroke:#ff8c8c,stroke-width:2px
    style Fase2 fill:#f5fff5,stroke:#8cff8c,stroke-width:2px
    style Fase3 fill:#f5f5ff,stroke:#8c8cff,stroke-width:2px
EOF

# --- KUBERNETES: DEPLOYMENT ---
cat <<EOF > k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: santander-card-api
  labels:
    app: card-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: card-api
  template:
    metadata:
      labels:
        app: card-api
    spec:
      containers:
      - name: card-api
        image: gcr.io/santander-repo/card-system-api:1.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: "250m"
            memory: "512Mi"
          limits:
            cpu: "500m"
            memory: "1Gi"
        # Garante que o tráfego só chegue quando a JVM subir
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 20
          periodSeconds: 10
        # Reinicia o container se a aplicação travar
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 20
EOF

# --- KUBERNETES: HPA & SERVICE ---
cat <<EOF > k8s/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: card-api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: santander-card-api
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
EOF

cat <<EOF > k8s/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: santander-card-api-service
spec:
  type: LoadBalancer
  selector:
    app: card-api
  ports:
    - protocol: TCP
      port: 80        # Porta externa
      targetPort: 8080 # Porta interna do container
EOF

# --- TERRAFORM: GOOGLE CLOUD ---
cat <<EOF > terraform/main.tf
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
        image = "\${var.region}-docker.pkg.dev/\${var.project_id}/\${google_artifact_registry_repository.santander_repo.repository_id}/card-system-api:latest"
        
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
EOF

# --- DOCKERFILE ---
cat <<EOF > Dockerfile
FROM amazoncorretto:11-alpine
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF

# --- GITHUB ACTIONS: CI/CD ---
cat <<'EOF' > .github/workflows/deploy.yml
name: CI/CD Santander F1RST

on:
  push:
    branches: [ "main" ]

env:
  PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
  REGION: us-central1
  REPO_NAME: santander-repo
  IMAGE_NAME: card-system-api

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    # Define o diretório de trabalho para que o GitHub saiba que os comandos devem rodar dentro da pasta da API
    defaults:
      run:
        working-directory: ./card-system-api

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up JDK 11
        uses: actions/setup-java@v3
        with:
          java-version: '11'
          distribution: 'temurin'
          cache: maven

      - name: Build with Maven
        run: mvn clean package -DskipTests

      - name: Google Auth
        uses: 'google-github-actions/auth@v2'
        with:
          credentials_json: '${{ secrets.GCP_SA_KEY }}'

      - name: Docker Auth
        run: gcloud auth configure-docker us-central1-docker.pkg.dev

      - name: Build and Push Container
        run: |
          docker build -t us-central1-docker.pkg.dev/${{ env.PROJECT_ID }}/${{ env.REPO_NAME }}/${{ env.IMAGE_NAME }}:${{ github.sha }} .
          docker push us-central1-docker.pkg.dev/${{ env.PROJECT_ID }}/${{ env.REPO_NAME }}/${{ env.IMAGE_NAME }}:${{ github.sha }}

      - name: Deploy to Cloud Run
        uses: 'google-github-actions/deploy-cloudrun@v2'
        with:
          service: ${{ env.IMAGE_NAME }}
          image: us-central1-docker.pkg.dev/${{ env.PROJECT_ID }}/${{ env.REPO_NAME }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          region: ${{ env.REGION }}
          flags: '--allow-unauthenticated'
EOF

# --- SCRIPT DE LIMPEZA ---
cat <<EOF > clear_all_service.sh
#!/bin/bash
echo "♻️ Resetando ambiente de desenvolvimento..."
docker stop santander-api prometheus grafana || true
docker rm santander-api prometheus grafana || true
docker-compose -f monitoring/docker-compose.yml down || true
mvn clean
echo "✅ Ambiente limpo."
EOF
chmod +x clear_all_service.sh

echo "✅ IaaS configurada com sucesso!"