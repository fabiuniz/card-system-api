#!/bin/bash
clear
mkdir -p aiops/ollama
echo "🤖 [SRE Córtex] Iniciando instalação da IA Preditiva ..."

# 1. CRIANDO ESTRUTURA DE DIRETÓRIOS


# 2. GERANDO O AGENTE PREDITIVO (Python + LangChain + RAG)
cat <<EOF > aiops/ollama/dashboard.py
import streamlit as st
import requests
import pandas as pd
import platform
import psutil
import os
import subprocess
os.environ['TRANSFORMERS_OFFLINE'] = "1"
os.environ['HF_DATASETS_OFFLINE'] = "1"
st.set_page_config(page_title="SRE Córtex", layout="wide")
st.title("🤖 SRE Córtex - Painel Preditivo")
def get_gpu_info():
    try:
        # Tenta NVIDIA
        gpu_raw = subprocess.check_output("nvidia-smi --query-gpu=name --format=csv,noheader", shell=True).decode()
        return gpu_raw.strip(), "Aceleração CUDA (GTX 760)"
    except:
        try:
            # Tenta AMD (Verifica se o dispositivo de render existe)
            if os.path.exists("/dev/dri/renderD128"):
                return "AMD Radeon RX 580 8GB", "Aceleração ROCm (Polaris)"
        except:
            pass
    return "Executando em CPU", "Modo Xeon (AVX2)"
gpu_label, motor = get_gpu_info()
# Sidebar com Status do Hardware REAL da Máquina
st.sidebar.header("📡 Status da Infra Local")
# Detecta Processador e Threads
# No dashboard.py, procure a parte do cpu_info e substitua por:
def get_detailed_cpu():
    try:
        # Tenta ler diretamente do sistema de arquivos do Linux (mais preciso no WSL)
        with open("/proc/cpuinfo", "r") as f:
            for line in f:
                if "model name" in line:
                    return line.split(":")[1].strip()
    except:
        return platform.processor()
cpu_model = get_detailed_cpu()
# Exibe no Sidebar sem cortes bruscos
st.sidebar.subheader("💻 Processador")
st.sidebar.info(f"{cpu_model}")
st.sidebar.write(f"**Threads:** {os.cpu_count()} | **Arquitetura:** {platform.machine()}")
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
    with st.spinner('Consultando base de conhecimento técnica...'):
        # 1. Busca no banco vetorial (ChromaDB)
        import predictive_agent_rag as rag
        contexto_recuperado = rag.get_context(user_input)
        
        # 2. Envia para o Ollama com as métricas da tela
        metricas_atuais = f"Latência: 250ms, Erro: 2%"
        resposta = rag.ask_ollama(metricas_atuais, contexto_recuperado, modelo_selecionado)
        
        st.write("### 📢 Insight do Engenheiro SRE:")
        st.info(resposta)
# Tabela de logs do 'Cérebro'
st.subheader("📂 Conhecimento Indexado (RAG Memory)")
if os.path.exists("./brain"):
    arquivos = os.listdir("./brain")
    datas = [
        pd.to_datetime(os.path.getmtime(os.path.join("./brain", f)), unit='s').strftime('%d/%m/%Y %H:%M') 
        for f in arquivos
    ]
    st.table(pd.DataFrame({
        "Fonte de Dados": arquivos,
        "Data de Indexação": datas,
        "Status": ["✅ Ativo" for _ in arquivos]
    }))
else:
    st.write("Nenhum conhecimento extra indexado ainda.")
EOF

# Indexa os manuais iniciais do banco de dados vetorial.
cat <<'EOF' > aiops/ollama/predictive_agent_rag.py
__import__('pysqlite3')
import sys
sys.modules['sqlite3'] = sys.modules.pop('pysqlite3')
import requests
import os
from langchain_community.vectorstores import Chroma
from langchain_community.embeddings import HuggingFaceEmbeddings

OLLAMA_URL = "http://ollama-server:11434/api/generate"

# Tentativa com caminho garantido pelo volume do Docker
MODEL_PATH = "/app/aiops/ollama/models/all-MiniLM-L6-v2"

embeddings = HuggingFaceEmbeddings(
    model_name=MODEL_PATH,
    model_kwargs={'device': 'cpu'}
)

