#!/bin/bash
echo "♻️ Resetando ambiente de desenvolvimento..."
docker stop santander-api prometheus grafana || true
docker rm santander-api prometheus grafana || true
docker-compose -f monitoring/docker-compose.yml down || true
mvn clean
#docker system prune -a --volumes -f
#docker stop $(docker ps -q)
echo "✅ Ambiente limpo."
