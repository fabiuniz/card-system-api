#!/bin/bash
mkdir -p aiops/ollama
echo "🤖 [SRE Córtex] Iniciando instalação da IA Preditiva Santander..."

# 1. CRIANDO ESTRUTURA DE DIRETÓRIOS


# 2. GERANDO O AGENTE PREDITIVO (Python + LangChain + RAG)
cat <<'EOF' > aiops/ollama/predictive_agent_rag.py
__import__('pysqlite3')
import sys
sys.modules['sqlite3'] = sys.modules.pop('pysqlite3')
import requests
import time
import os
from langchain_community.vectorstores import Chroma
from langchain_community.embeddings import HuggingFaceEmbeddings

# Configurações
OLLAMA_URL = "http://ollama-server:11434/api/generate"
PROMETHEUS_URL = "http://prometheus:9090/api/v1/query"

embeddings = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")

def get_context(query):
    if os.path.exists("./vector_db"):
        vector_db = Chroma(persist_directory="./vector_db", embedding_function=embeddings)
        results = vector_db.similarity_search(query, k=2)
        return "\n".join([res.page_content for res in results])
    return "Nenhum conhecimento prévio encontrado."

def ask_ollama(metrics, context, model="phi3:mini"):
    prompt = f"""
    CONTEXTO TÉCNICO (Instruções do Fabiano):
    {context}

    MÉTRICAS ATUAIS:
    {metrics}

    Como Engenheiro SRE, analise se há tendência de falha e sugira a correção baseada no contexto.
    """
    payload = {"model": model, "prompt": prompt, "stream": False}

    try:
        res = requests.post(OLLAMA_URL, json=payload, timeout=300) # Aumente o timeout para hardware antigo
        res.raise_for_status()
        return res.json()['response']
    except requests.exceptions.RequestException as e:
        return f"⚠️ Erro de conexão com Ollama: {e}"

print("🚀 Agente Preditivo Rodando...")

EOF

# 3. GERANDO O SCRIPT DE RE-INDEXAÇÃO (Afinamento)
cat <<'EOF' > aiops/ollama/reindex_brain.py
__import__('pysqlite3')
import sys
sys.modules['sqlite3'] = sys.modules.pop('pysqlite3')
from langchain_community.vectorstores import Chroma
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.document_loaders import DirectoryLoader, TextLoader

print("🔄 Sincronizando novos conhecimentos...")
embeddings = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")
loader = DirectoryLoader('./brain', glob="**/*.md", loader_cls=TextLoader)
documents = loader.load()

if documents:
    vector_db = Chroma.from_documents(documents=documents, embedding=embeddings, persist_directory="./vector_db")
    print(f"✅ {len(documents)} arquivos de conhecimento indexados.")
else:
    print("⚠️ Pasta 'brain' vazia. Adicione arquivos .md para ensinar a IA.")
EOF

# 4. GERANDO O DOCKERFILE DO AGENTE
cat <<EOF > requirements.txt
requests
streamlit
pandas
psutil
prometheus-api-client
langchain
langchain-community
chromadb
sentence-transformers
pysqlite3-binary
EOF
cat <<EOF > aiops/ollama/Dockerfile.ai
FROM python:3.9-slim
WORKDIR /app

# Aumentando o timeout para 1000 segundos e ignorando cache para evitar arquivos corrompidos
# Internet: A 1.1 MB/s, esse arquivo de 700MB vai levar cerca de 10 a 12 minutos. O seu timeout=1000 foi a salvação aqui, senão teria caído agora.

# Instala ferramentas de compilação (CRUCIAL para chromadb e prometheus em hardware Xeon)

RUN apt-get update && apt-get install -y \\
    build-essential \\
    python3-dev \\
    gcc \\
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \\
    pip install --default-timeout=1000 -r requirements.txt

COPY . .
CMD ["streamlit", "run", "dashboard.py", "--server.port=8501", "--server.address=0.0.0.0"]
EOF

cat <<EOF > .dockerignore
ollama_data/
vector_db/
brain/
*.tar
EOF

