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
echo "🌐 http://santander-api:8080/api/v1/transactions"
echo "🌐 http://santander-api:8080/swagger-ui/index.html"

minikube status
