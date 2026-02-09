#!/bin/bash

# Validação simples: se o array não existir, para o script
if [[ -z "${PROJETO_CONF[PROJECT_NAME]}" ]]; then
    echo "🚨 Erro: Configurações do projeto não encontradas!"
    return 1 # Usa return pois estamos usando 'source' (.)
fi

echo "🏗️ Configurando Camada de IaaS e Infraestrutura ${PROJETO_CONF[NOME]}..."
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
        image: card-system-api:1.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: "250m"
            memory: "512Mi"
          limits:
            cpu: "500m"
            memory: "1Gi"
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 20
          periodSeconds: 10
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


# --- NGNIX ---
# 
cat <<EOF > monitoring/nginx/nginx.conf
events {}
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    server {
        listen 80;
        server_name ${PROJETO_CONF[HOST_NAME]};

        location / {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
        }

        # Opcional: manter logs de erro para facilitar debug se necessário
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }
    }
}
EOF

# --- GRAFANA DATASOURCE ---
cat <<EOF > monitoring/grafana/provisioning/datasources/datasource.yml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    uid: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

# --- GRAFANA CONFIG---
cat <<EOF > monitoring/grafana/provisioning/dashboards/dashboard_config.yml
apiVersion: 1
providers:
  - name: 'Default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    editable: true
    options:
      path: /etc/grafana/provisioning/dashboards
EOF

# Baixa o dashboard padrão da JVM (ID 4701)
curl -s https://grafana.com/api/dashboards/4701/revisions/10/download > monitoring/grafana/provisioning/dashboards/jvm_micrometer.json

# Garante que qualquer referência de datasource aponte para o seu UID "prometheus"
sed -i 's/\${DS_PROMETHEUS}/prometheus/g' monitoring/grafana/provisioning/dashboards/jvm_micrometer.json
sed -i 's/"datasource": ".*"/"datasource": "prometheus"/g' monitoring/grafana/provisioning/dashboards/jvm_micrometer.json
sed -i 's/"from": "now-24h"/"from": "now-1m"/g' monitoring/grafana/provisioning/dashboards/jvm_micrometer.json

# --- PROMETHEUS ---
cat <<EOF > monitoring/prometheus/prometheus.yml
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: 'card-system-api'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['${PROJETO_CONF[INTERNAL_HOST]}:8080'] # Se rodar API no host e Prom no Docker
EOF

# --- DOCKERFILE ---
cat <<EOF > Dockerfile
FROM amazoncorretto:11-alpine
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF

# --- DOCKER COMPOSE ---
cat <<EOF > docker-compose.yml
version: "3"
services:
  nginx:
    image: nginx:latest
    container_name: nginx-proxy
    ports:
      - "8081:80"
    volumes:
      - ./monitoring/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    networks:
      - monitoring

  santander-front-vue:
      build: ./card-system-front-vue
      container_name: santander-front-vue
      ports:
        - "4000:4000"
      networks:
        - monitoring
      depends_on:
        - santander-api

  santander-front-react:
      build: 
        context: ./card-system-front-react
      container_name: santander-front-react
      ports:
        - "4300:4300"      
      environment:
        - CHOKIDAR_USEPOLLING=true
      networks:
        - monitoring
      depends_on:
        - santander-api
  
  santander-front-angular:
      build: 
        context: ./card-system-front-angular
        dockerfile: Dockerfile
      container_name: santander-front-angular
      ports:
        - "4200:4200"
      networks:
        - monitoring
      depends_on:
        - santander-api

  santander-api:
    image: card-system-api:1.0
    container_name: santander-api
    ports:
      - "8080:8080"
    networks:
      - monitoring

  prometheus:
    image: prom/prometheus:v2.47.1
    container_name: prometheus
    user: root
    volumes:
      - ./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    networks:
      - monitoring
    depends_on:
      - santander-api

  grafana:
    image: grafana/grafana:10.1.5
    container_name: grafana
    user: "472"
    ports:
      - "3000:3000"
    volumes:
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning
    environment:
      - GF_AUTH_ANONYMOUS_ORG_ROLE=Admin
      - GF_AUTH_ANONYMOUS_ENABLED=true
    networks:
      - monitoring
    depends_on:
      - prometheus

  mongodb:
    image: mongo:7.0
    container_name: mongodb
    ports:
      - "27017:27017"
    environment:
      - MONGO_INITDB_ROOT_USERNAME=admin
      - MONGO_INITDB_ROOT_PASSWORD=admin
      - MONGO_INITDB_DATABASE=card_system
    volumes:
      - ./init-db:/docker-entrypoint-initdb.d:ro # Onde colocaremos o script .js
    networks:
      - monitoring

  mongo-express:
    image: mongo-express:latest
    container_name: mongo-express
    ports:
      - "8082:8081"
    environment:
      - ME_CONFIG_BASICAUTH_USERNAME=admin
      - ME_CONFIG_BASICAUTH_PASSWORD=admin
      - ME_CONFIG_MONGODB_ADMINUSERNAME=admin
      - ME_CONFIG_MONGODB_ADMINPASSWORD=admin
      - ME_CONFIG_MONGODB_URL=mongodb://admin:admin@mongodb:27017/
    networks:
      - monitoring
    depends_on:
      - mongodb

  mysqldb:
    image: mysql:8.0
    container_name: mysqldb
    restart: always
    ports:
      - "3306:3306"
    environment:
      - MYSQL_ROOT_PASSWORD=admin
      - MYSQL_DATABASE=santander_system
      - MYSQL_USER=fabiano
      - MYSQL_PASSWORD=admin
    volumes:
      - ./mysql-init:/docker-entrypoint-initdb.d:ro # Scripts SQL de inicialização
    networks:
      - monitoring

  phpmyadmin:
    image: phpmyadmin/phpmyadmin:latest  # Nome exato da imagem no seu 'docker images'
    container_name: phpmyadmin
    restart: always
    ports:
      - "8083:80"
    environment:
      - PMA_HOST=mysqldb
      - MYSQL_ROOT_PASSWORD=admin
      - PMA_ARBITRARY=1
    networks:
      - monitoring
    depends_on:
      - mysqldb

  postgresdb:
    image: postgres:14-alpine
    container_name: postgresdb
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=santander_system
      - POSTGRES_USER=admin
      - POSTGRES_PASSWORD=admin
    volumes:
      - ./postgres-init:/docker-entrypoint-initdb.d:ro
    networks:
      - monitoring

  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: pgadmin
    restart: always
    ports:
      - "8084:80"
    environment:
      - PGADMIN_DEFAULT_EMAIL=admin@admin.com
      - PGADMIN_DEFAULT_PASSWORD=admin
      - PGADMIN_CONFIG_SERVER_MODE=False
    volumes:
      # Importa o servidor automaticamente
      - ./pgadmin-config/servers.json:/pgadmin4/servers.json:ro
      # Importa a senha para não pedir ao clicar no servidor
      - ./pgadmin-config/pgpassfile:/tmp/pgpassfile:ro
    networks:
      - monitoring
    depends_on:
      - postgresdb

