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
# removido cat <<EOF > ${PROJETO_CONF[PACKAGE_PATH]}/application/service/TransactionMetrics.java


cat <<EOF > ${PROJETO_CONF[PACKAGE_PATH]}/application/service/TransactionService.java
package com.fabiano.cardsystem.application.service;
import com.fabiano.cardsystem.application.ports.in.ProcessTransactionUseCase;
import com.fabiano.cardsystem.application.ports.out.TransactionOutputPort;
import com.fabiano.cardsystem.domain.model.Transaction;
import org.springframework.stereotype.Service;
import java.util.UUID;
@Service
public class TransactionService implements ProcessTransactionUseCase {
    private final TransactionOutputPort metricsPort;
    public TransactionService(TransactionOutputPort metricsPort) {
        this.metricsPort = metricsPort;
    }
    @Override
    public Transaction execute(Transaction transaction) {
        // Regra de Negócio: Limite de R$ 10.000
        if (transaction.getAmount().doubleValue() > 10000) {
            transaction.setStatus("REJECTED");
            metricsPort.reportRejection();
        } else {
            transaction.setStatus("APPROVED");
            metricsPort.reportApproval();
        }
        transaction.setTransactionId(UUID.randomUUID().toString());
        return transaction;
    }
}
EOF

# --- TRANSACTION CONTROLLER (Com Logs e Métricas) ---
cat <<EOF > ${PROJETO_CONF[PACKAGE_PATH]}/adapters/in/web/TransactionController.java
package com.fabiano.cardsystem.adapters.in.web;
import com.fabiano.cardsystem.domain.model.Transaction;
import com.fabiano.cardsystem.application.ports.in.ProcessTransactionUseCase;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import java.util.Map;
@RestController
@RequestMapping("/api/v1/transactions")
public class TransactionController {
    // Injetamos a Porta de Entrada (Caso de Uso), não o adaptador de métricas!
    private final ProcessTransactionUseCase processTransactionUseCase;
    public TransactionController(ProcessTransactionUseCase processTransactionUseCase) {
        this.processTransactionUseCase = processTransactionUseCase;
    }
    @PostMapping
    public ResponseEntity<?> process(@RequestBody Transaction transaction) {
        if (transaction.getAmount() == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Amount is required"));
        }
        // Delegamos TODA a lógica de negócio e métricas para o Service
        Transaction result = processTransactionUseCase.execute(transaction);
        if ("REJECTED".equals(result.getStatus())) {
            return ResponseEntity.status(422).body(result);
        }
        return ResponseEntity.ok(result);
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
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-data-mongodb</artifactId>
    </dependency>
    <dependency>
      <groupId>org.postgresql</groupId>
      <artifactId>postgresql</artifactId>
      <scope>runtime</scope>
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
import java.math.BigDecimal;

public class Transaction {
    private String cardNumber;
    private BigDecimal amount;
    private String status;
    private String transactionId;

    public Transaction() {}
    public String getCardNumber() { return cardNumber; }
    public void setCardNumber(String cardNumber) { this.cardNumber = cardNumber; }
    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getTransactionId() { return transactionId; }
    public void setTransactionId(String transactionId) { this.transactionId = transactionId; }
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

# Criando a Porta de Entrada
cat <<EOF > ${PROJETO_CONF[PACKAGE_PATH]}/application/ports/in/ProcessTransactionUseCase.java
package com.fabiano.cardsystem.application.ports.in;
import com.fabiano.cardsystem.domain.model.Transaction;
public interface ProcessTransactionUseCase {
    Transaction execute(Transaction transaction);
}
EOF

# Criando a Porta de Saída para Métricas
cat <<EOF > ${PROJETO_CONF[PACKAGE_PATH]}/application/ports/out/TransactionOutputPort.java
package com.fabiano.cardsystem.application.ports.out;

public interface TransactionOutputPort {
    void reportApproval();
    void reportRejection();
}
EOF

# --- ADAPTER OUT: Implementação Micrometer (Infrastructure Layer) ---
cat <<EOF > ${PROJETO_CONF[PACKAGE_PATH]}/adapters/out/metrics/TransactionMetricsAdapter.java
package com.fabiano.cardsystem.adapters.out.metrics;

import com.fabiano.cardsystem.application.ports.out.TransactionOutputPort;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Component;

@Component
public class TransactionMetricsAdapter implements TransactionOutputPort {
    private final Counter approved;
    private final Counter rejected;

    public TransactionMetricsAdapter(MeterRegistry registry) {
        this.approved = Counter.builder("transactions_total").tag("status", "approved").register(registry);
        this.rejected = Counter.builder("transactions_total").tag("status", "rejected").register(registry);
    }

    @Override public void reportApproval() { approved.increment(); }
    @Override public void reportRejection() { rejected.increment(); }
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

mkdir -p src/main/java/com/fabiano/cardsystem/adapters/in/web
cat <<EOF > ${PROJETO_CONF[PACKAGE_PATH]}/adapters/in/web/TransactionController.java
package com.fabiano.cardsystem.adapters.in.web;

import com.fabiano.cardsystem.domain.model.Transaction;
import com.fabiano.cardsystem.application.ports.out.TransactionOutputPort;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/transactions")
public class TransactionController {
    private final TransactionOutputPort metricsPort;

    public TransactionController(TransactionOutputPort metricsPort) {
        this.metricsPort = metricsPort;
    }

    @PostMapping
    public ResponseEntity<?> process(@RequestBody Transaction transaction) {
        if (transaction.getAmount() == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Amount is required"));
        }

        if (transaction.getAmount().doubleValue() > 10000) {
            metricsPort.reportRejection();
            return ResponseEntity.status(422).body(Map.of(
                "status", "REJECTED",
                "reason", "Limit exceeded",
                "transactionId", UUID.randomUUID().toString()
            ));
        }

        metricsPort.reportApproval();
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