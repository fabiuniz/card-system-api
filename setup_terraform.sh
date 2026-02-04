#!/bin/bash

# Garante que estamos na raiz do projeto para começar
BASE_DIR=$(pwd)

echo "🛠️ Instalando Terraform e Dependências..."
apt-get update && apt-get install -y gnupg software-properties-common curl lsb-release

# Chave GPG e Repositório
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg --yes
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

apt-get update && apt-get install terraform -y

echo "🚀 Validando instalação..."
terraform -version

# Entra na pasta terraform existente (onde estão seus arquivos .tf)
cd ${BASE_DIR}/terraform

echo "📥 Inicializando Providers em: $(pwd)"
# Limpeza para evitar erros de cache/deadline
rm -rf .terraform/ .terraform.lock.hcl

MAX_RETRIES=3
COUNT=0
SUCCESS=false

until [ $COUNT -ge $MAX_RETRIES ]; do
    if terraform init; then
        echo "✅ Terraform inicializado com sucesso!"
        SUCCESS=true
        break
    else
        COUNT=$((COUNT+1))
        echo "⚠️ Falha na conexão (Tentativa $COUNT/$MAX_RETRIES). Tentando novamente em 10s..."
        sleep 10
    fi
done

if [ "$SUCCESS" = false ]; then
    echo "❌ Erro crítico: Falha ao baixar providers."
    exit 1
fi

echo "🛡️ Dica: Agora execute 'gcloud auth application-default login'"