def get_context(query):
    db_path = "/app/vector_db"
    if os.path.exists(db_path):
        vector_db = Chroma(persist_directory=db_path, embedding_function=embeddings)
        results = vector_db.similarity_search(query, k=3)
        return "\n".join([res.page_content for res in results])
    return "AVISO: O MANUAL TÉCNICO NÃO FOI ENCONTRADO!"

def ask_ollama(metrics, context, question, model="llama3:8b-instruct-q4_0"):
    system_instruction = (
        "Você é o SRE CÓRTEX. Ignore biologia. Foque em TI."
    )
    full_prompt = f"{system_instruction}\nCONTEXTO: {context}\nMETRICAS: {metrics}\nPERGUNTA: {question}"
    
    payload = {
        "model": model,
        "prompt": full_prompt,
        "stream": False,
        "options": {"num_gpu": 5}
    }
    
    try:
        res = requests.post(OLLAMA_URL, json=payload, timeout=300)
        return res.json()['response']
    except Exception as e:
        return f"Erro: {str(e)}"
EOF

cat <<'EOF' > aiops/ollama/chroma_manager.py
__import__('pysqlite3')
import sys
sys.modules['sqlite3'] = sys.modules.pop('pysqlite3')
import os
from langchain_community.vectorstores import Chroma
from langchain_community.embeddings import HuggingFaceEmbeddings

# Caminhos internos do container
DB_PATH = "/app/aiops/ollama/vector_db"
MODEL_PATH = "/app/aiops/ollama/models/all-MiniLM-L6-v2"

embeddings = HuggingFaceEmbeddings(
    model_name=MODEL_PATH,
    model_kwargs={'device': 'cpu'}
)

