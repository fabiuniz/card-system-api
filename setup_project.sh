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
# Cria toda a estrutura de uma vez, sem repetições
# a. CORE DA APLICAÇÃO (Arquitetura Hexagonal Java)
mkdir -p "${PROJETO_CONF[PACKAGE_PATH]}"/{domain/model,application/{service,ports/{in,out}},adapters/{in/web/exception,out/{persistence,metrics}},infrastructure/{security,config}}
# b. OBSERVABILIDADE (Prometheus, Grafana, Nginx)
mkdir -p monitoring/{prometheus,grafana/provisioning/{datasources,dashboards},nginx}
# c. INFRAESTRUTURA & CLOUD (IaaS, K8s, Terraform)
mkdir -p {.idx,k8s,terraform}
# d. CI/CD & RECURSOS (GitHub, Scripts, Resources)
mkdir -p {.github/workflows,scripts,src/main/resources}
# Corrige permissões de escrita para os volumes do Grafana/Prometheus no ambiente Cloud
chmod -R 777 monitoring/grafana
chmod -R 777 monitoring/prometheus
chmod +x setup_iaas.sh
chmod +x setup_application.sh 
chmod +x setup_front_vue.sh

# Conteúdo do setup_iaas.sh
# --- DOCUMENTAÇÃO TÉCNICA (README) ---
# --- DOCUMENTAÇÃO TÉCNICA (Mermaid Flow) ---
# --- KUBERNETES: DEPLOYMENT ---
# --- KUBERNETES: HPA & SERVICE ---
# --- TERRAFORM: GOOGLE CLOUD ---
# --- GITHUB ACTIONS: CI/CD ---
# --- NGNIX ---
# --- GRAFANA DATASOURCE ---
# --- GRAFANA CONFIG--- 
# --- PROMETHEUS ---
# --- DOCKERFILE ---
# --- DOCKER COMPOSE ---
# --- TOOL SCRIPT DE LIMPEZA ---
. setup_iaas.sh
. setup_application.sh
# --- Metricas sobre o projeto ---
. setup_analyses.sh
. setup_front_vue.sh



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
echo -e "Vue Frontend: ${BLUE_UNDERLINE}http://${PROJETO_CONF[HOST_NAME]}:4000 {NC}"
echo -e "Actuator: ${RED_UNDERLINE}curl http://${PROJETO_CONF[HOST_NAME]}:8080/actuator/prometheus${NC}"
echo -e "Python: ${RED_UNDERLINE}python3 scripts/aiops_health_agent.py${NC}"
echo "--------------------------"