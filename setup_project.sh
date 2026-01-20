#!/bin/bash

# Nome do projeto
PROJECT_NAME="card-system-api"
PACKAGE_PATH="src/main/java/com/fabiano/cardsystem"
HOST_NAME="vmlinuxd"
INTERNAL_HOST="host.docker.internal"
INTERNAL_HOST="santander-api"
URL_FIREBASE="3000-firebase-my-java-app-1756832118227.cluster-f73ibkkuije66wssuontdtbx6q.cloudworkstations.dev"
URL_FIREBASE=$HOST_NAME
#HOST_NAME="localhost"
EMAIL="fabiuniz@msn.com"
NOME="Fabiano"

# 1. Garante que estamos na raiz do projeto (sem duplicar)
CURRENT_DIR_NAME=$(basename "$PWD")

if [ "$CURRENT_DIR_NAME" == "$PROJECT_NAME" ]; then
    echo "📍 Você já está na pasta '$PROJECT_NAME'. Criando estrutura aqui..."
else
    echo "📂 Criando pasta '$PROJECT_NAME' e entrando nela..."
    mkdir -p "$PROJECT_NAME"
    cd "$PROJECT_NAME" || exit
fi

echo "🚀 Iniciando criação do projeto $PROJECT_NAME..."

# 1. Criar estrutura de pastas (REMOVIDO o $PROJECT_NAME do caminho inicial)
mkdir -p "$PACKAGE_PATH"/{domain/model,application/service,application/ports/out,adapter/in/web,adapter/out/db}
mkdir -p scripts
mkdir -p src/main/resources
mkdir -p "$PACKAGE_PATH"/{application/service,domain/model,adapter/in/web}
mkdir -p monitoring/prometheus
mkdir -p monitoring/grafana/provisioning/datasources
mkdir -p monitoring/grafana/provisioning/dashboards
mkdir -p monitoring/nginx
mkdir -p .idx k8s terraform
mkdir -p .github/workflows
# Corrige permissões de escrita para os volumes do Grafana/Prometheus no ambiente Cloud
chmod -R 777 monitoring/grafana
chmod -R 777 monitoring/prometheus
chmod +x setup_iaas.sh

. setup_iaas.sh

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

