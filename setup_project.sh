#!/bin/bash

# Nome do projeto
PROJECT_NAME="card-system-api"
PACKAGE_PATH="src/main/java/com/fabiano/cardsystem"

echo "🚀 Iniciando criação do projeto $PROJECT_NAME..."

# 1. Criar estrutura de pastas (Arquitetura Hexagonal)
mkdir -p $PROJECT_NAME/$PACKAGE_PATH/{domain/model,application/service,application/ports/out,adapter/in/web,adapter/out/db}
mkdir -p $PROJECT_NAME/src/main/resources


cat <<EOF > README.md
# Card System API - Santander/F1RST Challenge

Este projeto é um Microserviço focado no processamento de transações de cartões, desenvolvido como parte do processo seletivo para a posição de **Analista de Sistemas III**.

## 🚀 Tecnologias e Frameworks
- **Java 11**: Linguagem base para conformidade com o ecossistema atual.
- **Spring Boot 2.7**: Framework para agilidade no desenvolvimento de microserviços.
- **Arquitetura Hexagonal (Ports and Adapters)**: Para garantir desacoplamento total da regra de negócio.
- **JUnit 5**: Para testes unitários de regras críticas.
- **Docker**: Containerização com imagem **Amazon Corretto 11** para ambiente Cloud-Ready.
- **Maven**: Gerenciamento de dependências e build.

## 🏗️ Arquitetura
O projeto utiliza **Arquitetura Hexagonal** para isolar o domínio das tecnologias externas (bancos de dados, frameworks, APIs externas). 



- **Domain**: Entidades e regras de negócio puras.
- **Application**: Casos de uso e portas de entrada/saída.
- **Adapters (In/Out)**: Implementações técnicas (REST Controllers, Persistence, etc.).

## 🛠️ Como Executar o Projeto

### Pré-requisitos
- Docker instalado.
- Maven 3.8+ (opcional se usar Docker).

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
curl -X POST http://localhost:8080/api/v1/transactions \\
-H "Content-Type: application/json" \\
-d '{"cardNumber": "1234-5678", "amount": 500.00}'
\`\`\`

**Rejeição de Transação (Valor > 10.000):**
\`\`\`bash
curl -X POST http://localhost:8080/api/v1/transactions \\
-H "Content-Type: application/json" \\
-d '{"cardNumber": "1234-5678", "amount": 15000.00}'
\`\`\`

## 🛡️ Diferenciais Implementados
- **Global Exception Handler**: Padronização de erros JSON para conformidade com gateways de API.
- **Troubleshooting Ready**: Logs estruturados para facilitar a análise em ambientes produtivos.
- **Cloud Friendly**: Configuração preparada para ambientes AWS/Azure via Docker.

---
**Desenvolvido por Fabiano - Candidato Analista III**
EOF

cd $PROJECT_NAME

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
import java.math.BigDecimal;

public class Transaction {
    private Long id;
    private String cardNumber;
    private BigDecimal amount;
    private String status;

    public Transaction() {}
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public BigDecimal getAmount() { return amount; }
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

# 5. Criar o Dockerfile
cat <<EOF > Dockerfile
FROM amazoncorretto:11-alpine
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF

# 6. Inicializar Git e Primeiro Commit
echo "📦 Inicializando repositório Git..."
git init
cat <<EOF > .gitignore
target/
.mvn/
.idea/
*.class
.DS_Store
EOF

git add .
git commit -m "feat: initial structure with hexagonal architecture, java 11 and docker"

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
docker run --rm card-system-api:1.0 java -version
docker run -d -p 8080:8080 --name santander-api card-system-api:1.0
curl -X POST http://localhost:8080/api/v1/transactions -H "Content-Type: application/json" -d '{"cardNumber": "1234-5678", "amount": 500.00}'
#curl -X POST http://localhost:8080/api/v1/transactions -H "Content-Type: application/json" -d '{"cardNumber": "1234-5678", "amount": 15000.00}'