networks:
  monitoring:
    driver: bridge # Docker cria a rede automaticamente se não existir
EOF

# --- TOOL SETUP MINIKUBE (Reconstrução do Cluster) ---
cat <<EOF > setup_all_minikube.sh
#!/bin/bash

echo "📦 Carregando imagem base do Minikube..."
#docker pull gcr.io/k8s-minikube/kicbase:v0.0.44
docker load -i kicbase_minikube.tar 

echo "📥 Instalando binário do Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube

echo "🚀 Iniciando Cluster com permissões de Root..."
minikube start --driver=docker --base-image="gcr.io/k8s-minikube/kicbase:v0.0.48" --force

cd /home/userlnx/docker/script_docker/card-system-api/
# 2. Gere o pacote JAR da aplicação
mvn clean package -DskipTests
# 3. Construa a imagem Docker localmente
docker build -t card-system-api:1.0 .

echo "🖼️ Injetando imagem da API no Cluster..."
minikube image load card-system-api:1.0

echo "☸️ Aplicando Manifestos Kubernetes..."
# Usando o kubectl embutido no minikube para evitar erro de 'command not found'
minikube kubectl -- apply -f k8s/deployment.yaml
minikube kubectl -- apply -f k8s/service.yaml
minikube kubectl -- apply -f k8s/hpa.yaml

echo "📊 Ativando Servidor de Métricas para AIOps/HPA..."
minikube addons enable metrics-server


echo "🚀 iniciando Servidor ..."
minikube service santander-card-api-service 
echo "✅ Externando acesso ao host ..."
minikube kubectl -- port-forward service/santander-card-api-service 8080:80 --address 0.0.0.0

echo "✅ Ambiente K8s pronto!"
echo "🌐 http://${PROJETO_CONF[INTERNAL_HOST]}:8080/api/v1/transactions"
echo "🌐 http://${PROJETO_CONF[INTERNAL_HOST]}:8080/swagger-ui/index.html"

minikube status
EOF

# --- TOOL SETUP MINIKUBE (Reconstrução do Cluster) ---

cat <<EOF > setup_k8s.sh
#!/bin/bash

# Define a raiz do projeto dinamicamente para evitar caminhos fixos "hardcoded"
BASE_DIR=\$(pwd)

echo "📦 Preparando infraestrutura do Minikube..."
# Se o arquivo tar estiver na raiz, o caminho funciona. 
# Se estiver em outro lugar, ajuste para o caminho correto.
if [ -f "kicbase_minikube.tar" ]; then
    docker load -i kicbase_minikube.tar
fi

echo "🚀 Iniciando Cluster Minikube..."
minikube start --driver=docker --base-image="gcr.io/k8s-minikube/kicbase:v0.0.48" --force