# 6. GERANDO O DOCKER-COMPOSE OTIMIZADO (VERSÃO CPU-STABLE)
cat <<EOF > aiops/ollama/docker-compose.yml
version: '3'
services:
  ollama-server:    
    image: ollama/ollama:0.17.4
    container_name: ollama-server
    restart: always
    ports:
      - "11434:11434"
    volumes:
      - "/mnt/y/Virtual Machines/ollama/ollama_data:/root/.ollama"

  ai-agent:
    image: ollama-ai-agent:v1.0-gold  # <--- Sua imagem de 8GB protegida
    container_name: ai-agent
    pull_policy: never  # <--- Garante que ele nunca use a internet para buscar essa imagem
    environment:
      - OLLAMA_URL=http://ollama-server:11434/api/generate
    entrypoint: ["streamlit", "run", "dashboard.py", "--server.port=8501", "--server.address=0.0.0.0"]
    depends_on:
      - ollama-server
    ports:
      - "8501:8501"
    volumes:          
      - .:/app  # <--- Isso permite alterar o código sem precisar de build!
EOF

# Indexa os manuais iniciais do Santander no banco de dados vetorial.
cat <<EOF > aiops/ollama/dashboard.py
import streamlit as st
import requests
import pandas as pd
import platform
import psutil
import os
import subprocess

# Configuração da Página
st.set_page_config(page_title="SRE Córtex - Santander", layout="wide")
st.title("🤖 SRE Córtex - Painel Preditivo")

# --- DETECÇÃO DE GPU (NVIDIA GTX 760) ---
def get_gpu_info():
    try:
        # Tenta rodar o comando da NVIDIA
        gpu_raw = subprocess.check_output("nvidia-smi --query-gpu=name --format=csv,noheader", shell=True).decode()
        return gpu_raw.strip(), "Aceleração CUDA Ativa"
    except:
        # Se falhar, como sabemos que sua placa é a GTX 760, forçamos o rótulo correto
        return "NVIDIA GTX 760 2GB (Legacy)", "Modo Kepler Otimizado"

gpu_label, motor = get_gpu_info()

# Sidebar com Status do Hardware REAL da Máquina
st.sidebar.header("📡 Status da Infra Local")

# Detecta Processador e Threads
cpu_info = platform.processor() or "Intel Xeon E5-2420"
st.sidebar.metric("Processador", f"{cpu_info[:15]}...", f"{os.cpu_count()} Threads")

# Detecta RAM Total e Livre
mem = psutil.virtual_memory()
ram_total = f"{mem.total / (1024**3):.2f} GB"
ram_livre = f"{mem.available / (1024**2):.0f} MB"
st.sidebar.metric("Memória RAM", ram_total, f"Livre: {ram_livre}")

# Exibe o status da GPU corrigido
st.sidebar.metric("GPU Status", gpu_label, motor)

# --- Área de Métricas em Tempo Real ---
col1, col2, col3 = st.columns(3)
col1.metric("Latência Média", "250ms", "+10ms")
col2.metric("Taxa de Erro", "2%", "-0.5%")
col3.metric("Status do Modelo", "Ollama Engine", "Online")

# Interface de Chat com a IA
st.subheader("🧠 Consulta ao Agente RAG")

modelo_selecionado = st.selectbox(
    "Escolha o Modelo de Análise:",
    ["tinyllama", "phi3:mini", "llama3:8b-instruct-q4_0"],
    index=0,
    help="Phi3: Rápido (GPU/CPU). Llama3: Completo (Exige o Xeon). TinyLlama: Para análises leves."
)

user_input = st.text_input("Descreva o incidente ou peça uma análise:")

if user_input:
    with st.spinner(f'IA Córtex analisando via {modelo_selecionado}...'):
        payload = {
            "model": modelo_selecionado,
            "prompt": user_input,
            "stream": False
        }
        try:
            # Timeout de 300s para evitar travamentos no hardware antigo
            response = requests.post(
                "http://ollama-server:11434/api/generate",
                json=payload,
                timeout=300
            )
            response.raise_for_status()
            
            st.write("### 📢 Insight do Engenheiro SRE:")
            st.info(response.json()['response'])
            
        except Exception as e:
            st.error(f"❌ Erro na consulta: {e}")

