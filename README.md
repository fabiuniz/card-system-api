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

Este projeto nasceu para transcender o desenvolvimento tradicional. 
## **Abordagem SRE-Driven:**
Este projeto não foi apenas "codado"; ele foi projetado para ser resiliente. A infraestrutura e a observabilidade foram definidas como requisitos de primeira classe antes da implementação da lógica de negócio onde é entregue **Disponibilidade**. Através da **Arquitetura Hexagonal**, isolamos o core bancário de instabilidades externas. Com o **HPA (Horizontal Pod Autoscaler)**, nossa infraestrutura "respira" conforme a demanda, e através de um **Agente AIOps em Python**, detectamos anomalias antes que elas afetem o cliente final. É a engenharia de software aliada à inteligência operacional para garantir um sistema que nunca dorme.

---

## 🌟 Specialist Evolution (Vaga Atual: Especialista AIOps)
Diferente da versão inicial de Analista III, esta branch introduz conceitos avançados de **SRE** e **AIOps**, elevando a maturidade do microserviço:

- **Observabilidade Full-Stack**: Implementação de métricas customizadas via **Micrometer** e exposição de telemetria via **Spring Actuator**.
- **Python AIOps Agent**: Script lateral (`/scripts`) que consome dados de saúde da API para automação de incidentes.
- **FinOps Ready**: Configuração de limites de recursos (CPU/MEM) no CI/CD para otimização de custos no GCP Cloud Run.
- **Resiliência Nativa**: Implementação de *Liveness* e *Readiness Probes* para garantir o Self-healing do container.
- **Analytics Integrado**: Camada de dados pronta para BI (Looker) para visão executiva do negócio.
- 
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
- **Prometheus & Grafana**: Dashboards técnicos de saúde do sistema (SRE).
- **Kubernetes (Minikube)**: Orquestração local com suporte a HPA e Metrics Server.
- **Terraform**: Infraestrutura como Código para GCP e Docker local.
- **Looker / LookML**: Modelagem de dados para análise de KPIs.

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
```bash
apt-get update && apt-get install maven -y
apt-get update && apt-get install docker.io -y
systemctl start docker
systemctl enable docker
usermod -aG docker $USER
```

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
curl -X POST http://localhost:8080/api/v1/transactions -H "Content-Type: application/json" -d '{"cardNumber": "1234-5678", "amount": 500.00}'
```

**Rejeição de Transação (Valor > 10.000):**
```bash
curl -X POST http://localhost:8080/api/v1/transactions -H "Content-Type: application/json" -d '{"cardNumber": "1234-5678", "amount": 15000.00}'
```
### 🤖 Validando a Camada de AIOps
Após subir o container, você pode validar a telemetria que alimenta nossa IA:

**1. Ver métricas brutas (Prometheus format):**
```bash
curl http://localhost:8080/actuator/prometheus
```

# O agente analisa o status e transações em tempo real
```bash
python3 scripts/aiops_health_agent.py
```

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

Para replicar o ambiente de produção, siga os passos abaixo utilizando o `gcloud CLI`:

### ⚙ 1. Configuração de Acesso (Service Account)
```bash
# 1. Definir a variável corretamente (sem espaços)
export PROJECT_ID="santander-repo"

# 2. Ativar a API do Artifact Registry (isso só funcionará após o Billing ser vinculado)
gcloud services enable artifactregistry.googleapis.com --project=$PROJECT_ID
gcloud services enable run.googleapis.com --project=santander-repo

# 3. Criar a Service Account (se der erro de 'already exists', pode ignorar)
gcloud iam service-accounts create github-deploy-sa || echo "Conta já existe"

# 4. Atribuir permissões usando a variável $PROJECT_ID
gcloud projects add-iam-policy-binding $PROJECT_ID     --member="serviceAccount:github-deploy-sa@$PROJECT_ID.iam.gserviceaccount.com"     --role="roles/run.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID     --member="serviceAccount:github-deploy-sa@$PROJECT_ID.iam.gserviceaccount.com"     --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $PROJECT_ID     --member="serviceAccount:github-deploy-sa@$PROJECT_ID.iam.gserviceaccount.com"     --role="roles/iam.serviceAccountUser"

# 5. Gerar a chave JSON
gcloud iam service-accounts keys create gcp-key.json     --iam-account=github-deploy-sa@$PROJECT_ID.iam.gserviceaccount.com

# Garante que você está no projeto correto
gcloud config set project $PROJECT_ID

# Habilita a API do Artifact Registry
gcloud services enable artifactregistry.googleapis.com

gcloud artifacts repositories create $PROJECT_ID     --repository-format=docker     --location=us-central1     --description="Repositorio Docker para o Santander F1RST"

