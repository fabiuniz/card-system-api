#!/bin/bash
echo "♻️ Resetando ambiente de desenvolvimento..."
docker stop santander-api prometheus grafana || true
docker rm santander-api prometheus grafana || true
docker-compose -f monitoring/docker-compose.yml down || true
mvn clean
echo "✅ Ambiente limpo."
