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

# --- DOCUMENTAÇÃO TÉCNICA (README) ---
cat <<EOF > README.md
<!-- 
  Tags: DevOps,Iac
  Label: 💳 Card System Platform - Santander/F1RST Evolution
  Description:⭐ Microserviço focado no processamento de transações de cartões
  technical_requirement: Java 11, Spring Boot 2.7, Spring Data JPA, Hibernate, MySQL, Docker, Maven, JUnit 5, Hexagonal Architecture, SOLID, Clean Architecture, REST API, Global Exception Handling, Bean Validation, Bash Scripting, Linux (Debian), Git, GitFlow, Amazon Corretto, Multi-stage builds, CI/CD, GitHub Actions, SRE, Troubleshooting, Cloud Computing.
  path_hook: hookfigma.hook18,hookfigma.hook20
-->
# 💳 Card System Platform - Santander/F1RST Evolution

![Fluxo do Sistema](images/fluxo.png)

Este projeto é um Microserviço focado no processamento de transações de cartões, desenvolvido como parte do processo seletivo para a posição de **Analista de Sistemas III**.

## 📖 Storytelling: A Jornada da Resiliência
Imagine uma **Black Friday** no ecossistema **Santander**. Milhares de transações por segundo cruzam a rede. Neste cenário, uma falha não é apenas um erro de log; é um cliente impossibilitado de comprar. 

Este projeto nasceu para transcender o desenvolvimento tradicional. Não entregamos apenas código; entregamos **Disponibilidade**. Através da **Arquitetura Hexagonal**, isolamos o core bancário de instabilidades externas. Com o **HPA (Horizontal Pod Autoscaler)**, nossa infraestrutura "respira" conforme a demanda, e através de um **Agente AIOps em Python**, detectamos anomalias antes que elas afetem o cliente final. É a engenharia de software aliada à inteligência operacional para garantir um sistema que nunca dorme.

---

## 🌟 Specialist Evolution (Vaga Atual: Especialista AIOps)
Diferente da versão inicial de Analista III, esta branch introduz conceitos avançados de **SRE** e **AIOps**, elevando a maturidade do microserviço:

