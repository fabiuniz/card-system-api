#!/bin/bash

# --- FUNÇÕES DE INSTALAÇÃO (Extraídas de lib_bash.sh) ---

install_docker_if_missing() {
    if ! command -v docker &> /dev/null; then
        echo "🐳 Docker não encontrado. Instalando..."
        apt-get update
        apt-get install -y docker.io
        systemctl start docker
        systemctl enable docker
        echo "✅ Docker instalado com sucesso."
    else
        echo "✅ Docker já está instalado."
    fi
}

install_docker_compose_if_missing() {
    if ! command -v docker-compose &> /dev/null; then
        echo "🐙 Docker Compose não encontrado. Instalando..."
        # Opção via repositório (conforme seu script original)
        apt-get update && apt-get install -y docker-compose
        echo "✅ Docker Compose instalado com sucesso."
    else
        echo "✅ Docker Compose já está instalado."
    fi
}

install_utils() {
    echo "📦 Instalando utilitários (parted, dos2unix)..."
    apt-get update
    apt-get install -y parted dos2unix curl
}

# --- FUNÇÃO DE DIAGNÓSTICO (Dashboard Clean) ---

dashboard_docker() {
    echo "=== 📊 DASHBOARD DOCKER ==="
    echo "--- Containers Ativos ---"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo -e "\n--- Uso de Recursos ---"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
    
    echo -e "\n--- Armazenamento ---"
    docker system df
}

# --- FUNÇÃO PARA CARREGAR IMAGENS VIA TAR ---

load_images_from_tar() {
    local backup_dir="${1:-.}" # Usa o diretório atual se nenhum for passado
    echo "💾 Verificando arquivos .tar para carregar imagens Docker em: $backup_dir"
    # Verifica se existem arquivos .tar no diretório
    if [ -n "$(ls "$backup_dir"/*.tar 2>/dev/null)" ]; then
        for tar_file in "$backup_dir"/*.tar; do
            echo "📦 Encontrado: $(basename "$tar_file")"
             # Tenta carregar a imagem
            if docker load -i "$tar_file"; then
                echo "✅ Imagem de $(basename "$tar_file") carregada com sucesso."
                 # --- AÇÃO DE LIMPEZA ---
                echo "🗑️ Removendo arquivo $(basename "$tar_file") para liberar espaço..."
                rm "$tar_file"
                # -----------------------
             else
                echo "❌ Erro ao carregar $tar_file. O arquivo foi mantido para nova tentativa."
            fi
        done
    else
        echo "ℹ️ Nenhum arquivo .tar encontrado para restauração."
    fi
    docker images
}

calcular_espaco_projeto() {
    echo "📊 Calculando ocupação em disco para: ${PROJETO_CONF[PROJECT_NAME]}..."
     # Pega apenas as imagens que contém o nome do projeto
    local total_mb=$(docker images | grep "${PROJETO_CONF[PROJECT_NAME]}" | awk '
    {
        valor = $(NF-0); 
        if (valor ~ /GB/) { sub(/GB/, "", valor); soma += valor * 1024 }
        else if (valor ~ /MB/) { sub(/MB/, "", valor); soma += valor }
    } 
    END { print soma }')

    if [ -z "$total_mb" ] || [ "$total_mb" == "0" ]; then
        echo "⚠️ Nenhuma imagem encontrada para este projeto."
    else
        echo "✅ O projeto está ocupando aproximadamente: ${total_mb} MB"
    fi
}

# --- EXECUÇÃO ---

# Verifica se é root
if [ "$EUID" -ne 0 ]; then 
  echo "Por favor, execute como root (sudo)"
  exit
fi

install_utils
install_docker_if_missing
install_docker_compose_if_missing
load_images_from_tar "."
dashboard_docker
calcular_espaco_projeto

# Imagens Base (Build)
#docker load -i mysql_8.0.tar
#docker load -i mongo.tar
#docker load -i postgres_14-alpine.tar
#docker load -i prom_prometheus.tar
#docker load -i grafana_latest.tar
#docker load -i amazoncorretto_11_alpine.tar
#docker load -i nginx_latest.tar
#docker load -i node18_16_alpine.tar
#docker load -i node_18-alpine.tar
#docker load -i mongo-express
#docker load -i pgadmin4.tar
#docker load -i phpmyadmin.tar
#
#Total reclaimed space: 232.2MB
#root@vmlinuxd:/home/userlnx/docker/script_docker/card-system-api# docker images
#REPOSITORY                                TAG            IMAGE ID       CREATED          SIZE
#card-system-api                           1.0            54ff5ec80263   2 minutes ago    339MB
#card-system-api_santander-front-vue       latest         52cc5668f840   16 minutes ago   311MB
#card-system-api_santander-front-react     latest         6ac7e1422cd3   17 minutes ago   275MB
#card-system-api_santander-front-angular   latest         6cd4ffaf92e1   18 minutes ago   590MB
#amazoncorretto                            11-alpine      4cdaeff01d65   3 months ago     281MB
#mongo                                     7.0            35c7eda371cc   6 months ago     834MB
#dpage/pgadmin4                            latest         37917e5f3734   7 months ago     543MB
#postgres                                  14-alpine      9645962c46cd   9 months ago     272MB
#node                                      18-alpine      ee77c6cd7c18   10 months ago    127MB
#nginx                                     latest         97662d24417b   12 months ago    192MB
#phpmyadmin/phpmyadmin                     latest         0276a66ce322   12 months ago    571MB
#mysql                                     8.0            6616596982ed   12 months ago    764MB
#mongo-express                             latest         870141b735e7   23 months ago    182MB
#grafana/grafana                           10.1.5         00a157ed8c1f   2 years ago      392MB
#prom/prometheus                           v2.47.1        8f13e28dee2b   2 years ago      245MB
#node                                      18.16-alpine   f85482183a4f   2 years ago      175MB


#Categoria,Tamanho Somado
#Suas Aplicações (API + Frontends),1.515 MB (1.51 GB)
#"Bancos de Dados (Mongo, Postgres, MySQL)",1.870 MB (1.87 GB)
#Ferramentas de Gerenciamento & Infra,1.535 MB (1.53 GB)
#"Imagens Base & Runtimes (Node, Corretto)",864 MB
#📊 TOTAL GERAL,5.784 MB (~5.78 GB)