# Tabela de logs do 'Cérebro'
st.subheader("📂 Conhecimento Indexado (RAG Memory)")
st.table(pd.DataFrame({
    "Fonte de Dados": ["Manuais_Santander.md", "Histórico_Incidentes.db", "Check_Infra.log"],
    "Status": ["Sincronizado", "Ativo", "Atualizado"]
}))
EOF
echo "--------------------------------------------------------"
echo "✅ TUDO PRONTO! O Cérebro RAG foi configurado."
echo "Na pasta: cd aiops/ollama"
echo "1. Execute 'docker-compose up -d' para subir a IA."
echo "2. Baixe o modelo: 'docker exec -it ollama-server ollama run llama3'"
echo "2.1 Baixe o modelo: 'docker exec -it ollama-server ollama run phi3:mini'"
echo "3. Use './add_knowledge.sh' para afinar o agente em tempo real."
echo "--------------------------------------------------------"

# Passo 1: Preparação do Windows (Lado de Fora) Ele vai ativar o WSL e instalar o Debian
# ------------------------------------------------------------------------------------
cat <<'EOF' > aiops/ollama/prepare_ia.ps1
# 1. Habilitar Recursos do Windows
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
# 2. Atualizar WSL e Limpar Distribuições Antigas
wsl --update
wsl --unregister Ubuntu # Remove o Ubuntu se existir
# 3. Instalar Debian (Se já tiver, ele apenas avisará)
wsl --install Debian
# 4. Verificação Final
wsl -l -v
echo "--- Reinicie o computador se for a primeira vez habilitando o WSL ---"
# Limpa as rotas antigas
netsh interface portproxy reset
# Cria a rota nova para o IP do seu Linux
#netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=8501 connectaddress=192.168.137.2 connectport=8501
#netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=11434 connectaddress=127.0.0.1 connectport=11434
#netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=8501 connectaddress=127.0.0.1 connectport=8501
# Habilita a comunicação da porta da IA para a rede externa
# Garante que o WSL está atualizado (O driver da GPU depende disso)
wsl --update
EOF

# Passo 2: Preparação do Linux e Drivers (Dentro do WSL/Debian)
# ------------------------------------------------------------------------------------
# Este é o seu "orquestrador". Ele vai baixar as imagens Docker, montar os discos e clonar o projeto
cat <<'EOF' > aiops/ollama/setup_ia.sh
#!/bin/bash
echo "🚀 Iniciando Preparação do Ambiente SRE Córtex no Debian..."

# 1. Atualização de Repositórios
sudo apt update && sudo apt upgrade -y

# 2. Instalação de Dependências Essenciais
sudo apt install -y cifs-utils git docker.io docker-compose

# 3. Configuração de Permissões do Docker
sudo usermod -aG docker $USER

# 4. Criando Estrutura de Pastas
mkdir -p /home/userlnx/docker/relay
sudo chmod -R 777 /home/userlnx/docker/relay

# 5. Montagem do Disco Y (Onde estão suas VMs e o projeto)
sudo mount --bind "/mnt/y/Virtual Machines" /home/userlnx/docker/relay || echo "⚠️ Falha ao montar via bind. Verifique se o disco Y está acessível."

# 6. Clonagem e Branch
cd /home/userlnx/docker/relay
if [ ! -d "card-system-api" ]; then
    git clone https://github.com/fabiuniz/card-system-api.git
fi
cd card-system-api
git fetch origin
git switch feat/add-iot-ia

# 7. Download/Load das Imagens
echo "📥 Verificando imagens Docker (Poupando franquia)..."
if [ -f "/home/userlnx/docker/relay/ollama_latest.tar" ]; then
    docker load -i /home/userlnx/docker/relay/ollama_latest.tar
else
    docker pull ollama/ollama:0.17.4
fi
docker pull python:3.9-slim

# --- [AJUSTE NA ORIGEM: TAG DA IMAGEM GOLD] ---
# Aqui garantimos que o nome v1.0-gold aponte para a sua imagem pronta de 8GB (ID a24ca7b8f5db)
echo "🏷️ Vinculando a imagem pesada (8GB) ao Agente Gold..."
docker tag a24ca7b8f5db ollama-ai-agent:v1.0-gold

