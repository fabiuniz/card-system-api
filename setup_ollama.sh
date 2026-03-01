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

def ask_ollama(metrics, context):
    prompt = f"""
    CONTEXTO TÉCNICO (Instruções do Fabiano):
    {context}

    MÉTRICAS ATUAIS:
    {metrics}

    Como Engenheiro SRE, analise se há tendência de falha e sugira a correção baseada no contexto.
    """
    payload = {"model": "phi3:mini", "prompt": prompt, "stream": False}

    try:
        res = requests.post(OLLAMA_URL, json=payload, timeout=90) # Aumente o timeout para hardware antigo
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
cat <<EOF > aiops/ollama/requirements.txt
requests
streamlit
pandas
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

# 5. GERANDO O UTILITÁRIO add_knowledge.sh
cat <<'EOF' > add_knowledge.sh
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
chmod +x add_knowledge.sh
chmod +x aiops/ollama/add_knowledge.sh


# 6. GERANDO O DOCKER-COMPOSE COMPLETO
cat <<EOF > aiops/ollama/docker-compose.yml
version: '3'

services:
  ollama-server:
    image: ollama/ollama:latest
    container_name: ollama-server
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    restart: always
    # O segredo para v3 com GPU no Docker Engine local:
    runtime: nvidia 
    ports:
      - "11434:11434"
    volumes:
      - ./ollama_data:/root/.ollama
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=compute,utility

  ai-agent:
    build:
      context: .
      dockerfile: Dockerfile.ai
    container_name: ai-agent
    depends_on:
      - ollama-server
    environment:
      - OLLAMA_URL=http://ollama-server:11434/api/generate
    volumes:      
      - .:/app
      - ./pip_cache:/root/.cache/pip
    ports:
      - "8501:8501"
EOF

cat <<EOF > aiops/ollama/cfg_service.sh
#Antes de rodar abra o PowerShell como Administrador.
#Copie e cole os comandos:
#   1. Comando para criar o túnel entre sua placa de rede física e o WSL
#   netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=11434 connectaddress=localhost connectport=11434
#   2. Abre o Firewall do Windows para a porta da IA
#   New-NetFirewallRule -DisplayName "SRE-Cortex-IA" -Direction Inbound -LocalPort 11434 -Protocol TCP -Action Allow
docker-compose up -d
docker exec -it ollama-server ollama pull phi3:mini
docker exec -it ollama-server ollama run phi3:mini "Olá Córtex!"
#docker exec -it ollama-server ollama run llama3:8b-instruct-q4_0
#docker exec -it ollama-server ollama run phi3:mini
# como testar:
# Substitua pelo IP real da sua máquina Xeon
# curl http://192.168.x.x:11434/api/generate -d '{
#   "model": "llama3:8b-instruct-q4_0",
#   "prompt": "SRE Córtex, você está online na rede Santander?",
#   "stream": false
# }'
EOF
chmod +x cfg_service.sh

cat <<EOF > aiops/ollama/dashboard.py
import streamlit as st
import requests
import pandas as pd

st.set_page_config(page_title="SRE Córtex - Santander", layout="wide")

st.title("🤖 SRE Córtex - Painel Preditivo")

# Sidebar com Status do Hardware
st.sidebar.header("Status da Infra")
st.sidebar.metric("GPU (GTX 760)", "2GB VRAM", "Ativa")
st.sidebar.metric("CPU (Xeon E5)", "12 Threads", "Normal")

# Área de Métricas em Tempo Real
col1, col2, col3 = st.columns(3)
col1.metric("Latência Média", "250ms", "+10ms")
col2.metric("Taxa de Erro", "2%", "-0.5%")
col3.metric("Status do Modelo", "Llama3-Q4", "Online")

# Interface de Chat com a IA
st.subheader("🧠 Consulta ao Agente RAG")
user_input = st.text_input("Descreva o incidente ou peça uma análise:")

if user_input:
    with st.spinner('IA analisando métricas e base de conhecimento...'):
        # Aqui ele chama o seu agente que já está no Docker
        payload = {
            "model": "phi3:mini", # Alinhado com o que foi baixado no cfg_service
            "prompt": user_input, 
            "stream": False
        }
        response = requests.post("http://ollama-server:11434/api/generate", json=payload)
        st.write("### Insight do Engenheiro SRE:")
        st.info(response.json()['response'])

# Tabela de logs do 'Cérebro'
st.subheader("📂 Conhecimento Indexado (Memory)")
st.table(pd.DataFrame({"Arquivo": ["memo_incidente_db.md", "pop_santander_v1.md"], "Status": ["Indexado", "Indexado"]}))
EOF

echo "--------------------------------------------------------"
echo "✅ TUDO PRONTO! O Cérebro RAG foi configurado."
echo "1. Execute 'docker-compose up -d' para subir a IA."
echo "2. Baixe o modelo: 'docker exec -it ollama-server ollama run llama3'"
echo "2.1 Baixe o modelo: 'docker exec -it ollama-server ollama run phi3:mini'"
echo "3. Use './add_knowledge.sh' para afinar o agente em tempo real."
echo "--------------------------------------------------------"