def get_context(query):
    if os.path.exists(DB_PATH):
        try:
            vector_db = Chroma(persist_directory=DB_PATH, embedding_function=embeddings)
            results = vector_db.similarity_search(query, k=3)
            return "\n".join([res.page_content for res in results])
        except Exception as e:
            return f"Erro ao acessar banco vetorial: {str(e)}"
    return "AVISO: Banco de dados vetorial não encontrado!"
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
embeddings = HuggingFaceEmbeddings(model_name="./models/all-MiniLM-L6-v2")
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
# 1. Instala dependências e o 'findutils' completo
RUN apt-get update && apt-get install -y \\
    build-essential \\
    python3-dev \\
    gcc \\
    findutils \\
    && rm -rf /var/lib/apt/lists/*
# 2. Copia requisitos
COPY requirements.txt .
# 3. O PULO DO GATO (Versão Blindada):
# Usamos \\\$ para o shell do host não tentar resolver a variável antes da hora.
# Adicionamos 'file://' para o PIP não ignorar os diretórios.
RUN --mount=type=bind,source=pip_cache,target=/app/pip_cache \
    export FIND_LINKS=$(find /app/pip_cache -name "*.whl" -printf "%h\n" | sort -u | tr '\n' ' ') && \
    pip install --no-index --find-links="$FIND_LINKS" -r requirements.txt || \\
    (echo "⚠️ Falha no modo offline, tentando fallback..." && pip install \$FIND_LINKS -r requirements.txt)
# 4. Copia o restante
COPY . .
CMD ["streamlit", "run", "dashboard.py", "--server.port=8501", "--server.address=0.0.0.0"]
EOF

cat <<EOF > .dockerignore
ollama_data/
vector_db/
brain/
*.tar
EOF

# GERANDO O DOCKER-COMPOSE OTIMIZADO PARA AMD RX 580
cat <<EOF > aiops/ollama/docker-compose_rx580.yml
services:
  ollama-server:
    image: ollama/ollama:rocm
    container_name: ollama-server
    restart: always
    ports:
      - "11434:11434"
    volumes:
      - /home/userlnx/docker/ollama_data:/root/.ollama
    environment:
      - HSA_OVERRIDE_GFX_VERSION=8.0.3
      - HCC_AMDGPU_TARGET=gfx803
      - OLLAMA_DEBUG=1
    devices:
      - "/dev/kfd:/dev/kfd"
      - "/dev/dri:/dev/dri"
  ai-agent:
    build:
      context: .
      dockerfile: Dockerfile.ai
    image: ollama-ai-agent:v1.0-gold
    container_name: ai-agent
    pull_policy: never
    environment:
      # Ajustado para o padrão que a maioria das libs python usa
      - OLLAMA_HOST=ollama-server
      - OLLAMA_BASE_URL=http://ollama-server:11434
      # Adicionado para o Dashboard também "ver" a GPU corretamente
      - HSA_OVERRIDE_GFX_VERSION=8.0.3
    depends_on:
      - ollama-server
    ports:
      - "8501:8501"
    volumes:
      - .:/app
      - "/mnt/y/Virtual Machines/VirtualPc/vmlinux_d/_plugins/bin_pip:/app/pip_cache"
    devices:
      - "/dev/kfd:/dev/kfd"
      - "/dev/dri:/dev/dri"
EOF

# 6. GERANDO O DOCKER-COMPOSE OTIMIZADO (VERSÃO CPU-STABLE) #latest # 0.1.32 #0.17.4 #0.1.32
cat <<EOF > aiops/ollama/docker-compose_gtx760.yml
version: '3'
services:
  ollama-server:
    image: ollama/ollama:0.17.4
    container_name: ollama-server
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - OLLAMA_MAX_VRAM=1500000000
    restart: always
    ports:
      - "11434:11434"
    volumes:
      - /home/userlnx/docker/ollama_data:/root/.ollama
    deploy:
      resources:
        limits:
          cpus: '6.0'        # Limita a 50% do seu Xeon (6 de 12 threads)
          memory: 8G         # Limita a 8GB de RAM
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

  ai-agent:
    image: ollama-ai-agent:v1.0-gold
    container_name: ai-agent
    pull_policy: never
    # AJUSTE 1: Define a pasta onde o dashboard.py realmente está
    working_dir: /app/aiops/ollama
    environment:
      - OLLAMA_URL=http://ollama-server:11434/api/generate
      - PYTHONUNBUFFERED=1
    # AJUSTE 2: Comando aponta para o arquivo no local correto
    entrypoint: ["streamlit", "run", "dashboard.py", "--server.port=8501", "--server.address=0.0.0.0"]
    depends_on:
      - ollama-server
    ports:
      - "8501:8501"
    volumes:
      - /home/userlnx/docker/script_docker/card-system-api:/app
    deploy:
      resources:
        limits:
          cpus: '2.0'        # O agente de IA não precisa de muito
          memory: 4G
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
EOF

# 6. GERANDO O DOCKER-COMPOSE OTIMIZADO (VERSÃO CPU-STABLE)
cat <<EOF > aiops/ollama/docker-compose_cpu.yml
version: '3'
services:
  ollama-server:
    image: ollama/ollama:0.17.4
    container_name: ollama-server
    restart: always
    ports:
      - "11434:11434"
    volumes:
      - /home/userlnx/docker/ollama_data:/root/.ollama
    environment:
      - OLLAMA_HOST=0.0.0.0
      - OLLAMA_LLM_LIBRARY=cpu    # FORÇA o modo CPU logo na largada
      - OLLAMA_NUM_PARALLEL=1
    deploy:
      resources:
        limits:
          cpus: '6.0'        # Limita a 50% do seu Xeon (6 de 12 threads)
          memory: 8G         # Limita a 8GB de RAM

  ai-agent:
    image: ollama-ai-agent:v1.0-gold
    container_name: ai-agent
    pull_policy: never
    # IMPORTANTE: O Dashboard.py está dentro de aiops/ollama/
    working_dir: /app/aiops/ollama
    environment:
      - OLLAMA_HOST=ollama-server
      - OLLAMA_BASE_URL=http://ollama-server:11434
    entrypoint: ["streamlit", "run", "dashboard.py", "--server.port=8501", "--server.address=0.0.0.0"]
    depends_on:
      - ollama-server
    ports:
      - "8501:8501"
    volumes:
      # Mapeia a raiz do projeto para o /app do container
      - /home/userlnx/docker/script_docker/card-system-api:/app
    deploy:
      resources:
        limits:
          cpus: '2.0'        # O agente de IA não precisa de muito
          memory: 4G
EOF

echo "--------------------------------------------------------"
echo "✅ TUDO PRONTO! O Cérebro RAG foi configurado."
echo "1. Subir Infra (Escolha uma opção)"
echo " - 1 Só CPU 'docker compose -f aiops/ollama/docker-compose_cpu.yml up -d'"
echo " - 2 RX580 'docker compose -f aiops/ollama/docker-compose_rx580.yml up -d' ."
echo " - 3 GTX760 'docker compose -f aiops/ollama/docker-compose_gtx760.yml up -d --force-recreate' ."
echo " - 4 Assistente 'cd aiops/ollama && ./setup_ia.sh' ."
echo "2. Gerenciar Modelos (Recomendado: phi3:mini)"
echo " - 1 Baixe o modelo: 'docker exec -it ollama-server ollama run llama3'"
echo " - 2 Baixe o modelo: 'docker exec -it ollama-server ollama run phi3:mini'"
echo " - 3 Baixe o modelo: 'docker exec -it ollama-server ollama run llama3:8b-instruct-q4_0'"
echo "3. Popular Conhecimento (RAG)"
echo ' - 1 Exe: ./aiops/ollama/add_knowledge.sh "$(cat README.md)"'
echo ' - 2 Limpar Cérebro: ./aiops/ollama/clear_knowledge.sh'
echo ' - 3 Configurar serviço: ./aiops/ollama/cfg_service.sh'
echo ' - 4 Configurar serviço: ./aiops/ollama/check_infra.sh'
echo " - 5 Forçar Reindexação: docker exec -it ai-agent python3 aiops/ollama/reindex_brain.py"
echo " - 6 Teste chroma_manager.py: "
echo ""
echo 'docker exec -it ai-agent python3 -c "'
echo "import sys"
echo "sys.path.append('/app/aiops/ollama')"
echo "from chroma_manager import get_context"
echo "# Testa se ele encontra algo sobre o banco de dados no seu README"
echo "print('\n🔍 Buscando no banco vetorial...')"
echo "resultado = get_context('quais bancos de dados o sistema usa?')"
echo "print('\n📖 Conteúdo encontrado:')"
echo "print(resultado)"
echo '"'
echo " - 7 Teste predictive_agent_rag.py: "
echo ""
echo " docker exec -it ai-agent python3 -c "
echo "import sys"
echo "sys.path.append('/app/aiops/ollama')"
echo "from chroma_manager import get_context"
echo "from predictive_agent_rag import ask_ollama"
echo "pergunta = 'Qual a base da arquitetura deste sistema?'"
echo "contexto = get_context(pergunta)"
echo "print('\n📖 [CONTEÚDO DO README]:')"
echo "print(contexto)"
echo "print('\n🤖 [RESPOSTA DO XEON]:')"
echo "print(ask_ollama([], contexto, pergunta, model='tinyllama'))"
echo '"'


echo "--------------------------------------------------------"
echo "🌐 Dashboard disponível em: http://localhost:8501"
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
# 1. Construir a imagem obrigatoriamente (o --build garante que o pysqlite3 seja instalado)
echo "📦 Construindo imagem do Agente (Garante a instalação das dependências)..."
# Ativa o BuildKit para a sessão atual
export DOCKER_BUILDKIT=1
# Agora roda o build sem o --mount falhar
DOCKER_BUILDKIT=1 docker build -t ollama-ai-agent:v1.0-gold -f Dockerfile.ai .
usermod -aG docker $USER
echo "✅ AMBIENTE PREPARADO!"
cd "$(dirname "$(readlink -f "$0")")"
# 2. Detecção de Hardwar
echo "------------------------------------------------"
echo "🖥️  DETECÇÃO DE HARDWARE SRE CÓRTEX"
echo "1) NVIDIA GTX 760 (Legacy CUDA)"
echo "2) AMD RX 580 (ROCm Polaris)"
echo "3) APENAS CPU (Modo Xeon Estável - Sem GPU)"
echo "------------------------------------------------"
read -p "Selecione o hardware para aceleração: " hardware
# 3. Subida inteligente (apenas uma vez)
# SUBIDA DOS CONTAINERS (Interativo)
if [ "$hardware" == "1" ]; then
    echo "🚀 Ativando aceleração NVIDIA..."
    export OLLAMA_MAX_VRAM=1600000000
    docker compose -f docker-compose_gtx760.yml up -d 
elif [ "$hardware" == "2" ]; then
    echo "🚀 Ativando aceleração AMD (ROCm)..."
    # Adicionando a remoção de containers órfãos para evitar o erro de porta ocupada
    docker compose -f docker-compose_rx580.yml down --remove-orphans
    docker compose -f docker-compose_rx580.yml up -d
    docker logs ollama-server --tail 20 | grep -E "gpu|vram|compute"
else
    echo "🚀 Iniciando em MODO CPU (Sem aceleração gráfica)..."
    docker compose -f docker-compose_cpu.yml up -d
fi
# 9. VERIFICAÇÃO DO MOTOR OLLAMA
echo "⏳ Aguardando o motor Ollama iniciar (Xeon Mode)..."
for i in {1..20}; do
    if docker exec ollama-server ollama list >/dev/null 2>&1; then
        echo "✅ Motor Ollama Online!"
        break
    fi
    echo "..."
    sleep 2
done
# 10. MODELO PHI3 (Verificação inteligente)
echo "🧠 Verificando modelo Phi-3..."
if docker exec ollama-server ollama list | grep -q "phi3"; then
    echo "✅ Modelo Phi-3 detectado. Pulando download para poupar dados."
else
    echo "📥 Baixando Phi-3 (Apenas se necessário)..."
    docker exec -it ollama-server ollama pull phi3:mini
fi
lsmod | grep amdgpu || echo "⚠️ Alerta: Driver amdgpu não detectado no kernel!"
echo "✅ IA RODANDO!"
WSL_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1); 
WSL_IP=$(hostname);
echo "--------------------------------------------------------"
echo "🚀 DASHBOARD SRE CÓRTEX: http://$WSL_IP:8501"
echo "--------------------------------------------------------"
EOF
chmod +x aiops/ollama/setup_ia.sh

# Prepara o sistema e o Docker para suportar a NVIDIA Legacy
cat <<'EOF' > aiops/ollama/setup_nvidia.sh
#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
echo -e "${GREEN}🛠️ Preparando suporte GPU (Driver 550) para o sistema...${NC}"
# 1. Validação do Driver
if ! nvidia-smi &> /dev/null; then
    echo -e "${RED}❌ Driver NVIDIA não detectado. Certifique-se de ter reiniciado após a instalação.${NC}"
    exit 1
fi
# 2. Toolkit do Docker (Adicionada verificação de repositório se necessário)
echo "📦 Instalando/Verificando NVIDIA Container Toolkit..."
# Nota: Como você já tem o repositório da NVIDIA nas suas listas de 'apt', o comando abaixo deve fluir bem.
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
# 3. Configuração de Runtime
echo "⚙️ Configurando NVIDIA como Runtime padrão do Docker..."
sudo nvidia-ctk runtime configure --runtime=docker --set-as-default
# 4. Ajuste de Compatibilidade para Kernels Novos e Placas Antigas
# No Debian 13/Kernel 6.12, o cgroups v2 é padrão. 
# O ajuste abaixo garante que o toolkit não tente isolar recursos de forma que a placa falhe.
if [ -f /etc/nvidia-container-runtime/config.toml ]; then
    echo "🔧 Ajustando config.toml para o Kernel 6.12 e Cgroups v2..."
    sudo sed -i 's/no-cgroups = false/no-cgroups = true/g' /etc/nvidia-container-runtime/config.toml
    # Adicional: desativa o modo debug para performance
    sudo sed -i 's/debug = .*/debug = false/g' /etc/nvidia-container-runtime/config.toml
