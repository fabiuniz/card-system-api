#!/bin/bash
cd terraform/
echo "🔍 Verificando plano de infraestrutura..."
terraform plan -out=tfplan
echo "🚀 Aplicando mudanças no GCP..."
terraform apply tfplan
