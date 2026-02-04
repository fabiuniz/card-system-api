#!/bin/bash

echo "🛠️ Instalando Terraform e Dependências..."
apt-get update && apt-get install -y gnupg software-properties-common curl lsb-release

# 2. Chave GPG e Repositório
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg --yes
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

# 4. Instalação
apt-get update && apt-get install terraform -y

# 5. Validação e Inicialização com Lógica de Resiliência
echo "🚀 Validando instalação..."
terraform -version

# Entra na pasta do terraform antes de iniciar
cd terraform/ 2>/dev/null || mkdir -p terraform && cd terraform/

echo "📥 Inicializando Providers (Google Cloud)..."
# Limpeza prévia para evitar Deadlines de tentativas anteriores
rm -rf .terraform/ .terraform.lock.hcl

# Lógica de Retry para o erro 'context deadline exceeded'
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
    echo "❌ Erro crítico: Falha ao baixar providers após $MAX_RETRIES tentativas."
    exit 1
fi

echo "🛡️ Dica: Agora execute 'gcloud auth application-default login' para autenticar."
