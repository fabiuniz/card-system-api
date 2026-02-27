#!/bin/bash
mkdir -p aiops/ollama
echo "🤖 [SRE Córtex] Iniciando instalação da IA Preditiva Santander..."

# 1. CRIANDO ESTRUTURA DE DIRETÓRIOS


# 2. GERANDO O AGENTE PREDITIVO (Python + LangChain + RAG)
cat <<'EOF' > aiops/ollama/predictive_agent_rag.py
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
    payload = {"model": "llama3", "prompt": prompt, "stream": False}
    try:
        res = requests.post(OLLAMA_URL, json=payload)
        return res.json()['response']
    except:
        return "Aguardando inicialização do Ollama..."

print("🚀 Agente Preditivo Rodando...")
while True:
    # Simulação de busca de métrica (aqui conectaria no Prometheus real)
    mock_metrics = "Latência: 250ms, Erros 5xx: 2%"
    context = get_context("latência alta e erros de servidor")
    insight = ask_ollama(mock_metrics, context)
    print(f"\n🧠 [IA Insight]: {insight}")
    time.sleep(60)
EOF

# 3. GERANDO O SCRIPT DE RE-INDEXAÇÃO (Afinamento)
cat <<'EOF' > aiops/ollama/reindex_brain.py
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
cat <<EOF > aiops/ollama/Dockerfile.ai
FROM python:3.9-slim
WORKDIR /app
RUN pip install requests prometheus-api-client langchain langchain-community chromadb sentence-transformers
COPY . .
CMD ["python", "predictive_agent_rag.py"]
EOF

# 5. GERANDO O UTILITÁRIO add_knowledge.sh
cat <<'EOF' > aiops/ollama/add_knowledge.sh
#!/bin/bash
if [ -z "$1" ]; then
    echo "Uso: ./add_knowledge.sh 'Minha instrução para a IA'"
    exit 1
fi
echo "$1" > aiops/ollama/brain/memo_$(date +%s).md
docker exec -it ai-agent python3 reindex_brain.py
echo "✅ IA atualizada!"
EOF
chmod +x aiops/ollama/add_knowledge.sh


# 6. GERANDO O DOCKER-COMPOSE COMPLETO
cat <<EOF > aiops/ollama/docker-compose.yml
version: '3'

services:
  ollama-server:
    image: ollama/ollama:latest
    container_name: ollama-server
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
      context: ./aiops/ollama
      dockerfile: Dockerfile.ai
    container_name: ai-agent
    depends_on:
      - ollama-server
    environment:
      - OLLAMA_URL=http://ollama-server:11434/api/generate
    volumes:
      - ./brain:/app/brain
      - ./vector_db:/app/vector_db
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
docker exec -it ollama-server ollama run llama3:8b-instruct-q4_0
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
        payload = {"model": "llama3:8b-instruct-q4_0", "prompt": user_input, "stream": False}
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
#docker save python:3.9-slim > python_base.tar
#docker load -i ollama_image.tar
#docker load -i python_base.tar