fi
# 5. Correção de permissões (DICA EXTRA!)
# Às vezes, o Docker precisa de permissão explícita para acessar os nós da NVIDIA em /dev
echo "🛡️ Ajustando permissões de dispositivos de vídeo..."
sudo chmod 666 /dev/nvidia* || true
# 6. Atualizando cache de bibliotecas
echo "🔗 Atualizando cache de bibliotecas (ldconfig)..."
sudo ldconfig
# 7. Reinício do Serviço
echo "🔄 Reiniciando o Docker para aplicar as configurações..."
sudo systemctl restart docker
echo -e "${GREEN}✅ Hardware preparado! O Docker agora suporta sua GPU com Driver 550.${NC}"
echo -e "Dica: Teste com 'docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu22.04 nvidia-smi'"
EOF
chmod +x aiops/ollama/setup_nvidia.sh

# Ele vai instalar o Toolkit da RX 580 no Debian para o Docker
# Script de Setup para GPU AMD (RX 580) no Debian/WSL
cat <<'EOF' > aiops/ollama/setup_amd.sh
#!/bin/bash
GREEN='\033[0;32m'
NC='\033[0m'
echo -e "${GREEN}🚀 Preparando Kernel para RX 580 (MODO ROCm)...${NC}"
# 1. Instala dependências de renderização AMD
usermod -aG video $USER
usermod -aG render $USER
apt-get update && apt-get install -y libnuma-dev libdrm-amdgpu1 mesa-va-drivers clinfo
# 2. Permissões de hardware
usermod -aG video $USER
usermod -aG render $USER
# 3. Patch para arquitetura Polaris (RX 580)
if ! grep -q "HSA_OVERRIDE_GFX_VERSION" /etc/environment; then
    echo "HSA_OVERRIDE_GFX_VERSION=8.0.3" | tee -a /etc/environment
