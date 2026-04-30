#!/bin/bash
clear
# --- FUNÇÃO DE VERIFICAÇÃO DE DEPENDÊNCIAS ---
verificar_ferramentas() {
    echo "🔍 Verificando dependências do sistema..."

    # 1. Verificar/Instalar Docker
    if ! command -v docker &> /dev/null; then
        echo "🐳 Docker não encontrado. Instalando..."
        curl -fsSL https://get.docker.com | sh
        systemctl start docker
        systemctl enable docker
    else
        echo "✅ Docker já está instalado."
    fi

    # 2. Verificar/Instalar Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo "🐙 Docker Compose não encontrado. Instalando..."
        # Baixa a versão estável mais recente
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    else
        echo "✅ Docker Compose já está instalado."
    fi

    # 3. Verificar Ferramentas de Rede e Python (O que causou erro antes)
    echo "📦 Atualizando ferramentas de rede e Python..."
    apt-get update -qq
    apt-get install -y curl python3-venv python3-pip &> /dev/null
}

# 1. INSTALAÇÃO DE DEPENDÊNCIAS (Mover para o topo)
echo "🔧 Preparando ferramentas do Host..."
verificar_ferramentas

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

export PROJECT_ROOT="$(pwd)/${PROJETO_CONF[PROJECT_NAME]}"

# 3. Faz a atribuição dinâmica (Sincroniza URL com o Host)
# PROJETO_CONF[HOST_NAME]='localhost'
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
echo "🧹 Limpando resquícios e organizando Arquitetura Hexagonal..."
# 1. Remove pastas de Frontend que entraram por engano no projeto Java
rm -rf src/assets src/components
rm -rf "${PROJETO_CONF[PACKAGE_PATH]}/infrastructure/persistence/adapter"
# 2. Cria a estrutura limpa e profissional
mkdir -p "${PROJETO_CONF[PACKAGE_PATH]}"/{domain/model,\
application/{service,ports/{in,out}},\
adapters/{in/web/exception,out/{persistence,metrics}},\
infrastructure/{security,config,persistence/{entity,document,repository}}} \
src/test/java/com/fabiano/cardsystem/domain/model \
src/test/java/com/fabiano/cardsystem/application/service
# b. OBSERVABILIDADE (Prometheus, Grafana, Nginx)
mkdir -p monitoring/{prometheus,grafana/provisioning/{datasources,dashboards},nginx}
# c. INFRAESTRUTURA & CLOUD (IaaS, K8s, Terraform)
mkdir -p {.idx,k8s,terraform}
# Databases (Configurações de Inicialização)
mkdir -p {postgres-init,mysql-init,mongo-init,pgadmin-config}
# d. CI/CD & RECURSOS
mkdir -p {.github/workflows,scripts,src/main/resources}
#IoT
mkdir -p iot/esp01_monitor/
#IA
mkdir -p {aiops/brain,aiops/vector_db,aiops/config}
echo "✅ Estrutura de pastas higienizada!"
# Corrige permissões de escrita para os volumes do Grafana/Prometheus no ambiente Cloud
chmod -R 777 monitoring/grafana
chmod -R 777 monitoring/prometheus
chmod +x setup_utils.sh
chmod +x setup_iaas.sh
chmod +x setup_databases.sh 
chmod +x setup_application.sh 
chmod +x setup_front_vue.sh
chmod +x setup_front_angular.sh
chmod +x setup_front_react.sh
chmod +x setup_front_flutter.sh
chmod +x setup_iot.sh
chmod +x setup_ollama.sh
for f in setup_*.sh; do dos2unix "$f" && chmod +x "$f"; done

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
. setup_utils.sh
. setup_iaas.sh
. setup_databases.sh
. setup_application.sh
# --- Metricas sobre o projeto ---
. setup_analyses.sh
. setup_front_vue.sh
. setup_front_angular.sh
. setup_front_react.sh
. setup_front_flutter.sh
. setup_iot.sh
. setup_ollama.sh

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

echo "🔨 Iniciando Build COMPLETO com Auditoria JaCoCo..."
# REMOVIDO o -DskipTests para permitir que o JaCoCo gere os dados
mvn clean package 

# Validação imediata do Relatório
if [ -d "target/site/jacoco" ]; then
    echo "✅ JaCoCo: Relatório de cobertura gerado com sucesso!"
    # Extrai a porcentagem de cobertura para o log (Toque de Especialista)
    COVERAGE=$(grep -oP 'Total.*?(\d+%)' target/site/jacoco/index.html | head -1)
    echo "📊 Métrica de Cobertura: $COVERAGE"
else
    echo "⚠️ JaCoCo: Relatório não encontrado. Verifique os logs do Maven acima."
fi

