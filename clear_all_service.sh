#!/bin/bash
# Captura o parâmetro mesmo se usar 'source' ou execução direta
PARAM="$1"
echo "♻️ Resetando ambiente de desenvolvimento..."
# 1. Derruba o que estiver rodando pelo Compose
if [ -f "docker-compose.yml" ]; then
    docker-compose down --remove-orphans || true
fi
# 2. Limpeza de imagens órfãs
echo "🧹 Limpando imagens órfãs (<none>)..."
docker image prune -f
# 3. Lógica para o parâmetro --all
if [[ "$PARAM" == "--all" ]]; then
    echo "🚨 REMOÇÃO TOTAL: Buscando imagens 'card-system'..."    
    # Lista imagens que contém 'card-system' (API e Frontends)
    IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "card-system")    
    if [ ! -z "$IMAGES" ]; then
        echo "🗑️ Removendo: $IMAGES"
        docker rmi -f $IMAGES
    else
        echo "ℹ️ Nenhuma imagem do projeto encontrada."
    fi
fi
echo "✅ Ambiente limpo."
#docker stop santander-api prometheus grafana || true
#docker rm santander-api prometheus grafana || true
#docker-compose -f monitoring/docker-compose.yml down || true
#mvn clean
#docker system prune -a --volumes -f
#docker stop $(docker ps -q)
