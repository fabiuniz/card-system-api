#!/bin/bash

echo "🤖 [SRE Córtex] Iniciando instalação da IA Preditiva Santander..."

# 1. CRIANDO ESTRUTURA DE DIRETÓRIOS


# 2. GERANDO O AGENTE PREDITIVO (Python + LangChain + RAG)
cat <<'EOF' > aiops/predictive_agent_rag.py
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
cat <<'EOF' > aiops/reindex_brain.py
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
cat <<EOF > aiops/Dockerfile.ai
FROM python:3.9-slim
WORKDIR /app
RUN pip install requests prometheus-api-client langchain langchain-community chromadb sentence-transformers
COPY . .
CMD ["python", "predictive_agent_rag.py"]
EOF

# 5. GERANDO O UTILITÁRIO add_knowledge.sh
cat <<'EOF' > add_knowledge.sh
#!/bin/bash
if [ -z "$1" ]; then
    echo "Uso: ./add_knowledge.sh 'Minha instrução para a IA'"
    exit 1
fi
echo "$1" > aiops/brain/memo_$(date +%s).md
docker exec -it ai-agent python3 reindex_brain.py
echo "✅ IA atualizada!"
EOF
chmod +x add_knowledge.sh

echo "--------------------------------------------------------"
echo "✅ TUDO PRONTO! O Cérebro RAG foi configurado."
echo "1. Execute 'docker-compose up -d' para subir a IA."
echo "2. Baixe o modelo: 'docker exec -it ollama-server ollama run llama3'"
echo "3. Use './add_knowledge.sh' para afinar o agente em tempo real."
echo "--------------------------------------------------------"


#Máquina A (A "Poderosa" com RX 580):
#Ollama + Llama 3 (RAG): Essa GPU AMD aguenta o modelo de 8 bilhões de parâmetros.
#Banco de Vetores (ChromaDB): Onde fica o conhecimento.
#Grafana/Prometheus: O centro de controle.
#Máquina B (A "Estável" com GTX 760):
#API Java (Spring Boot): Rodando o core business.
#Os 3 Bancos de Dados (MySQL, Postgres, Mongo): Usando os 16GB de RAM para cache.
#Os 3 Front-ends: Servindo as interfaces.