gcloud projects add-iam-policy-binding $PROJECT_ID     --member="serviceAccount:github-deploy-sa@$PROJECT_ID.iam.gserviceaccount.com"     --role="roles/artifactregistry.writer"if [[ condition ]]; then
      #statements
    fi    

cat gcp-key.json    
gcloud config get-value project
```
### ⚙ 2. Configuração de Secrets no GitHub

Copie todo o texto que aparecer (começa com { e termina com }).
Não cole essa chave diretamente no seu código! 
Ela deve ser guardada nos Secrets do seu repositório para ficar protegida:

Acesse o seu repositório no GitHub.

Vá na aba Settings (Configurações).

No menu lateral esquerdo, clique em Secrets and variables > Actions.

- **Clique em secret  and variables.**

**Aba: Secrets (Botão "New repository secret")**
```bash
Name: GCP_SA_KEY
Value: (Cole todo o conteúdo do arquivo gcp-key.json)
```

**Aba: Variables (Botão "New repository variable")**
```bash
Name: GCP_PROJECT_ID
Value: santander-repo
```

```bash
    GCP_PROJECT_ID: "O ID do seu projeto no Google Cloud."
    GCP_SA_KEY: "O conteúdo completo do arquivo gcp-key.json gerado no passo anterior.""
```

### 🚀 3. Testando a implantação da aplicação

Para visualizar a aplicação em execução, acesse o Cloud Run no console do Google Cloud e localize o serviço santander-repo.

A documentação interativa das APIs (Swagger) está disponível no endpoint final da URL gerada.

Exemplo de link para acesso: 🔗 https://8080xxxxxxxxxxxxxxxxxxx.run.app/swagger

## 📊 Guia de Configuração do Dashboard de Observabilidade

Siga os passos abaixo para conectar os dados da API ao Grafana e visualizar a saúde do sistema.

### 1. Acesso ao Grafana
* **URL:** `http://vmlinuxd:3000`
* **Credenciais:** Usuário `admin` | Senha `admin`

### 2. Configurar Fonte de Dados (Prometheus)
O Grafana precisa "ler" o banco de dados do Prometheus:
1. No menu lateral, clique em **Connections** > **Data Sources**.
2. Clique em **Add data source** e selecione **Prometheus**.
3. No campo **URL**, digite: `http://prometheus:9090`
4. Role até o fim e clique em **Save & Test**. (Deve aparecer uma confirmação verde).

### 3. Criar Painel de Transações (Business Metrics)
Para ver o volume de Aprovações vs. Rejeições:
1. No menu lateral, clique em **Dashboards** > **New** > **Add Visualization**.
2. Selecione o Data Source **Prometheus**.
3. No campo de busca **Query**, insira:
   ```promql
   sum(transactions_total) by (status)
   ```
4. No canto direito, em Panel options, altere o título para `Status de Transações (Tempo Real)`.
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

```promql

for i in {1..50}; do 
  curl -s -X POST http://vmlinuxd:8080/api/v1/transactions   -H "Content-Type: application/json"   -d "{\"cardNumber\": \"1234\", \"amount\": $((RANDOM % 15000))}" > /dev/null
  sleep 0.5
done
```

### 📊 Observabilidade Automática (IaC)
O ambiente já está pré-configurado com **Dashboards as Code**.
1. Acesse `http://vmlinuxd:3000` (admin/admin).
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

## 📊 Analytics & BI Layer (Looker)
Além da observabilidade técnica, o projeto conta com uma camada de inteligência de negócios preparada para o **Looker (Professional ou Studio)**, permitindo análises executivas sobre o comportamento das transações.

- **LookML View**: Definição de métricas de negócio (Taxa de Aprovação, Volume Financeiro) e métricas SRE (SLA de Latência > 200ms) diretamente no código.
- **Data Generator**: Script automatizado (`setup_analyses.sh`) que gera massa de dados sintéticos e instruções de conexão para BigQuery.
- **Visualização Condicional**: Formatação HTML integrada para status de transações (Verde para Approved / Vermelho para Rejected).

**Para configurar:** Execute `./setup_analyses.sh` e siga as instruções geradas no diretório `analyses/looker/`.

### 🛠️ Metodologia e Uso de IA
Este projeto foi desenvolvido utilizando uma abordagem de Engenharia Aumentada por IA.

"Embora tenha utilizado ferramentas de Inteligência Artificial para acelerar a implementação de determinados módulos e scripts, detenho o domínio da Arquitetura de Referência e dos conceitos fundamentais de SRE/AIOps. Isso me permite manter o controle técnico total da solução, realizar 'deep dives' em qualquer componente conforme a necessidade e garantir que a automação sirva aos objetivos de negócio de forma produtiva e segura."