echo "🐳 Gerando imagem Docker..."
# Garante que a imagem seja construída com o JAR recém-testado
docker-compose build --no-cache santander-api

# --- INICIALIZAÇÃO DO STACK ---
echo "🧹 Limpando ambiente anterior..."
docker-compose down --remove-orphans

echo "🔨 Gerando imagem Docker com o novo JAR..."
docker-compose build --no-cache santander-api

echo "♻️ Removendo imagens órfãs (<none>)..."
docker image prune -f

echo "🚀 Subindo a Stack..."
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

# Executa o Agente AIOps

# Simula tráfego inicial para o Agente Python ter dados
echo "📈 Gerando tráfego de teste..."
curl -s -X POST http://${PROJETO_CONF[HOST_NAME]}:8080/api/v1/transactions -H "Content-Type: application/json" -d '{"cardNumber": "123", "amount": 500}' > /dev/null
curl -s -X POST http://${PROJETO_CONF[HOST_NAME]}:8080/api/v1/transactions -H "Content-Type: application/json" -d '{"cardNumber": "123", "amount": 15000}' > /dev/null

# 1. Corrigir o ambiente virtual do Python (conforme o erro sugeriu)
rm -rf venv
python3 -m venv venv
# 2. Instalar a biblioteca requests necessária para o aiops_health_agent.py
./venv/bin/pip install requests
# 3. RUN AIOps
./venv/bin/python3 scripts/aiops_health_agent.py

echo "✅ Testes de metricas realizado!"

echo "--------------------------"
# Define a cor azul sublinhado
BLUE_UNDERLINE='\e[4;34m'
RED_UNDERLINE='\e[4;31m'
NC='\e[0m' # No Color (reseta a cor)
echo -e "\n--- 🚀 LINKS DA APLICAÇÃO Clique no link (Segure CTRL + Clique): ---"
echo -e "☕API Base:   ${BLUE_UNDERLINE}http://${PROJETO_CONF[HOST_NAME]}:8080/api/v1/transactions${NC}"
echo -e "📖 Swagger UI: ${BLUE_UNDERLINE}http://${PROJETO_CONF[HOST_NAME]}:8080/swagger-ui/index.html${NC}"
echo -e "📈 Prometheus: ${BLUE_UNDERLINE}http://${PROJETO_CONF[HOST_NAME]}:9090/targets${NC}"
echo -e "🔥 Grafana: ${BLUE_UNDERLINE}http://${PROJETO_CONF[HOST_NAME]}:3000 (Login: admin / Senha: admin${NC}"
echo -e "🍃 MongoDb: ${BLUE_UNDERLINE}http://${PROJETO_CONF[HOST_NAME]}:8082 (Login: admin / Senha: admin${NC}"
echo -e "🐬 Mysql: ${BLUE_UNDERLINE}http://${PROJETO_CONF[HOST_NAME]}:8083 (servidor:mysqldb Login: root / Senha: admin${NC}"
echo -e "🐘 Postgres:  ${BLUE_UNDERLINE}http://${PROJETO_CONF[HOST_NAME]}:8084 (admin@admin.com / admin)${NC}"
echo -e "🟢 Vue Frontend: ${BLUE_UNDERLINE}http://${PROJETO_CONF[HOST_NAME]}:4000${NC}"
echo -e "🅰️ Angular Frontend: ${BLUE_UNDERLINE}http://${PROJETO_CONF[HOST_NAME]}:4200${NC}"
echo -e "⚛️ React Frontend: ${BLUE_UNDERLINE}http://${PROJETO_CONF[HOST_NAME]}:4300${NC}"
echo -e "⚙️ Actuator: ${RED_UNDERLINE}curl http://${PROJETO_CONF[HOST_NAME]}:8080/actuator/prometheus${NC}"
echo -e "🐍 Python: ${RED_UNDERLINE}python3 scripts/aiops_health_agent.py${NC}"
echo "--------------------------"

echo 'start chrome --incognito "https://gemini.google.com/" "http://'${PROJETO_CONF[HOST_NAME]}':8081" "http://'${PROJETO_CONF[HOST_NAME]}':3000" "http://'${PROJETO_CONF[HOST_NAME]}':9090/targets" "http://'${PROJETO_CONF[HOST_NAME]}':8080/swagger-ui/index.html" "http://'${PROJETO_CONF[HOST_NAME]}':4000" "http://'${PROJETO_CONF[HOST_NAME]}':4200" "http://'${PROJETO_CONF[HOST_NAME]}':4300" "http://'${PROJETO_CONF[HOST_NAME]}':8082" "http://'${PROJETO_CONF[HOST_NAME]}':8083" "http://'${PROJETO_CONF[HOST_NAME]}':8084" "http://'${PROJETO_CONF[HOST_NAME]}':8501"'