cat <<EOF > monitoring/nginx/nginx.conf
events {}
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    server {
        listen 80;
        server_name $HOST_NAME;

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

cat <<EOF > monitoring/prometheus/prometheus.yml
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: 'card-system-api'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['$INTERNAL_HOST:8080'] # Se rodar API no host e Prom no Docker
EOF

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

cat <<EOF > monitoring/grafana/provisioning/dashboards/santander_transactions.json
{
  "annotations": { "list": [ { "builtIn": 1, "datasource": { "type": "grafana", "uid": "-- Grafana --" }, "enable": true, "hide": true, "name": "Annotations & Alerts", "type": "dashboard" } ] },
  "editable": true, "fiscalYearStartMonth": 0, "graphTooltip": 0, "id": null, "links": [], "liveNow": false,
  "panels": [
    {
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "fieldConfig": {
        "defaults": {
          "color": { "mode": "thresholds" },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [ { "color": "green", "value": null }, { "color": "red", "value": 10 } ]
          }
        },
        "overrides": []
      },
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 0 },
      "id": 1,
      "options": { "orientation": "auto", "reduceOptions": { "calcs": ["lastNotNull"], "fields": "", "values": false }, "showThresholdLabels": false, "showThresholdMarkers": true },
      "pluginVersion": "9.3.6",
      "targets": [
        { "datasource": { "type": "prometheus", "uid": "prometheus" }, "editorMode": "code", "expr": "sum(transactions_total) by (status)", "legendFormat": "{{status}}", "range": true, "refId": "A" }
      ],
      "title": "Monitoramento de Transações AIOps",
      "type": "bargauge"
    }
  ],
  "schemaVersion": 37, "style": "dark", "tags": ["santander", "aiops"], "templating": { "list": [] }, "time": { "from": "now-1m", "to": "now" }, "timepicker": {}, "timezone": "", "title": "Santander Card System - Overview", "version": 1
}
EOF

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
curl -X POST http://$HOST_NAME:8080/api/v1/transactions \
-H "Content-Type: application/json" \
-d '{"cardNumber": "1234-5678", "amount": 500.00}'
\`\`\`

**Rejeição de Transação (Valor > 10.000):**
\`\`\`bash
curl -X POST http://$HOST_NAME:8080/api/v1/transactions \
-H "Content-Type: application/json" \
-d '{"cardNumber": "1234-5678", "amount": 15000.00}'
\`\`\`
### 🤖 Validando a Camada de AIOps
Após subir o container, você pode validar a telemetria que alimenta nossa IA:

**1. Ver métricas brutas (Prometheus format):**
\`\`\`bash
curl http://$HOST_NAME:8080/actuator/prometheus
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

cd $PROJECT_NAME

# --- CONFIGURAÇÃO ACTUATOR (application.yml) ---
cat <<EOF > src/main/resources/application.yml
spring:
  application:
    name: card-system-platform
management:
  endpoints:
    web:
      exposure:
        include: "health,metrics,prometheus"
      cors:
        allowed-origins: "*"
        allowed-methods: "*"
        allowed-headers: "*"
  endpoint:
    health:
      show-details: always
EOF

mkdir -p $PACKAGE_PATH/infrastructure/security
cat <<EOF > $PACKAGE_PATH/infrastructure/security/SecurityConfig.java
package com.fabiano.cardsystem.infrastructure.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import java.util.List;
@Configuration
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.csrf().disable()
            .cors().configurationSource(request -> {
                CorsConfiguration config = new CorsConfiguration();
                config.setAllowedOrigins(List.of("*"));
                config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
                config.setAllowedHeaders(List.of("*"));
                return config;
            })
            .and()
            .authorizeRequests()
            .antMatchers("/**").permitAll();
        return http.build();
    }
}
EOF
# --- TRANSACTION METRICS (Coração do AIOps) ---
cat <<EOF > $PACKAGE_PATH/application/service/TransactionMetrics.java
package com.fabiano.cardsystem.application.service;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Service;

@Service
public class TransactionMetrics {
    private final Counter approved;
    private final Counter rejected;
    public TransactionMetrics(MeterRegistry registry) {
        this.approved = Counter.builder("transactions_total").tag("status", "approved").register(registry);
        this.rejected = Counter.builder("transactions_total").tag("status", "rejected").register(registry);
    }
    public void incrementApproved() { approved.increment(); }
    public void incrementRejected() { rejected.increment(); }
}
EOF

# --- TRANSACTION CONTROLLER (Com Logs e Métricas) ---
cat <<EOF > $PACKAGE_PATH/adapter/in/web/TransactionController.java
package com.fabiano.cardsystem.adapter.in.web;
import com.fabiano.cardsystem.domain.model.Transaction;
import com.fabiano.cardsystem.application.service.TransactionMetrics;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import java.util.Map;
import java.util.UUID;
@RestController
@CrossOrigin(origins = "*", allowedHeaders = "*")
@RequestMapping("/api/v1/transactions")
public class TransactionController {
    private final TransactionMetrics metrics;
    // O Spring injeta automaticamente as métricas aqui
    public TransactionController(TransactionMetrics metrics) {
        this.metrics = metrics;
    }
    @Operation(summary = "Processa transação", description = "Valida limite de segurança de R$ 10.000")
    @ApiResponse(responseCode = "200", description = "Aprovada")
    @ApiResponse(responseCode = "422", description = "Negada por limite")
    @PostMapping
    public ResponseEntity<?> process(@RequestBody Transaction transaction) {
        if (transaction.getAmount() == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Amount is required"));
        }
        double amount = transaction.getAmount().doubleValue();
        
        if (amount > 10000) {
            // AQUI É ONDE O AIOPS GANHA VIDA
            metrics.incrementRejected(); 
            return ResponseEntity.status(422).body(Map.of(
                "status", "REJECTED",
                "reason", "Limit exceeded",
                "transactionId", UUID.randomUUID().toString()
            ));
        }
        metrics.incrementApproved();
        return ResponseEntity.ok(Map.of(
            "status", "APPROVED",
            "transactionId", UUID.randomUUID().toString()
        ));
    }
}
EOF

# --- AGENTE PYTHON (AIOps Agent) ---
cat <<EOF > scripts/aiops_health_agent.py
import requests

def analyze_health():
    url = "http://$HOST_NAME:8080/actuator/prometheus"
    try:
        response = requests.get(url)
        lines = response.text.split('\n')
        
        approved = 0
        rejected = 0
        
        for line in lines:
            if 'transactions_total{status="approved",}' in line:
                approved = float(line.split()[-1])
            if 'transactions_total{status="rejected",}' in line:
                rejected = float(line.split()[-1])
        
        total = approved + rejected
        rejection_rate = (rejected / total * 100) if total > 0 else 0
        
        print(f"📊 --- AIOps Health Report ---")
        print(f"✅ Approved: {approved} | ❌ Rejected: {rejected}")
        print(f"📈 Rejection Rate: {rejection_rate:.2f}%")
        
        if rejection_rate > 40:
            print("🚨 ALERT: High rejection rate detected! Check fraud system.")
        else:
            print("🟢 System Status: HEALTHY")
            
    except Exception as e:
        print(f"🚨 Error connecting to API: {e}")

if __name__ == "__main__":
    analyze_health()
EOF

chmod +x scripts/aiops_health_agent.py
# --- VALIDAÇÃO DE FERRAMENTAS (MAVEN & DOCKER) ---
echo "🔍 Validando pré-requisitos do ambiente..."

# Validação do Maven
if ! command -v mvn &> /dev/null; then
    echo "⚠️ MAVEN: Não encontrado. Instalando..."
    apt-get update && apt-get install maven -y
else
    echo "✅ MAVEN: Detectado ($(mvn -version | head -n 1))"
fi

# Validação do Docker
if ! command -v docker &> /dev/null; then
    echo "⚠️ DOCKER: Não encontrado. Instalando..."
    apt-get update && apt-get install docker.io -y
    systemctl start docker
    systemctl enable docker
    usermod -aG docker $USER
    echo "🚀 Docker instalado. Nota: Pode ser necessário relogar para aplicar permissões de grupo."
else
    # Verifica se o daemon do Docker está rodando
    if ! docker ps &> /dev/null; then
        echo "🚨 DOCKER: Comando existe, mas o serviço está parado ou sem permissão (."
        systemctl start docker
    else
        echo "✅ DOCKER: Detectado e operacional."
    fi
fi
echo "✅ Adaptação do sistema com Monitoramento Inteligente. concluída!"

#
cat <<EOF > src/main/java/com/fabiano/cardsystem/CardSystemApplication.java
package com.fabiano.cardsystem;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;

@SpringBootApplication(exclude = {DataSourceAutoConfiguration.class })
public class CardSystemApplication {
    public static void main(String[] args) {
        SpringApplication.run(CardSystemApplication.class, args);
    }
}
EOF

# 2. Criar o arquivo pom.xml (Minimalista com Spring Boot 2.7.x / Java 11)
cat <<EOF > pom.xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.fabiano</groupId>
  <artifactId>card-system-api</artifactId>
  <version>1.0.0</version>
  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>2.7.18</version>
  </parent>
  <properties>
    <java.version>11</java.version>
  </properties>
  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
      <groupId>com.mysql</groupId>
      <artifactId>mysql-connector-j</artifactId>
      <scope>runtime</scope>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-test</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>com.h2database</groupId>
      <artifactId>h2</artifactId>
      <scope>runtime</scope>
    </dependency>
    <dependency>
      <groupId>org.springdoc</groupId>
      <artifactId>springdoc-openapi-ui</artifactId>
      <version>1.6.14</version>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>
    <dependency>
      <groupId>io.micrometer</groupId>
      <artifactId>micrometer-registry-prometheus</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-security</artifactId>
    </dependency>
  </dependencies>
  <build>
    <plugins>
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
      </plugin>
    </plugins>
  </build>
</project>
EOF

# 3. Criar a Classe de Domínio (Pure Java)
cat <<EOF > $PACKAGE_PATH/domain/model/Transaction.java
package com.fabiano.cardsystem.domain.model;

import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;

public class Transaction {
    @Schema(example = "1234-5678-9012-3456")
    private String cardNumber;
    
    @Schema(example = "500.00")
    private BigDecimal amount;
    
    private Long id;
    private String status;

    public Transaction() {}
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public BigDecimal getAmount() { return amount; }
    public String getCardNumber() { return cardNumber; }
}
EOF

# 4. Criar a Main Class do Spring Boot
cat <<EOF > src/main/java/com/fabiano/cardsystem/CardSystemApplication.java
package com.fabiano.cardsystem;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;

@SpringBootApplication(exclude = {DataSourceAutoConfiguration.class })
public class CardSystemApplication {
    public static void main(String[] args) {
        SpringApplication.run(CardSystemApplication.class, args);
    }
}
EOF

# Cria todas as pastas de uma vez
mkdir -p src/main/java/com/fabiano/cardsystem/adapters/in/web/exception

# Agora cria o arquivo dentro delas
cat <<EOF > src/main/java/com/fabiano/cardsystem/adapters/in/web/exception/GlobalExceptionHandler.java
package com.fabiano.cardsystem.adapters.in.web.exception;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import java.util.Map;
import java.time.LocalDateTime;

@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(Exception.class)
    public ResponseEntity<?> handleAllExceptions(Exception ex) {
        return ResponseEntity.status(500).body(Map.of(
            "timestamp", LocalDateTime.now(),
            "message", "Erro interno no processamento da transação",
            "details", ex.getMessage()
        ));
    }
}
EOF
mkdir -p src/test/java/com/fabiano/cardsystem/domain/model
cat <<EOF > src/test/java/com/fabiano/cardsystem/domain/model/TransactionTest.java
package com.fabiano.cardsystem.domain.model;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class TransactionTest {
    @Test
    void testTransactionCreation() {
        Transaction t = new Transaction();
        assertNotNull(t);
    }
}
EOF

mkdir -p src/main/java/com/fabiano/cardsystem/adapter/in/web
cat <<EOF > src/main/java/com/fabiano/cardsystem/adapter/in/web/TransactionController.java
package com.fabiano.cardsystem.adapter.in.web;
import com.fabiano.cardsystem.domain.model.Transaction;
import com.fabiano.cardsystem.application.service.TransactionMetrics;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import java.util.Map;
import java.util.UUID;
@RestController
@RequestMapping("/api/v1/transactions")
public class TransactionController {
    private final TransactionMetrics metrics;
    public TransactionController(TransactionMetrics metrics) {
        this.metrics = metrics;
    }
    @PostMapping
    public ResponseEntity<?> process(@RequestBody Transaction transaction) {
        if (transaction.getAmount() == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Amount is required"));
        }
        if (transaction.getAmount().doubleValue() > 10000) {
            metrics.incrementRejected();
            return ResponseEntity.status(422).body(Map.of(
                "status", "REJECTED",
                "transactionId", UUID.randomUUID().toString()
            ));
        }
        metrics.incrementApproved();
        return ResponseEntity.ok(Map.of(
            "status", "APPROVED",
            "transactionId", UUID.randomUUID().toString()
        ));
    }
}
EOF

# 5. Inicializar Git e Primeiro Commit
#echo "📦 Inicializando repositório Git..."
#git init
cat <<EOF > .gitignore
target/
.mvn/
.idea/
*.class
.DS_Store
EOF

#git add .
#git commit -m "feat: initial structure with hexagonal architecture, java 11 and docker"

echo "✅ Projeto '$PROJECT_NAME' criado com sucesso e commit realizado!"
echo "👉 Para rodar: cd $PROJECT_NAME && ./mvnw spring-boot:run (se tiver o maven wrapper)"


#curl -s "https://get.sdkman.io" | bash
#source "$HOME/.sdkman/bin/sdkman-init.sh"
#sdk list java | grep "11."
#sdk install java 11.0.29-tem
#sdk default java 11.0.29-tem
#java -version
#
#openjdk version "11.0.29" 2025-10-21
#OpenJDK Runtime Environment Temurin-11.0.29+7 (build 11.0.29+7)
#OpenJDK 64-Bit Server VM Temurin-11.0.29+7 (build 11.0.29+7, mixed mode)

#sdk install maven
#mvn -version

cd card-system-api
mvn clean compile
mvn clean package -DskipTests
docker build -t card-system-api:1.0 .
#docker run --rm card-system-api:1.0 java -version

# --- INICIALIZAÇÃO DO STACK DE MONITORAMENTO ---
echo "🧹 Limpando containers antigos para evitar conflitos..."
# Remove containers manuais (caso existam)
docker stop santander-api prometheus grafana || true
docker rm santander-api prometheus grafana || true

# Remove a stack do docker-compose completamente (containers, redes e órfãos)
docker-compose down --remove-orphans || true

echo "🚀 Iniciando Stack Completa..."
docker-compose up -d

echo "⏳ Aguardando a API subir (Health Check)..."
# Loop de espera inteligente
for i in {1..30}; do
    if curl -s http://$HOST_NAME:8080/actuator/health | grep -q "UP"; then
        echo "✅ API está Online!"
        break
    fi
    echo -n "."
    sleep 2
done

# Simula tráfego inicial para o Agente Python ter dados
echo "📈 Gerando tráfego de teste..."
curl -s -X POST http://$HOST_NAME:8080/api/v1/transactions -H "Content-Type: application/json" -d '{"cardNumber": "123", "amount": 500}' > /dev/null
curl -s -X POST http://$HOST_NAME:8080/api/v1/transactions -H "Content-Type: application/json" -d '{"cardNumber": "123", "amount": 15000}' > /dev/null

# Executa o Agente AIOps
./venv/bin/python3 scripts/aiops_health_agent.py

echo "✅ Testes de metricas realizado!"

echo "--------------------------"
# Define a cor azul sublinhado
BLUE_UNDERLINE='\e[4;34m'
RED_UNDERLINE='\e[4;31m'
NC='\e[0m' # No Color (reseta a cor)
echo -e "\n--- LINKS DA APLICAÇÃO Clique no link (Segure CTRL + Clique): ---"
echo -e "API Base:   ${BLUE_UNDERLINE}http://$HOST_NAME:8080/api/v1/transactions${NC}"
echo -e "Swagger UI: ${BLUE_UNDERLINE}http://$HOST_NAME:8080/swagger-ui/index.html${NC}"
echo -e "Prometheus: ${BLUE_UNDERLINE}http://$HOST_NAME:9090/targets${NC}"
echo -e "Grafana: ${BLUE_UNDERLINE}http://$HOST_NAME:3000 (Login: admin / Senha: admin${NC}"
echo -e "Actuator: ${RED_UNDERLINE}curl http://$HOST_NAME:8080/actuator/prometheus${NC}"
echo -e "Python: ${RED_UNDERLINE}python3 scripts/aiops_health_agent.py${NC}"
echo "--------------------------"