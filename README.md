<!-- 
  Tags: DevOps,Iac
  Label: ⚙️ Card System API - Santander/F1RST Challenge
  Description:⭐ Microserviço focado no processamento de transações de cartões
  technical_requirement: Java 11, Spring Boot 2.7, Spring Data JPA, Hibernate, MySQL, Docker, Maven, JUnit 5, Hexagonal Architecture, SOLID, Clean Architecture, REST API, Global Exception Handling, Bean Validation, Bash Scripting, Linux (Debian), Git, GitFlow, Amazon Corretto, Multi-stage builds, CI/CD, GitHub Actions, SRE, Troubleshooting, Cloud Computing.
  path_hook: hookfigma.hook18,hookfigma.hook20
-->
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
```bash
mvn clean package -DskipTests
```

### Passo 2: Build da Imagem Docker
```bash
docker build -t card-system-api:1.0 .
```

### Passo 3: Execução do Container
```bash
docker run -d -p 8080:8080 --name santander-api card-system-api:1.0
```

## 🧪 Validando a API (Exemplos de Endpoints)

**Aprovação de Transação (Valor < 10.000):**
```bash
curl -X POST http://localhost:8080/api/v1/transactions \
-H "Content-Type: application/json" \
-d '{"cardNumber": "1234-5678", "amount": 500.00}'
```

**Rejeição de Transação (Valor > 10.000):**
```bash
curl -X POST http://localhost:8080/api/v1/transactions \
-H "Content-Type: application/json" \
-d '{"cardNumber": "1234-5678", "amount": 15000.00}'
```

## 🛡️ Diferenciais Implementados
- **Global Exception Handler**: Padronização de erros JSON para conformidade com gateways de API.
- **Troubleshooting Ready**: Logs estruturados para facilitar a análise em ambientes produtivos.
- **Cloud Friendly**: Configuração preparada para ambientes AWS/Azure via Docker.

---
**Desenvolvido por Fabiano - Candidato Analista III**