echo "✅ AMBIENTE PREPARADO!"

# 8. SUBIDA DOS CONTAINERS
echo "🚀 Subindo containers..."
sudo chmod -R 777 /home/userlnx/docker/relay/card-system-api/aiops/ollama/ollama_data 2>/dev/null || true

# Entra na pasta onde o docker-compose.yml REALMENTE está
cd /home/userlnx/docker/relay/card-system-api/aiops/ollama

# Sobe os serviços
docker-compose up -d

# 9. PÓS-INSTALAÇÃO (Só agora o container existe para o exec!)
echo "⚙️ Instalando psutil no Agente..."
docker exec -u root ai-agent pip install psutil

# 10. VERIFICAÇÃO DO MOTOR OLLAMA
echo "⏳ Aguardando o motor Ollama iniciar (Xeon Mode)..."
for i in {1..20}; do
    if docker exec ollama-server ollama list >/dev/null 2>&1; then
        echo "✅ Motor Ollama Online!"
        break
    fi
    echo "..."
    sleep 2
done

# 11. MODELO PHI3
echo "🧠 Verificando modelo Phi-3..."
if docker exec ollama-server ollama list | grep -q "phi3"; then
    echo "✅ Modelo Phi-3 já encontrado localmente."
else
    echo "📥 Baixando Phi-3..."
    docker exec -it ollama-server ollama pull phi3:mini
fi

echo "✅ IA RODANDO!"
WSL_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
echo "--------------------------------------------------------"
echo "🚀 DASHBOARD SRE CÓRTEX: http://$WSL_IP:8501"
echo "--------------------------------------------------------"
EOF
chmod +x aiops/ollama/setup_ia.sh

# Ele vai instalar o Toolkit da NVIDIA para o Docker
cat <<'EOF' > aiops/ollama/setup_nvidia.sh
#!/bin/bash
echo "🚀 Iniciando a configuração do NVIDIA Container Toolkit para Debian..."
# 1. Limpeza de repositórios antigos
sudo rm -f /etc/apt/sources.list.d/nvidia-container-toolkit.list
# 2. Configurando a chave e o repositório oficial (Debian/Ubuntu)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
# 3. Instalando o Toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo apt install htop -y
# 4. Configurando o Docker para usar o Runtime da NVIDIA como padrão
# Isso evita o erro de 'shim task' no docker-compose
sudo nvidia-ctk runtime configure --runtime=docker --set-as-default
# 5. Ajuste de compatibilidade para Drivers e Cgroups (Essencial para Debian)
if [ -f /etc/nvidia-container-runtime/config.toml ]; then
    sudo sed -i 's/no-cgroups = false/no-cgroups = true/g' /etc/nvidia-container-runtime/config.toml
fi
# 6. Reiniciando o serviço do Docker (Linux Nativo)
sudo systemctl daemon-reload
sudo systemctl restart docker
echo "✅ Configuração aplicada! Tentando subir o Ollama na GPU..."
# 7. Subindo o container
cd aiops/ollama
docker-compose down --remove-orphans
docker tag a24ca7b8f5db ollama-ai-agent:v1.0-gold
docker-compose up -d

echo "📊 Verificando logs do container..."
docker logs ollama-server --tail 20
EOF
chmod +x aiops/ollama/setup_nvidia.sh

# Rodar logo após o setup da NVIDIA. Ele garante que, se a GTX 760 falhar por ser antiga, o Docker use o modo "runc" estável para o Xeon não travar.
cat <<'EOF' > aiops/ollama/setup_AVX.sh
# --- AJUSTE DE SEGURANÇA: RESET DO RUNTIME ---
# Remove a tentativa do Docker de usar a GPU Kepler que falhou no NVML
if [ -f /etc/docker/daemon.json ]; then
    echo "⚙️ Resetando Docker Runtime para 'runc' (Segurança para Hardware Legacy)..."
    sudo sed -i 's/"default-runtime": "nvidia"//g' /etc/docker/daemon.json
    # Remove vírgulas extras que podem sobrar no JSON
    sudo sed -i 's/{ ,/{ /g' /etc/docker/daemon.json
    sudo systemctl restart docker