fi
# 4. Sobe o container específico
cd "$(dirname "$0")"
docker-compose -f docker-compose_rx580.yml up -d
echo -e "${GREEN}✅ RX 580 Ativada! Verifique com: docker logs ollama-server${NC}"
EOF
chmod +x aiops/ollama/setup_amd.sh
# Rodar logo após o setup da NVIDIA. Ele garante que, se a GTX 760 falhar por ser antiga, o Docker use o modo "runc" estável para o Xeon não travar.
cat <<'EOF' > aiops/ollama/setup_AVX.sh
# --- AJUSTE DE SEGURANÇA: RESET DO RUNTIME ---
# Remove a tentativa do Docker de usar a GPU Kepler que falhou no NVML
if [ -f /etc/docker/daemon.json ]; then
    echo "⚙️ Resetando Docker Runtime para 'runc' (Segurança para Hardware Legacy)..."
    sed -i 's/"default-runtime": "nvidia"//g' /etc/docker/daemon.json
    # Remove vírgulas extras que podem sobrar no JSON
    sed -i 's/{ ,/{ /g' /etc/docker/daemon.json
    systemctl restart docker
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
echo "Escolha o Hardware:"
echo "1) NVIDIA GTX 760 (CUDA)"
echo "2) AMD RX 580 (ROCm)"
read -p "Opção: " hardware
if [ "\$hardware" == "1" ]; then
    export OLLAMA_MAX_VRAM=1600000000
    docker-compose -f docker-compose_gtx760.yml up -d --force-recreate
    echo "Subindo modo NVIDIA..."
