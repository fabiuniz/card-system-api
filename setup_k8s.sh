#!/bin/bash
#setup_k8s.sh
# Define a raiz do projeto dinamicamente para evitar caminhos fixos "hardcoded"
BASE_DIR=$(pwd)

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

echo "📊 Relatório de cobertura gerado em: target/site/jacoco/index.html"
mvn test -Dtest=TransactionServiceTest
# Opcional: printar a cobertura no terminal (exemplo simples)
grep -o 'Total[^%]*%' target/site/jacoco/index.html | head -1 || echo "Cobertura calculada."

echo "🐳 Construindo imagem Docker da API..."
docker build -t card-system-api:1.0 .

echo "🖼️ Injetando imagem no Minikube..."
minikube image load card-system-api:1.0

echo "☸️ Aplicando Manifestos do diretório k8s/..."
# Aqui está o segredo: apontamos para a pasta sem entrar nela
minikube kubectl -- apply -f ${BASE_DIR}/k8s/

echo "📊 Ativando Metrics Server..."
minikube addons enable metrics-server

echo "⏳ Aguardando os Pods ficarem prontos..."
minikube kubectl -- wait --for=condition=ready pod -l app=card-api --timeout=120s

echo "✅ Ambiente pronto! Iniciando Port-Forward..."
echo "Acesse em: http://vmlinuxd:8080"

# O port-forward bloqueia o terminal. 
# Rodamos o comando service em background para não travar o script.
minikube service santander-card-api-service &

# Mantém o port-forward ativo no terminal principal
minikube kubectl -- port-forward service/santander-card-api-service 8080:80 --address 0.0.0.0