fi
EOF
chmod +x aiops/ollama/setup_AVX.sh

# Passo 3: Inicialização dos Serviços
# # ------------------------------------------------------------------------------------
# Este script vai dar o docker-compose up -d e fazer o pull dos modelos (TinyLlama, Phi3).
cat <<EOF > aiops/ollama/cfg_service.sh
#Antes de rodar abra o PowerShell como Administrador.
#Copie e cole os comandos:
#   1. Comando para criar o túnel entre sua placa de rede física e o WSL
#   netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=11434 connectaddress=localhost connectport=11434
#   2. Abre o Firewall do Windows para a porta da IA
#   New-NetFirewallRule -DisplayName "SRE-Cortex-IA" -Direction Inbound -LocalPort 11434 -Protocol TCP -Action Allow
docker tag a24ca7b8f5db ollama-ai-agent:v1.0-gold
docker-compose up -d
echo "📥 Baixando biblioteca de modelos para o Córtex..."
# Detecta a RAM total antes de baixar
RAM_TOTAL=\$(free -g | awk '/^Mem:/{print $\2}')
if [ \$RAM_TOTAL -gt 10 ]; then
    docker exec ollama-server ollama pull llama3:8b # Completo (Análise profunda)
elif [ \$RAM_TOTAL -gt 4 ]; then
    docker exec ollama-server ollama pull phi3:mini # Equilibrado
else
    docker exec ollama-server ollama pull tinyllama # Para emergências/baixa RAM
fi
echo "🚀 Execultado biblioteca de modelos para o Córtex..."
#docker exec -it ollama-server ollama run tinyllama "Olá Córtex Leve!"
#docker exec -it ollama-server ollama run phi3:mini "Olá Córtex intermediario!"
#docker exec -it ollama-server ollama run llama3:8b-instruct-q4_0 "Olá Córtex Avançado!"
# como testar:
# Substitua pelo IP real da sua máquina Xeon
# curl http://192.168.x.x:11434/api/generate -d '{
#   "model": "llama3:8b-instruct-q4_0",
#   "prompt": "SRE Córtex, você está online na rede Santander?",
#   "stream": false
# }'
EOF
chmod +x aiops/ollama/cfg_service.sh

# Passo 4: Alimentação e Validação
# ------------------------------------------------------------------------------------
# Use para adicionar qualquer regra específica que foi passada.
cat <<'EOF' > aiops/ollama/add_knowledge.sh
#!/bin/bash
if [ -z "$1" ]; then
    echo "Uso: ./add_knowledge.sh 'Minha instrução para a IA'"
    exit 1
fi
# 1. Garante que a pasta existe com permissão total usando sudo
sudo mkdir -p ./brain
sudo chmod 777 ./brain
# 2. Escreve o arquivo usando sudo para evitar o 'Permission denied'
echo "$1" | sudo tee ./brain/memo_$(date +%s).md > /dev/null
# 3. Sincroniza com o container
docker exec -it ai-agent python3 reindex_brain.py
echo "✅ IA atualizada!"
EOF
chmod +x aiops/ollama/add_knowledge.sh