else
    docker-compose -f docker-compose_rx580.yml up -d
    echo "Subindo modo AMD..."
fi
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
#   "prompt": "SRE Córtex, você está online na rede?",
#   "stream": false
# }'
EOF
chmod +x aiops/ollama/cfg_service.sh

# Passo 4: Alimentação e Validação
cat <<'EOF' > aiops/ollama/clear_knowledge.sh
#!/bin/bash
echo "🗑️ Iniciando limpeza do cérebro do Agente Córtex..."
# 1. Limpa os arquivos físicos (O que o Dashboard lê)
rm -rf ./aiops/ollama/brain/*.md
echo "✅ Arquivos de memória física removidos."
# 2. Parar o container para evitar corrupção de arquivos
echo "🛑 Parando ai-agent..."
docker stop ai-agent >/dev/null 2>&1
# 3. Remover a pasta do banco vetorial
if [ -d "./vector_db" ]; then
    echo "📂 Removendo banco de dados vetorial (vector_db)..."
    rm -rf ./vector_db
    echo "✅ Banco de dados removido com sucesso."
else
    echo "ℹ️  O banco de dados vetorial já estava limpo."
fi
# 3. Reiniciar o container
echo "🚀 Reiniciando ai-agent..."
docker start ai-agent >/dev/null 2>&1
echo "------------------------------------------------"
echo "✨ Cérebro resetado! O Agente agora está puro."
echo "💡 Próximo passo: Rode ./add_knowledge.sh para indexar o README correto."
echo "------------------------------------------------"
EOF
chmod +x aiops/ollama/clear_knowledge.sh
# ------------------------------------------------------------------------------------
# Use para adicionar qualquer regra específica que foi passada.
cat <<'EOF' > aiops/ollama/add_knowledge.sh
#!/bin/bash
# Define o caminho absoluto baseado na localização do script
BASE_DIR=$(dirname "$(readlink -f "$0")")
BRAIN_DIR="$BASE_DIR/brain"
if [ -z "$1" ]; then
    echo "Uso: ./add_knowledge.sh 'Minha instrução para a IA'"
    exit 1
fi
# 1. Garante a pasta no local correto
mkdir -p "$BRAIN_DIR"
chmod 777 "$BRAIN_DIR"
# 2. Gera o arquivo
FILENAME="memo_$(date +%s).md"
echo "$1" > "$BRAIN_DIR/$FILENAME"
echo "📝 Arquivo $FILENAME criado em $BRAIN_DIR"
# 3. Sincroniza
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
    apt update
    apt install lm-sensors htop
    echo -e "\n\033[1;34m--- [REPORT DE HARDWARE: SRE CÓRTEX] ---\033[0m"
    echo "Data do Registro: $(date '+%d/%m/%Y %H:%M:%S')"
    # CPU Identification
    echo -ne "Modelo CPU: "
    if command -v lscpu > /dev/null; then
        # Pega o nome comercial completo do Xeon
        CPU_FULL=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
        echo -e "\033[1;32m$CPU_FULL\033[0m"
    else
        echo -e "\033[1;31mNão foi possível identificar via lscpu\033[0m"
    fi

    # Threads e Cores
    CORES=$(nproc)
    echo "Threads lógicas disponíveis: $CORES"
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
    echo "watch -n 1 sensors"
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
#docker exec -it ollama-server ollama run tinyllama "SRE Córtex, analise: Latência subiu para 500ms no cluster. O que fazer?"

## Libera a porta no firewall do Windows (Local)
#New-NetFirewallRule -DisplayName "SRE-Cortex" -Direction Inbound -LocalPort 8501 -Protocol TCP -Action Allow
# Redireciona o tráfego do localhost para o WSL
#netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=8501 connectaddress=127.0.0.1 connectport=8501

#Minha internet é 100 GB de franquina poupe meus recursos
# wsl -d Debian_FBI -u userlnx
# winpty wsl.exe -d Debian_FBI -u userlnx
# ip a | grep inet
# cd "/mnt/y/Virtual Machines/card-system-api"

# root@pc-linux:/home/userlnx/docker/script_docker/card-system-api/aiops/ollama# docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
#Thu Apr 30 18:28:24 2026
#+-----------------------------------------------------------------------------+
#| NVIDIA-SMI 470.256.02   Driver Version: 470.256.02   CUDA Version: 12.4     |
#|-------------------------------+----------------------+----------------------+
#| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
#| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
#|                               |                      |               MIG M. |
#|===============================+======================+======================|
#|   0  NVIDIA GeForce ...  Off  | 00000000:03:00.0 N/A |                  N/A |
#| 47%   42C    P0    N/A /  N/A |      0MiB /  1998MiB |     N/A      Default |
#|                               |                      |                  N/A |
#+-------------------------------+----------------------+----------------------+
#
#+-----------------------------------------------------------------------------+
#| Processes:                                                                  |
#|  GPU   GI   CI        PID   Type   Process name                  GPU Memory |
#|        ID   ID                                                   Usage      |
#|=============================================================================|
#|  No running processes found                                                 |
#+-----------------------------------------------------------------------------+
#root@pc-linux:/home/userlnx/docker/script_docker/card-system-api/aiops/ollama#

## Remove a placa do barramento
#echo 1 | tee /sys/bus/pci/devices/0000:03:00.0/remove
#sleep 2
# Força o kernel a re-escannear o barramento
#echo 1 | tee /sys/bus/pci/rescan


#Córtex, com base nos últimos documentos que foram indexados no seu cérebro via RAG, quais são os principais tópicos técnicos abordados sobre este projeto?
#Córtex, quais são as 3 camadas da Arquitetura Hexagonal deste projeto e qual imagem Docker base é usada para o Java?
#Córtex, Qual a base da arquitetura deste sistema e qual imagem Docker ele usa para o Java?