- **Observabilidade Full-Stack**: Implementação de métricas customizadas via **Micrometer** e exposição de telemetria via **Spring Actuator**.
- **Python AIOps Agent**: Script lateral (\`/scripts\`) que consome dados de saúde da API para automação de incidentes.
- **FinOps Ready**: Configuração de limites de recursos (CPU/MEM) no CI/CD para otimização de custos no GCP Cloud Run.
- **Resiliência Nativa**: Implementação de *Liveness* e *Readiness Probes* para garantir o Self-healing do container.
 
## 🚀 Tecnologias e Frameworks
- **Java 11**: Linguagem base para conformidade com o ecossistema atual.
- **Spring Boot 2.7**: Framework para agilidade no desenvolvimento de microserviços.
- **Arquitetura Hexagonal (Ports and Adapters)**: Para garantir desacoplamento total da regra de negócio.
- **JUnit 5**: Para testes unitários de regras críticas.
- **Docker**: Containerização com imagem **Amazon Corretto 11** para ambiente Cloud-Ready.
- **Maven**: Gerenciamento de dependências e build.
- **Cloud Friendly**: Containerização otimizada com Amazon Corretto para deploy imediato em ambientes AWS, Azure ou Kubernetes.
- **OpenAPI/Swagger**: Documentação interativa integrada para facilitar o consumo por times de Frontend e Integração.
- **GitHub Actions**: Esteira de CI/CD totalmente automatizada.
- **Google Cloud Platform (GCP)**: Infraestrutura de hospedagem via Cloud Run (Serverless). 

## 🏗️ Arquitetura
O projeto utiliza **Arquitetura Hexagonal** para isolar o domínio das tecnologias externas (bancos de dados, frameworks, APIs externas). 



- **Domain**: Entidades e regras de negócio puras.
- **Application**: Casos de uso e portas de entrada/saída.
- **Adapters (In/Out)**: Implementações técnicas (REST Controllers, Persistence, etc.).

## 🛠️ Como Executar o Projeto

### Pré-requisitos
- Docker instalado.
- Maven 3.8+ (opcional se usar Docker).

### preparação: Maven
\`\`\`bash
apt-get update && apt-get install maven -y
apt-get update && apt-get install docker.io -y
systemctl start docker
systemctl enable docker
usermod -aG docker \$USER
\`\`\`

### Passo 1: Build da aplicação
\`\`\`bash
mvn clean package -DskipTests
\`\`\`

### Passo 2: Build da Imagem Docker
\`\`\`bash
docker build -t card-system-api:1.0 .
\`\`\`

### Passo 3: Execução do Container
\`\`\`bash
docker run -d -p 8080:8080 --name santander-api card-system-api:1.0
\`\`\`

## 🧪 Validando a API (Exemplos de Endpoints)

**Aprovação de Transação (Valor < 10.000):**
\`\`\`bash
curl -X POST http://${PROJETO_CONF[HOST_NAME]}:8080/api/v1/transactions \
-H "Content-Type: application/json" \
-d '{"cardNumber": "1234-5678", "amount": 500.00}'
\`\`\`

**Rejeição de Transação (Valor > 10.000):**
\`\`\`bash
curl -X POST http://${PROJETO_CONF[HOST_NAME]}:8080/api/v1/transactions \
-H "Content-Type: application/json" \
-d '{"cardNumber": "1234-5678", "amount": 15000.00}'
\`\`\`
### 🤖 Validando a Camada de AIOps
Após subir o container, você pode validar a telemetria que alimenta nossa IA:

**1. Ver métricas brutas (Prometheus format):**
\`\`\`bash
curl http://${PROJETO_CONF[HOST_NAME]}:8080/actuator/prometheus
\`\`\`

# O agente analisa o status e transações em tempo real
\`\`\`bash
python3 scripts/aiops_health_agent.py
\`\`\`

## 🛡️ Diferenciais Implementados
- **Global Exception Handler**: Padronização de erros JSON para conformidade com gateways de API.
- **Troubleshooting Ready**: Logs estruturados para facilitar a análise em ambientes produtivos.
- **Cloud Friendly**: Configuração preparada para ambientes AWS/Azure via Docker.

---

## 🏗️ Arquitetura e CI/CD
O projeto segue os princípios de **Clean Architecture** e utiliza uma esteira automatizada para deploy. 



### Pipeline de Entrega Continua:
1. **Build**: Compilação via Maven no GitHub Runner.
2. **Containerize**: Criação da imagem Docker e push para o **GCP Artifact Registry**.
3. **Deploy**: Atualização automática do serviço no **GCP Cloud Run**.

---

## ☁️ Implantação no Google Cloud (GCP)

Para replicar o ambiente de produção, siga os passos abaixo utilizando o \`gcloud CLI\`:

### ⚙ 1. Configuração de Acesso (Service Account)
\`\`\`bash
# 1. Definir a variável corretamente (sem espaços)
export PROJECT_ID="santander-repo"

# 2. Ativar a API do Artifact Registry (isso só funcionará após o Billing ser vinculado)
gcloud services enable artifactregistry.googleapis.com --project=\$PROJECT_ID
gcloud services enable run.googleapis.com --project=santander-repo

# 3. Criar a Service Account (se der erro de 'already exists', pode ignorar)
gcloud iam service-accounts create github-deploy-sa || echo "Conta já existe"

# 4. Atribuir permissões usando a variável \$PROJECT_ID
gcloud projects add-iam-policy-binding \$PROJECT_ID \
    --member="serviceAccount:github-deploy-sa@\$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/run.admin"

gcloud projects add-iam-policy-binding \$PROJECT_ID \
    --member="serviceAccount:github-deploy-sa@\$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding \$PROJECT_ID \
    --member="serviceAccount:github-deploy-sa@\$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"

# 5. Gerar a chave JSON
gcloud iam service-accounts keys create gcp-key.json \
    --iam-account=github-deploy-sa@\$PROJECT_ID.iam.gserviceaccount.com

# Garante que você está no projeto correto
gcloud config set project \$PROJECT_ID

# Habilita a API do Artifact Registry
gcloud services enable artifactregistry.googleapis.com

gcloud artifacts repositories create \$PROJECT_ID \
    --repository-format=docker \
    --location=us-central1 \
    --description="Repositorio Docker para o Santander F1RST"

gcloud projects add-iam-policy-binding \$PROJECT_ID \
    --member="serviceAccount:github-deploy-sa@\$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.writer"if [[ condition ]]; then
      #statements
    fi    

cat gcp-key.json    
gcloud config get-value project
\`\`\`
### ⚙ 2. Configuração de Secrets no GitHub

Copie todo o texto que aparecer (começa com { e termina com }).
Não cole essa chave diretamente no seu código! 
Ela deve ser guardada nos Secrets do seu repositório para ficar protegida:

Acesse o seu repositório no GitHub.

Vá na aba Settings (Configurações).

No menu lateral esquerdo, clique em Secrets and variables > Actions.

- **Clique em secret  and variables.**

**Aba: Secrets (Botão "New repository secret")**
\`\`\`bash
Name: GCP_SA_KEY
Value: (Cole todo o conteúdo do arquivo gcp-key.json)
\`\`\`

**Aba: Variables (Botão "New repository variable")**
\`\`\`bash
Name: GCP_PROJECT_ID
Value: santander-repo
\`\`\`

\`\`\`bash
    GCP_PROJECT_ID: "O ID do seu projeto no Google Cloud."
    GCP_SA_KEY: "O conteúdo completo do arquivo gcp-key.json gerado no passo anterior.""
\`\`\`

### 🚀 3. Testando a implantação da aplicação

Para visualizar a aplicação em execução, acesse o Cloud Run no console do Google Cloud e localize o serviço santander-repo.

A documentação interativa das APIs (Swagger) está disponível no endpoint final da URL gerada.

Exemplo de link para acesso: 🔗 https://8080xxxxxxxxxxxxxxxxxxx.run.app/swagger

## 📊 Guia de Configuração do Dashboard de Observabilidade

Siga os passos abaixo para conectar os dados da API ao Grafana e visualizar a saúde do sistema.

### 1. Acesso ao Grafana
* **URL:** \`http://vmlinuxd:3000\`
* **Credenciais:** Usuário \`admin\` | Senha \`admin\`

### 2. Configurar Fonte de Dados (Prometheus)
O Grafana precisa "ler" o banco de dados do Prometheus:
1. No menu lateral, clique em **Connections** > **Data Sources**.
2. Clique em **Add data source** e selecione **Prometheus**.
3. No campo **URL**, digite: \`http://prometheus:9090\`
4. Role até o fim e clique em **Save & Test**. (Deve aparecer uma confirmação verde).

### 3. Criar Painel de Transações (Business Metrics)
Para ver o volume de Aprovações vs. Rejeições:
1. No menu lateral, clique em **Dashboards** > **New** > **Add Visualization**.
2. Selecione o Data Source **Prometheus**.
3. No campo de busca **Query**, insira:
   \`\`\`promql
   sum(transactions_total) by (status)
   \`\`\`
4. No canto direito, em Panel options, altere o título para \`Status de Transações (Tempo Real)\`.
5. Em Library panels > Suggestions, escolha o formato Bar Gauge ou Pie Chart.
6. Clique em Apply no topo superior direito.

### 4. Importar Dashboard Completo de SRE (JVM)
Para monitorar CPU, Memória Heap e Threads automaticamente:
1. No menu lateral, clique em Dashboards > New > Import.
2. No campo Import via grafana.com, digite o ID: 4701 (é o ID oficial de um template na galeria pública do Grafana.com) e clique em Load.   
3. Na próxima tela, selecione o Data Source Prometheus no seletor de baixo.
4. Clique em Import.

### 🛠️ Gerar Massa de Dados para Teste
Caso o gráfico esteja vazio, execute o comando abaixo no terminal para simular 50 transações e popular os gráficos instantaneamente:

\`\`\`promql

for i in {1..50}; do 
  curl -s -X POST http://vmlinuxd:8080/api/v1/transactions \
  -H "Content-Type: application/json" \
  -d "{\"cardNumber\": \"1234\", \"amount\": \$((RANDOM % 15000))}" > /dev/null
  sleep 0.5
done
\`\`\`

### 📊 Observabilidade Automática (IaC)
O ambiente já está pré-configurado com **Dashboards as Code**.
1. Acesse \`http://vmlinuxd:3000\` (admin/admin).
2. Vá em **Dashboards** e abra o item **"Santander Card System - Overview"**.
3. Os dados das transações aparecerão automaticamente conforme o uso da API.

### 📊 Dashboards Disponíveis (Auto-Provisioned)
Ao acessar o Grafana, você encontrará dois ambientes prontos:
1. **Santander Card System - Overview**: Dashboard de negócio (Aprovações vs Rejeições) com limites de alerta AIOps.
2. **JVM Micrometer**: Dashboard técnico (Health-check profundo) com métricas de Memória Heap, CPU, Threads e Garbage Collector. 

### 🚀 terraform
No seu terminal, dentro da pasta terraform:
Inicializar: terraform init
Validar: terraform plan -var="project_id=santander-repo"
Provisionar: terraform apply -var="project_id=santander-repo"

### 🛠️ Metodologia e Uso de IA
Este projeto foi desenvolvido utilizando uma abordagem de Engenharia Aumentada por IA.

"Embora tenha utilizado ferramentas de Inteligência Artificial para acelerar a implementação de determinados módulos e scripts, detenho o domínio da Arquitetura de Referência e dos conceitos fundamentais de SRE/AIOps. Isso me permite manter o controle técnico total da solução, realizar 'deep dives' em qualquer componente conforme a necessidade e garantir que a automação sirva aos objetivos de negócio de forma produtiva e segura."
EOF
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

  santander-api:
    image: card-system-api:1.0
    container_name: santander-api
    ports:
      - "8080:8080"
    networks:
      - monitoring

  prometheus:
    image: prom/prometheus
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
    image: grafana/grafana
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
echo "Acesse em: http://localhost:8080"

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
echo "♻️ Resetando ambiente de desenvolvimento..."
docker stop santander-api prometheus grafana || true
docker rm santander-api prometheus grafana || true
docker-compose -f monitoring/docker-compose.yml down || true
mvn clean
#docker system prune -a --volumes -f
#docker stop \$(docker ps -q)
echo "✅ Ambiente limpo."
EOF
chmod +x clear_all_service.sh

echo "✅ IaaS configurada com sucesso!"