#!/bin/bash

# Criando o "Objeto" de configuração (Array Associativo)
unset PROJETO_CONF
declare -A PROJETO_CONF

# 1. Declara o Array Associativo
declare -A PROJETO_CONF

# 2. Inicializa com os valores estáticos
PROJETO_CONF=(
  [PROJECT_NAME]="card-system-api"
  [PACKAGE_PATH]="src/main/java/com/fabiano/cardsystem"
  [HOST_NAME]='vmlinuxd'
  [INTERNAL_HOST]="santander-api"
  [EMAIL]="fabiuniz@msn.com"
  [NOME]="Fabiano"
)

# 3. Faz a atribuição dinâmica (Sincroniza URL com o Host)
PROJETO_CONF[HOST_NAME]='localhost'
PROJETO_CONF[URL_FIREBASE]=${PROJETO_CONF[HOST_NAME]}
PROJETO_CONF[URL_FIREBASE]="3000-firebase-my-java-app-1756832118227.cluster-f73ibkkuije66wssuontdtbx6q.cloudworkstations.dev"

# --- Validação ---
echo "🚀 Configuração carregada para: ${PROJETO_CONF[NOME]}"
echo "📍 Host: ${PROJETO_CONF[HOST_NAME]}"
echo "🔗 URL:  ${PROJETO_CONF[URL_FIREBASE]}"

# 1. Garante que estamos na raiz do projeto (sem duplicar)
CURRENT_DIR_NAME=$(basename "$PWD")

if [ "$CURRENT_DIR_NAME" == "${PROJETO_CONF[PROJECT_NAME]}" ]; then
    echo "📍 Você já está na pasta '${PROJETO_CONF[PROJECT_NAME]}'. Criando estrutura aqui..."
else
    echo "📂 Criando pasta '${PROJETO_CONF[PROJECT_NAME]}' e entrando nela..."
    mkdir -p "${PROJETO_CONF[PROJECT_NAME]}"
    cd "${PROJETO_CONF[PROJECT_NAME]}" || exit
fi

echo "🚀 Iniciando criação do projeto ${PROJETO_CONF[PROJECT_NAME]}..."

# 1. Criar estrutura de pastas (REMOVIDO o ${PROJETO_CONF[PROJECT_NAME]} do caminho inicial)
mkdir -p "${PROJETO_CONF[PACKAGE_PATH]}"/{domain/model,application/service,application/ports/out,adapter/in/web,adapter/out/db}
mkdir -p scripts
mkdir -p src/main/resources
mkdir -p "${PROJETO_CONF[PACKAGE_PATH]}"/{application/service,domain/model,adapter/in/web}
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

# --- DOCUMENTAÇÃO TÉCNICA (README) ---
# --- DOCUMENTAÇÃO TÉCNICA (Mermaid Flow) ---
# --- KUBERNETES: DEPLOYMENT ---
# --- KUBERNETES: HPA & SERVICE ---
# --- TERRAFORM: GOOGLE CLOUD ---
# --- DOCKERFILE ---
# --- GITHUB ACTIONS: CI/CD ---
# --- TOOL SCRIPT DE LIMPEZA ---
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
      - targets: ['${PROJETO_CONF[INTERNAL_HOST]}:8080'] # Se rodar API no host e Prom no Docker
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

cd ${PROJETO_CONF[PROJECT_NAME]}

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

mkdir -p ${PROJETO_CONF[PACKAGE_PATH]}/infrastructure/security
cat <<EOF > ${PROJETO_CONF[PACKAGE_PATH]}/infrastructure/security/SecurityConfig.java
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
cat <<EOF > ${PROJETO_CONF[PACKAGE_PATH]}/application/service/TransactionMetrics.java
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
cat <<EOF > ${PROJETO_CONF[PACKAGE_PATH]}/adapter/in/web/TransactionController.java
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
    url = "http://${PROJETO_CONF[HOST_NAME]}:8080/actuator/prometheus"
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
cat <<EOF > ${PROJETO_CONF[PACKAGE_PATH]}/domain/model/Transaction.java
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

echo "✅ Projeto '${PROJETO_CONF[PROJECT_NAME]}' criado com sucesso e commit realizado!"
echo "👉 Para rodar: cd ${PROJETO_CONF[PROJECT_NAME]} && ./mvnw spring-boot:run (se tiver o maven wrapper)"


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
    if curl -s http://${PROJETO_CONF[HOST_NAME]}:8080/actuator/health | grep -q "UP"; then
        echo "✅ API está Online!"
        break
    fi
    echo -n "."
    sleep 2
done

# Simula tráfego inicial para o Agente Python ter dados
echo "📈 Gerando tráfego de teste..."
curl -s -X POST http://${PROJETO_CONF[HOST_NAME]}:8080/api/v1/transactions -H "Content-Type: application/json" -d '{"cardNumber": "123", "amount": 500}' > /dev/null
curl -s -X POST http://${PROJETO_CONF[HOST_NAME]}:8080/api/v1/transactions -H "Content-Type: application/json" -d '{"cardNumber": "123", "amount": 15000}' > /dev/null

# Executa o Agente AIOps
python3 -m venv venv
./venv/bin/pip install requests
./venv/bin/python3 scripts/aiops_health_agent.py

echo "✅ Testes de metricas realizado!"

echo "--------------------------"
# Define a cor azul sublinhado
BLUE_UNDERLINE='\e[4;34m'
RED_UNDERLINE='\e[4;31m'
NC='\e[0m' # No Color (reseta a cor)
echo -e "\n--- LINKS DA APLICAÇÃO Clique no link (Segure CTRL + Clique): ---"
echo -e "API Base:   ${BLUE_UNDERLINE}http://${PROJETO_CONF[HOST_NAME]}:8080/api/v1/transactions${NC}"
echo -e "Swagger UI: ${BLUE_UNDERLINE}http://${PROJETO_CONF[HOST_NAME]}:8080/swagger-ui/index.html${NC}"
echo -e "Prometheus: ${BLUE_UNDERLINE}http://${PROJETO_CONF[HOST_NAME]}:9090/targets${NC}"
echo -e "Grafana: ${BLUE_UNDERLINE}http://${PROJETO_CONF[HOST_NAME]}:3000 (Login: admin / Senha: admin${NC}"
echo -e "Actuator: ${RED_UNDERLINE}curl http://${PROJETO_CONF[HOST_NAME]}:8080/actuator/prometheus${NC}"
echo -e "Python: ${RED_UNDERLINE}python3 scripts/aiops_health_agent.py${NC}"
echo "--------------------------"