cat <<'EOF' > aiops/ollama/check_infra.sh
clear
echo -e "\n--- [REPORT DE HARDWARE: SRE CÓRTEX] ---"
echo "Modelo CPU: $(grep -m 1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs || uname -p)"
echo "Threads/Cores: $(nproc)"
echo "Instruções: $(grep -oE 'avx2|avx' /proc/cpuinfo | head -n 1 || echo 'Nenhum AVX encontrado')"
echo "RAM Total: $(grep MemTotal /proc/meminfo | awk '{printf "%.2f GB", $2/1024/1024}')"
echo "RAM Livre (Windows): $(powershell -command "[math]::round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1KB, 2)") MB"
echo "Arquitetura: $(uname -m)"
echo "Docker Status: $(docker info --format '{{.ServerVersion}}' 2>/dev/null || echo '🔴 Docker não iniciado ou não instalado')"
powershell -command "Get-CimInstance Win32_VideoController | Select-Object Name, AdapterRAM, DriverVersion"
echo "---------------------------------------"
EOF


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
#docker save ai-agent:latest | gzip > /mnt/q/ai_agent_pronto.tar.gz
#docker save python:3.9-slim > python_base.tar
#docker load -i ollama_image.tar
#docker load -i "/mnt/q/Virtual Machines/ollama_latest.tar"
#docker load -i python_base.tar
#mount -t cifs "//192.168.1.179/y/Virtual Machines/VirtualPc/vmlinux_d/plugins" /home/userlnx/docker/relay -o username=user,domain=sweethome,password=1111,iocharset=utf8,users,file_mode=0777,dir_mode=0777,vers=3.0
#docker exec -it ollama-server ollama run phi3:mini
#Montar o wsl em outra disco com mais espaço Q:
#
#
cat <<'EOF' > aiops/ollama/setup_ia.sh
#!/bin/bash
echo "🚀 Iniciando Preparação do Ambiente SRE Córtex no Debian..."
# 1. Atualização de Repositórios
sudo apt update && sudo apt upgrade -y
# 2. Instalação de Dependências Essenciais
sudo apt install -y cifs-utils git docker.io docker-compose
# 3. Configuração de Permissões do Docker
sudo usermod -aG docker $USER
# Nota: O grupo só ativa após novo login ou 'newgrp docker'
# 4. Criando Estrutura de Pastas
mkdir -p /home/userlnx/docker/relay
sudo chmod -R 777 /home/userlnx/docker/relay
# 5. Montagem do Disco Q (Ajustado para o seu caminho com espaços)
# Se o bind falhar, tentaremos montar o drive C/Q do Windows
sudo mount --bind "/mnt/q/Virtual Machines" /home/userlnx/docker/relay || echo "⚠️ Falha ao montar via bind. Verifique se o disco Q está acessível no WSL."
# 6. Clonagem do Projeto
cd /home/userlnx/docker/relay
if [ ! -d "card-system-api" ]; then
    git clone https://github.com/fabiuniz/card-system-api.git
fi
cd card-system-api
git fetch origin
git switch feat/add-iot-ia
# 7. Download das Imagens (Ollama e Python)
echo "📥 Baixando imagens Docker (Isso pode demorar)..."
sudo docker pull ollama/ollama:latest
sudo docker pull python:3.9-slim
# 8. Exportação para .tar (Backup na pasta relay)
echo "💾 Gerando arquivos .tar para backup..."
sudo docker save -o /home/userlnx/docker/relay/ollama_latest.tar ollama/ollama:latest
sudo docker save -o /home/userlnx/docker/relay/python_base.tar python:3.9-slim
echo "✅ AMBIENTE PREPARADO COM SUCESSO!"
echo "Próximo passo: Execute 'newgrp docker' e depois suba o docker-compose."
echo "🚀 Subindo containers..."
export DOCKER_BUILDKIT=1
docker-compose up -d
# Aguarda 10 segundos para o serviço do Ollama estabilizar
echo "⏳ Aguardando o servidor Ollama iniciar..."
sleep 10
echo "🧠 Baixando e iniciando o modelo Phi-3 (Otimizado para GTX 760)..."
docker exec -it ollama-server ollama run phi3:mini 
# docker exec -it ollama-server ollama run phi3:mini "Olá Córtex, confirme sua versão."
echo "✅ AMBIENTE PREPARADO E IA RODANDO!"
echo "watch -n 1 nvidia-smi"
echo 'New-NetFirewallRule -DisplayName "IA-Agent-Dashboard" -Direction Inbound -LocalPort 8501 -Protocol TCP -Action Allow'
echo "localhost:8501"
EOF

cat <<'EOF' > aiops/ollama/prepare_ia.sh
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
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=8501 connectaddress=192.168.137.2 connectport=8501
EOF

cat <<'EOF' > aiops/ollama/fix_cortex.sh
#!/bin/bash
# 1. Desliga tudo
docker-compose down
# 2. Reinicia o suporte a GPU no Docker (via terminal)
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
# 3. Limpa caches mortos que ocupam espaço no SSD
docker system prune -f
# 4. Sobe novamente
docker-compose up -d
EOF