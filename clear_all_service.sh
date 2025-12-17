#!/bin/bash

# 1. Obtém apenas projetos ativos para evitar erro em projetos já deletados
PROJECTS=$(gcloud projects list --filter="lifecycleState=ACTIVE" --format="value(PROJECT_ID)")

for PROJ in $PROJECTS; do
    echo "--------------------------------------------------------"
    echo "🚀 PROJETANDO LIMPEZA EM: [$PROJ]"
    echo "--------------------------------------------------------"

    # 1. Removendo Buckets (Apenas se existirem)
    echo "🗑️ Verificando Buckets..."
    BUCKETS=$(gsutil ls -p "$PROJ" 2>/dev/null)
    if [ -z "$BUCKETS" ]; then
        echo "   -> Nenhum bucket encontrado."
    else
        echo "   -> Removendo buckets encontrados..."
        for BKT in $BUCKETS; do
            gsutil -m rm -r "$BKT"
        done
    fi

    # 2. Removendo Discos (Apenas se a API de Compute estiver ativa)
    echo "💾 Verificando Discos..."
    # Verifica se a API de compute está ativa antes de tentar listar discos
    API_COMPUTE=$(gcloud services list --project="$PROJ" --filter="config.name:compute.googleapis.com" --format="value(config.name)")
    
    if [ ! -z "$API_COMPUTE" ]; then
        DISKS=$(gcloud compute disks list --project="$PROJ" --format="value(name,zone)" 2>/dev/null)
        if [ -z "$DISKS" ]; then
            echo "   -> Nenhum disco encontrado."
        else
            while read -r D_NAME D_ZONE; do
                if [ ! -z "$D_NAME" ]; then
                    echo "   -> Deletando disco: $D_NAME"
                    gcloud compute disks delete "$D_NAME" --project="$PROJ" --zone="$D_ZONE" --quiet
                fi
            done <<< "$DISKS"
        fi
    else
        echo "   -> API Compute Engine não está ativa. Pulando discos."
    fi

    # 3. Desativar APIs (O ponto mais importante para parar cobranças)
    echo "🔒 Desativando APIs principais..."
    APIS=("run.googleapis.com" "artifactregistry.googleapis.com" "compute.googleapis.com" "sqladmin.googleapis.com")
    
    for API in "${APIS[@]}"; do
        # Verifica se a API está ativa antes de tentar desativar
        IS_ENABLED=$(gcloud services list --project="$PROJ" --filter="config.name:$API" --format="value(config.name)")
        
        if [ ! -z "$IS_ENABLED" ]; then
            gcloud services disable "$API" --project="$PROJ" --force --quiet
            echo "   ✅ API $API desativada com sucesso."
        else
            echo "   ℹ️ API $API já estava desativada."
        fi
    done

    echo "🏁 Concluído: $PROJ está limpo."
done