echo "🔨 Gerando pacote JAR com Maven..."
mvn clean package -DskipTests

echo "🐳 Construindo imagem Docker da API..."
docker build -t card-system-api:1.0 .

echo "🖼️ Injetando imagem no Minikube..."
minikube image load card-system-api:1.0

echo "☸️ Aplicando Manifestos do diretório k8s/..."
# Aqui está o segredo: apontamos para a pasta sem entrar nela
minikube kubectl -- apply -f \${BASE_DIR}/k8s/

echo "📊 Ativando Metrics Server..."
minikube addons enable metrics-server

echo "⏳ Aguardando os Pods ficarem prontos..."
minikube kubectl -- wait --for=condition=ready pod -l app=card-api --timeout=120s

echo "✅ Ambiente pronto! Iniciando Port-Forward..."
echo "Acesse em: http://${PROJETO_CONF[HOST_NAME]}:8080"

# O port-forward bloqueia o terminal. 
# Rodamos o comando service em background para não travar o script.
minikube service santander-card-api-service &

# Mantém o port-forward ativo no terminal principal
minikube kubectl -- port-forward service/santander-card-api-service 8080:80 --address 0.0.0.0
EOF

# 1. Cria o arquivo de variáveis na pasta correta ANTES do script
mkdir -p terraform
cat <<EOF > terraform/terraform.tfvars
project_id = "seu-id-do-gcp-aqui"
region     = "us-central1"
EOF

mkdir -p terraform
cat <<EOF > terraform/local.tf
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
EOF


# 2. Cria o script de setup
cat <<EOF > setup_terraform.sh
#!/bin/bash

# Garante que estamos na raiz do projeto para começar
BASE_DIR=\$(pwd)

echo "🛠️ Instalando Terraform e Dependências..."
apt-get update && apt-get install -y gnupg software-properties-common curl lsb-release

# Chave GPG e Repositório
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg --yes
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com \$(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

apt-get update && apt-get install terraform -y

echo "🚀 Validando instalação..."
terraform -version

# Entra na pasta terraform existente (onde estão seus arquivos .tf)
cd \${BASE_DIR}/terraform

echo "📥 Inicializando Providers em: \$(pwd)"
# Limpeza para evitar erros de cache/deadline
rm -rf .terraform/ .terraform.lock.hcl

MAX_RETRIES=3
COUNT=0
SUCCESS=false

until [ \$COUNT -ge \$MAX_RETRIES ]; do
    if terraform init; then
        echo "✅ Terraform inicializado com sucesso!"
        SUCCESS=true
        break
    else
        COUNT=\$((COUNT+1))
        echo "⚠️ Falha na conexão (Tentativa \$COUNT/\$MAX_RETRIES). Tentando novamente em 10s..."
        sleep 10
    fi
done

if [ "\$SUCCESS" = false ]; then
    echo "❌ Erro crítico: Falha ao baixar providers."
    exit 1
fi

echo "🛡️ Dica: Agora execute 'gcloud auth application-default login'"
EOF
chmod +x setup_terraform.sh

cat <<EOF > deploy_infra.sh
#!/bin/bash
cd terraform/
echo "🔍 Verificando plano de infraestrutura..."
terraform plan -out=tfplan
echo "🚀 Aplicando mudanças no GCP..."
terraform apply tfplan
EOF
chmod +x deploy_infra.sh

# Dá permissão de execução
chmod +x setup_all_minikube.sh

chmod +x setup_k8s.sh

# --- TOOL SCRIPT DE LIMPEZA ---
cat <<EOF > clear_all_service.sh
#!/bin/bash
# Captura o parâmetro mesmo se usar 'source' ou execução direta
PARAM="\$1"
echo "♻️ Resetando ambiente de desenvolvimento..."
# 1. Derruba o que estiver rodando pelo Compose
if [ -f "docker-compose.yml" ]; then
    docker-compose down --remove-orphans || true
fi
# 2. Limpeza de imagens órfãs
echo "🧹 Limpando imagens órfãs (<none>)..."
docker image prune -f
# 3. Lógica para o parâmetro --all
if [[ "\$PARAM" == "--all" ]]; then
    echo "🚨 REMOÇÃO TOTAL: Buscando imagens 'card-system'..."    
    # Lista imagens que contém 'card-system' (API e Frontends)
    IMAGES=\$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "card-system")    
    if [ ! -z "\$IMAGES" ]; then
        echo "🗑️ Removendo: \$IMAGES"
        docker rmi -f \$IMAGES
    else
        echo "ℹ️ Nenhuma imagem do projeto encontrada."
    fi
fi
echo "✅ Ambiente limpo."
#docker stop santander-api prometheus grafana || true
#docker rm santander-api prometheus grafana || true
#docker-compose -f monitoring/docker-compose.yml down || true
#mvn clean
#docker system prune -a --volumes -f
#docker stop \$(docker ps -q)
EOF
chmod +x clear_all_service.sh

echo "✅ IaaS configurada com sucesso!"