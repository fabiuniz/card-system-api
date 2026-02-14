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