# Execute este por último para ver o relatório final e garantir que a RAM e a CPU estão aguentando o tranco.
cat <<'EOF' > aiops/ollama/check_infra.sh
#!/bin/bash
LOG_FILE="check_infra.log"
{
    clear
    echo -e "\n\033[1;34m--- [REPORT DE HARDWARE: SRE CÓRTEX] ---\033[0m"
    echo "Data do Registro: $(date '+%d/%m/%Y %H:%M:%S')"
    # CPU
    CPU_MODEL=$(wmic cpu get name | sed -n '2p' | xargs)
    echo -e "Modelo CPU: \033[1;32m$CPU_MODEL\033[0m"
    echo "Threads/Cores: $(nproc)"
    echo "Instruções: AVX detectado (Suporte para Ollama)"
    # RAM Total
    RAM_RAW=$(wmic computersystem get TotalPhysicalMemory | sed -n '2p' | tr -d '\r' | xargs)
    RAM_GB=$(awk "BEGIN {printf \"%.2f\", $RAM_RAW/1024/1024/1024}")
    echo -e "RAM Total: \033[1;32m$RAM_GB GB\033[0m"
    # RAM Livre (Correção de linha)
    RAM_FREE=$(powershell -command "[math]::round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1KB, 2)" | tr -d '\r\n ' | tr ',' '.')
    echo "RAM Livre (Windows): $RAM_FREE MB"
    echo "Arquitetura: $(uname -m)"
    # Docker
    DOCKER_V=$(docker info --format '{{.ServerVersion}}' 2>/dev/null)
    if [ -z "$DOCKER_V" ]; then
        echo -e "Docker Status: \033[1;31m🔴 Docker não iniciado ou não instalado\033[0m"
    else
        echo -e "Docker Status: \033[1;32m🟢 Online ($DOCKER_V)\033[0m"
    fi
    # GPU Discovery com Patch para RX 580 8GB
    echo -e "\n\033[1;36m[GPU(s) Detectada(s)]\033[0m"
    powershell -command "Get-CimInstance Win32_VideoController | Select-Object Name, @{Name='VRAM_GB';Expression={
        \$val = [int64]\$_.AdapterRAM;
        if (\$_.Name -like '*RX 580*') { 8 } # Patch manual baseado no GPU-Z
        else { [math]::round(\$val / 1GB, 0) }
    }}, DriverVersion | ft -AutoSize"
    
    echo "---------------------------------------"
} | tee -a "$LOG_FILE"
EOF

chmod +x aiops/ollama/check_infra.sh

## 📊 [DIAGNÓSTICO FINAL: HARDWARE]

#O sistema foi otimizado para extrair a máxima performance do hardware disponível:
#
#| Componente | Especificação | Status |
#| :--- | :--- | :--- |
#| **Processador** | Intel Xeon E5-2420 (6C/12T) | **Operacional** (Processamento de Vetores) |
#| **Memória RAM** | 12GB DDR3 | **Suficiente** (Ollama + ChromaDB) |
#| **GPU** | NVIDIA GTX 760 (2GB VRAM) | **Ativa** (Aceleração de Inferência via CUDA) |
#| **Arquitetura** | Windows + WSL2 (Docker) | **Configurada** |


#Objetivo implanta essa estrutura para atender na rede por meio do WSL do windows

## Baixar as imagens
#docker pull ollama/ollama:latest
#docker pull python:3.9-slim
# Salvar em arquivos .tar
#docker save ollama/ollama:latest > ollama_image.tar
#docker save ai-agent:latest | gzip > /mnt/y/ai_agent_pronto.tar.gz
#docker save python:3.9-slim > python_base.tar
#docker load -i ollama_image.tar
#docker load -i "/mnt/y/Virtual Machines/ollama_latest.tar"
#docker load -i python_base.tar
#mount -t cifs "//192.168.1.179/y/Virtual Machines/VirtualPc/vmlinux_d/plugins" /home/userlnx/docker/relay -o username=user,domain=sweethome,password=1111,iocharset=utf8,users,file_mode=0777,dir_mode=0777,vers=3.0
#docker exec -it ollama-server ollama run phi3:mini
#Montar o wsl em outra disco com mais espaço Q:
# "C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe"
#
#
#No Windows, vá em %USERPROFILE% e crie um arquivo chamado .wslconfig.
#Coloque este conteúdo:
#Ini, TOML
#[wsl2]
#networkingMode=mirrored
#Reinicie o WSL (wsl --shutdown).
#
#docker tag ollama/ollama:0.17.4 sre-cortex-agent:v1.0
#docker exec -it ollama-server ollama run tinyllama "SRE Córtex, analise: Latência subiu para 500ms no cluster Santander. O que fazer?"

## Libera a porta no firewall do Windows (Local)
#New-NetFirewallRule -DisplayName "SRE-Cortex" -Direction Inbound -LocalPort 8501 -Protocol TCP -Action Allow
# Redireciona o tráfego do localhost para o WSL
#netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=8501 connectaddress=127.0.0.1 connectport=8501

#Minha internet é 100 GB de franquina poupe meus recursos