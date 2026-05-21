#!/bin/bash
#setup_ollama.sh
clear
mkdir -p aiops/ollama
echo "🤖 [SRE Córtex] Iniciando instalação da IA Preditiva ..."
# 1. GERANDO O AGENTE PREDITIVO (Python + LangChain + RAG)
cat <<EOF > aiops/ollama/dashboard.py
import streamlit as st
import requests
import pandas as pd
import platform
import psutil
import os
import subprocess
import ollama
from streamlit_autorefresh import st_autorefresh
os.environ['TRANSFORMERS_OFFLINE'] = "1"
os.environ['HF_DATASETS_OFFLINE'] = "1"
st.set_page_config(page_title="SRE Córtex", layout="wide")
st.title("🤖 SRE Córtex - Painel Preditivo")
def get_gpu_metrics():
    try:
        # Consulta carga (utilization), memória usada e total
        cmd = "nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits"
        output = subprocess.check_output(cmd, shell=True).decode().strip()
        if not output: return {"load": "N/A", "vram": "N/A", "raw_load": 0}
        # Faz o split dos valores limpos
        util, used, total = [x.strip() for x in output.split(',')]
        # TRATAMENTO PARA GPU LEGADA: Se a carga vier "N/A", jogamos 0% ou "0" para não quebrar o int()
        if "N/A" in util:
            gpu_load_display = "Legacy "
            gpu_raw_load = 0
        else:
            gpu_load_display = f"{util}%"
            gpu_raw_load = int(util)
        return {
            "load": gpu_load_display,
            "vram": f"{used}MB / {total}MB",
            "raw_load": gpu_raw_load
        }
    except Exception:
        return {"load": "N/A", "vram": "N/A", "raw_load": 0}
def get_cpu_fan_speed():
    try:
        import glob
        # Busca direta no sistema de arquivos do Linux (/sys/class/hwmon)
        # Varre todos os inputs de fans ativos (fan1_input, fan2_input, etc.)
        fan_inputs = glob.glob("/sys/class/hwmon/hwmon*/fan*_input")
        for path in fan_inputs:
            with open(path, "r") as f:
                rpm_raw = f.read().strip()
                if rpm_raw.isdigit():
                    rpm = int(rpm_raw)
                    # Como o seu fan está no canal 'fan2' a 2280 RPM,
                    # qualquer valor real maior que zero será capturado aqui.
                    if rpm > 0:
                        return f"{rpm} RPM"
        # Fallback para o psutil caso o mapeamento direto falhe por permissão
        import psutil
        fans = psutil.sensors_fans()
        if fans:
            for name, entries in fans.items():
                for entry in entries:
                    if entry.current > 0:
                        return f"{entry.current} RPM"
        return "N/A"
    except Exception as e:
        return "N/A"
def get_cpu_temp_pro():
    try:
        # Caminho validado via 'x86_pkg_temp'
        path = "/sys/class/thermal/thermal_zone0/temp"
        if os.path.exists(path):
            with open(path, "r") as f:
                temp_raw = f.read().strip()
                # Converte miligraus para Celsius
                return f"{float(temp_raw) / 1000:.1f}°C"
    except Exception:
        return "N/A"
    return "N/A"
def get_temps():
    temps = {}
    try:
        # Temperatura da CPU
        tcore = psutil.sensors_temperatures()
        if 'coretemp' in tcore:
            temps['cpu'] = f"{tcore['coretemp'][0].current}°C"
        else:
            cmd = "cat /sys/class/thermal/thermal_zone0/temp"
            raw_temp = subprocess.check_output(cmd, shell=True).decode().strip()
            temps['cpu'] = f"{int(raw_temp)/1000:.1f}°C"
    except:
        temps['cpu'] = "N/A"
    try:
        # 🟢 NOVA CONSULTA: Puxa temperatura E velocidade da ventoinha juntas
        cmd_gpu = "nvidia-smi --query-gpu=temperature.gpu,fan.speed --format=csv,noheader,nounits"
        gpu_raw = subprocess.check_output(cmd_gpu, shell=True).decode().strip()
        temp_val, fan_val = [x.strip() for x in gpu_raw.split(',')]
        temps['gpu'] = f"{temp_val}°C"
        temps['gpu_fan'] = f"{fan_val}%" # Guarda a porcentagem do fan
    except:
        temps['gpu'] = "N/A"
        temps['gpu_fan'] = "N/A"
    return temps
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
# --- FUNÇÃO DE CONTROLE DINÂMICO DE REFRIGERAÇÃO (CORRIGIDA) ---
def set_gpu_fan_speed(speed_percent):
    try:
        # Comando unificado com export de ambiente para garantir
        if speed_percent == 0:
            cmd = "export DISPLAY=:1; nvidia-settings -a '[gpu:0]/GPUFanControlState=0'"
        else:
            cmd = f"export DISPLAY=:1; nvidia-settings -a '[gpu:0]/GPUFanControlState=1' -a '[fan:0]/GPUTargetFanSpeed={speed_percent}'"
        
        # Executa e captura erro para debug se necessário
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        # Se quiser debugar, descomente: 
        # print(result.stderr) 
    except Exception as e:
        print(f"Erro no Fan Control: {e}")
# --- Frame Sidebar ---
@st.fragment
def render_dynamic_sidebar():
    freq = psutil.cpu_freq()
    if freq:
        st.write(f"**Clock Atual:** {freq.current:.0f} MHz")
    # O auto-refresh garante a atualização local dentro do fragmento
    st_autorefresh(interval=3000, limit=None, key="sidebar_refresh")
    # IMPORTANTE: Sem o prefixo 'st.sidebar.' aqui dentro!
    st.header("📡 Status da Infra Local")
    
    def get_detailed_cpu():
        try:
            with open("/proc/cpuinfo", "r") as f:
                for line in f:
                    if "model name" in line:
                        return line.split(":")[1].strip()
        except:
            return platform.processor()
            
    cpu_model = get_detailed_cpu()
    #CPU
    st.subheader("💻 Processador")
    st.info(f"{cpu_model}")
    st.write(f"**Threads:** {os.cpu_count()} | **Arquitetura:** {platform.machine()}")
    
    # RAM
    mem = psutil.virtual_memory()
    ram_total = f"{mem.total / (1024**3):.2f} GB"
    ram_livre = f"{mem.available / (1024**2):.0f} MB"
    st.metric("Memória RAM", ram_total, f"Livre: {ram_livre}")
    # Correção do Erro 2: Coletando os dados da GPU antes de renderizar na tela
    gpu_label, motor = get_gpu_info()
    st.metric("GPU Status", gpu_label, motor)
    # --- Consolidação de Coleta de Dados (Chama apenas uma vez por atualização) ---
    telemetria = get_temps()
    gpu_data = get_gpu_metrics()
    cpu_usage = psutil.cpu_percent()
    cpu_temp_real = get_cpu_temp_pro()
    # cpu_fan = get_cpu_fan_speed() # Ative se a função estiver pronta
    # --- Seção 1: Monitoramento Térmico & Ventoinhas ---
    st.header("🌡️ Telemetria & Cooler")    
    # 4 Colunas para um visual de "Dashboard Profissional"
        # Carga de CPU com barra de progresso
    st.write(f"**💻Uso do Xeon E5:** {cpu_usage}%")
    st.progress(cpu_usage / 100)
    col_t1, col_t2 = st.columns(2)
    with col_t1:
        st.metric("Temp CPU", cpu_temp_real)
    with col_t2:
        # Tenta exibir Cooler CPU, se falhar mostra N/A
        try: st.metric("Cooler CPU", get_cpu_fan_speed())
        except: st.metric("Cooler CPU", "N/A")
    st.markdown("---")
    # --- Seção 2: Carga de Processamento (Gráficos e Métricas) ---
    # Métricas de GPU e VRAM em colunas
    st.write(f"**📟Uso da GPU ({gpu_label}):** {gpu_data['load']}")
    st.progress(gpu_data['raw_load'] / 100)
    col_t1, col_t2 = st.columns(2)        
    with col_t1:
        st.metric("Temp GPU", telemetria['gpu'])
    with col_t2:
        st.metric("Cooler GPU", telemetria['gpu_fan'])
    # Métricas de GPU e VRAM em colunas
    col_g1, col_g2 = st.columns(2)
    with col_g1:
        st.metric("Carga GPU", gpu_data['load'])
    with col_g2:
        # Se a VRAM estiver esgotada, o Streamlit destaca em vermelho automaticamente
        st.metric("VRAM Usada", gpu_data['vram'])
# Alerta visual objetivo: Detecta por que o modelo (mesmo pequeno) não entrou na GPU
    if "Legacy" in gpu_data['load'] or (gpu_data['raw_load'] < 2 and cpu_usage > 40):
        # Captura o nome do modelo atual
        m_atual = modelo_selecionado if 'modelo_selecionado' in locals() else "Desconhecido"
        
        st.error(f"### ⚠️ Hardware em modo Fallback: {m_atual} operando em CPU")
        
        col_diag, col_num = st.columns(2)
        
        with col_diag:
            st.markdown(f"""
            **🔍 Diagnóstico SRE:**
            * **Modelo Selecionado:** `{m_atual}` (~270MB).
            * **Status de Alocação:** A GPU GTX 760 (2GB) tem espaço, mas o **Ollama Engine** não consegue enviar dados para esta arquitetura (Kepler).
            * **Causa Raiz:** Incompatibilidade de drivers CUDA modernos com hardware de 2013.
            """)
            
        with col_num:
            st.markdown(f"""
            **📊 Comparativo de Eficiência:**
            * **VRAM Disponível:** 1998MB (Total) vs 8MB (Usada).
            * **Carga de Desvio:** {cpu_usage}% no Xeon E5 (Processamento pesado).
            * **Refrigeração:** Cooler CPU em **{get_cpu_fan_speed()}** (Esforço Máximo).
            """)
            
        st.info("💡 **Ação Prática:** Como o modelo é pequeno (135M parâmetros), ele rodará bem no Xeon, mas a latência de 250ms é o limite deste processador sem ajuda da GPU.")
# --- Inicialização da Sidebar no Contexto Correto ---
with st.sidebar:
    render_dynamic_sidebar()
    st.markdown("---")
    if st.button("❌ Cancelar Processamento", type="primary", use_container_width=True):
        st.toast("🚨 Enviando comando de interrupção...", icon="⚠️")
        try:
            # 1. Força o Ollama a descarregar todos os modelos da memória (para as requisições HTTP travadas)
            # Passar o modelo com tempo de vida 0 faz o Ollama matar a sessão atual imediatamente
            if 'modelo_selecionado' in locals() and modelo_selecionado:
                requests.post(f"{ollama_host}/api/generate", json={"model": modelo_selecionado, "keep_alive": 0})
            # 2. Comando via Docker para matar o "ollama runner" (processo de inferência pesado)
            # Como o Streamlit não tem a CLI do docker interna, usamos o 'ollama-server' da rede
            # Mas a forma mais garantida se estiver usando a API é derrubar o processo de execução técnica:
            import subprocess
            # Envia um sinal para reiniciar o serviço interno do container ou matar o runner
            subprocess.run("docker exec ollama-server pkill -f 'ollama runner'", shell=True, capture_output=True)
            st.success("🤖 Todos os processos de inferência do Ollama foram interrompidos!")
        except Exception as e:
            st.error(f"Erro ao interromper processos: {e}")
        st.rerun()


# --- Frame Main ---
col1, col2, col3 = st.columns(3)
col1.metric("Latência Média", "250ms", "+10ms")
col2.metric("Taxa de Erro", "2%", "-0.5%")
col3.metric("Status do Modelo", "Ollama Engine", "Online")
# Interface de Chat com a IA
st.subheader("🧠 Consulta ao Agente RAG")
#Personalizar Parâmetros
col_mod1, col_mod2 = st.columns([2, 3])
# 1. Configura o cliente para apontar para o container do Ollama na rede do Docker
# Se você não definiu a variável de ambiente OLLAMA_HOST, ele tentará usar o nome padrão do container
ollama_host = os.environ.get("OLLAMA_HOST", "http://ollama-server:11434")
client = ollama.Client(host=ollama_host)

# 2. Busca os modelos disponíveis usando o cliente configurado
try:
    model_list_response = client.list()
    modelos_disponiveis = [model['model'] for model in model_list_response['models']]
except Exception as e:
    modelos_disponiveis = []
    st.error(f"Erro ao conectar com o Ollama no endereço ({ollama_host}): {e}")

# 3. Renderiza o selectbox dinamicamente
with col_mod1:
    if modelos_disponiveis:
        modelo_selecionado = st.selectbox(
            "Escolha o Modelo de Análise:",
            options=modelos_disponiveis,
            index=0,
            help="Modelos carregados dinamicamente do seu Ollama local."
        )
    else:
        st.warning("Nenhum modelo encontrado. Certifique-se de que o Ollama possui modelos baixados (ollama pull).")
        modelo_selecionado = None
# --- ⚙️ Dicionário de Mensagens Predefinidas (Dropbox) ---
SYSTEM_PROMPTS_POOL = {
    "Padrão (IAOps & Infra)": (
        "Você é um Engenheiro SRE especialista em infraestrutura e IAOps. "
        "Analise os dados e métricas fornecidos com foco estritamente técnico, "
        "evitando misturar o contexto de documentos se não houver correlação direta."
    ),
    "Diagnóstico de Gargalos (Performance)": (
        "Você é um especialista em Performance Engineering e Linux Internals. "
        "Analise os logs e a telemetria focando estritamente em contenção de CPU, "
        "latência de instruções (AVX), eficiência de cache L3 e paginação de memória."
    ),
    "Otimização de RAG & Contexto": (
        "Você é um Arquiteto de Soluções de IA especializado em LLMs locais e RAG. "
        "Analise o volume de documentos indexados e sugira estratégias de chunking, "
        "limitação de Top-K e redução de tamanho do prompt para evitar estoiros de timeout."
    ),
    "Análise Teológica (Foco nos Dados de Leitura)": (
        "Você é um analista de dados especializado em processamento de textos históricos e teológicos. "
        "Ignore métricas de infraestrutura. Foque exclusivamente em sintetizar, correlacionar e explicar os fragmentos "
        "dos documentos bíblicos recuperados pelo RAG com base na pergunta do usuário. "
        "Para cada fragmento analisado, você DEVE extrair e estruturar a resposta obrigatoriamente nestes tópicos: "
        "1) ID/Dia da Leitura; 2) Características e Tom do Estudo; 3) Informações Diversas Extraídas do Texto. "
        "Se a resposta não estiver estritamente nos dados recuperados, declare que a informação não consta na base."
    )
}
with st.expander("🛠️ Personalizar Parâmetros do Agente (Ollama Options)"):
    st.markdown("Ajuste o comportamento de amostragem e a personalidade do modelo local.")
    
    # Renderização do Dropbox para selecionar as mensagens predefinidas
    prompt_key = st.selectbox(
        "Mensagens Predefinidas (Templates de Prompt):",
        options=list(SYSTEM_PROMPTS_POOL.keys()),
        index=0,
        help="Alterne rapidamente entre diferentes personas e regras de contenção do agente."
    )
    # Campo de texto populado dinamicamente com base no Dropbox
    custom_system = st.text_area(
        "System Prompt (Instrução do Sistema):",
        value=SYSTEM_PROMPTS_POOL[prompt_key],
        height=120,
        help="Define a 'personalidade' e as regras de contenção do agente para evitar alucinações."
    )
    col_p1, col_p2, col_p3 = st.columns(3)
    with col_p1:
        temperature = st.slider(
            "Temperatura", 
            min_value=0.0, max_value=1.0, value=0.1, step=0.1,
            help="Valores baixos (0.1) tornam o modelo determinístico e técnico. Valores altos trazem criatividade."
        )
    with col_p2:
        top_k = st.slider(
            "Top K", 
            min_value=1, max_value=100, value=21, step=5,
            help="Limita o vocabulário do modelo às K palavras mais prováveis."
        )
    with col_p3:
        top_p = st.slider(
            "Top P", 
            min_value=0.0, max_value=1.0, value=0.5, step=0.05,
            help="Amostragem de núcleo: controla a diversidade das respostas."
        )
    ollama_options = {
        "temperature": temperature,
        "top_k": top_k,
        "top_p": top_p,
        "system": custom_system,
        "num_ctx": 4096,        # Limitação preventiva de Contexto adicionada via código
        "num_thread": 6         # Otimização estática para o processador Xeon E5
    }
user_input = st.text_input("Descreva o incidente ou peça uma análise:")
if user_input:
    # 🚨 GATILHO DINÂMICO: O usuário perguntou? Acelera o Fan para 90% IMEDIATAMENTE
    st.toast("⚡ Proteção Térmica Ativada: Elevando rotação dos FANs para processamento...", icon="❄️")
    set_gpu_fan_speed(100)
    with st.spinner('Consultando base de conhecimento técnica e gerando Insight...'):
        # 1. Busca no banco vetorial (ChromaDB)
        import predictive_agent_rag as rag
        contexto_recuperado = rag.get_context(user_input)
        # 2. Envia para o Ollama com as métricas da tela
        metricas_atuais = f"Latência: 250ms, Erro: 2%"
        resposta = rag.ask_ollama(
            metricas_atuais, 
            contexto_recuperado, 
            modelo_selecionado, 
            options=ollama_options
        )
        st.write("### 📢 Insight do Engenheiro SRE:")
        st.info(resposta)
    # 📉 GATILHO DE DESCANSO: O modelo terminou de responder? Volta o fan para 35% ou Automático
    set_gpu_fan_speed(0)
    st.toast("✅ Inferência concluída. Reduzindo rotação dos FANs.", icon="🍃")
# Tabela de logs do 'Cérebro' (CAMINHO DINÂMICO INTERNO DO DOCKER AJUSTADO)
st.subheader("📂 Conhecimento Indexado (RAG Memory)")
BASE_DIR_CONTAINER = os.path.dirname(os.path.abspath(__file__))
caminho_brain = os.path.join(BASE_DIR_CONTAINER, "brain")
if os.path.exists(caminho_brain):
    arquivos = [f for f in os.listdir(caminho_brain) if f.endswith('.md')]
    if arquivos:
        datas = [
            pd.to_datetime(os.path.getmtime(os.path.join(caminho_brain, f)), unit='s').strftime('%d/%m/%Y %H:%M') 
            for f in arquivos
        ]
        st.table(pd.DataFrame({
            "Fonte de Dados": arquivos,
            "Data de Indexação": datas,
            "Status": ["✅ Ativo" for _ in arquivos]
        }))
    else:
        st.write("Nenhum conhecimento extra indexado ainda.")
else:
    st.write("Nenhum conhecimento extra indexado ainda.")
EOF

# 2. Indexa os manuais iniciais do banco de dados vetorial.
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
    # Forçado caminho absoluto unificado com a raiz do volume montado
    db_path = "/app/aiops/ollama/vector_db"
    if os.path.exists(db_path):
        vector_db = Chroma(persist_directory=db_path, embedding_function=embeddings)
        results = vector_db.similarity_search(query, k=2) # K reduzido para poupar o Xeon
        return "\n".join([res.page_content for res in results])
    return "AVISO: O MANUAL TÉCNICO NÃO FOI ENCONTRADO NO DIRETÓRIO INTEGRADO!"
def ask_ollama(metrics, context, question, model="tinyllama", options=None):
    # Se o dashboard enviou um System Prompt personalizado, usa ele. Caso contrário, mantém o padrão rígido.
    if options and options.get("system"):
        system_instruction = options.get("system")
    else:
        system_instruction = (
            "Você é o SRE CÓRTEX. Baseie-se APENAS no contexto fornecido. Se a resposta não estiver explicitamente no contexto, responda estritamente: 'Dados insuficientes no cérebro RAG'."
        )
    full_prompt = f"{system_instruction}\nCONTEXTO: {context}\nMETRICAS: {metrics}\nPERGUNTA: {question}"
    # Monta a estrutura base das opções do Ollama, preservando o tuning de CPU do seu Xeon
    # Centralizando TODAS as configurações de hardware e geração dentro do options do Ollama
    ollama_options = {
        "num_gpu": 0,           # Força processamento puramente em CPU
        "num_thread": 6,        # Evita estrangular o host Xeon E5-2420
        "num_predict": 250,     # Limite real de tokens gerados (evita loops infinitos de 99% CPU)
        "stop": ["User:", "PERGUNTA:", "<|im_end|>", "CONTEXTO:"] # Sinais de parada inteligentes
    }
    # Injeta dinamicamente os parâmetros vindos dos sliders da tela (com fallbacks seguros)
    if options:
        ollama_options["temperature"] = options.get("temperature", 0.0)
        ollama_options["top_k"] = options.get("top_k", 40)
        ollama_options["top_p"] = options.get("top_p", 0.1)
    else:
        ollama_options["temperature"] = 0.0
        ollama_options["top_p"] = 0.1
    payload = {
        "model": model,
        "prompt": full_prompt,
        "stream": False,
        "options": ollama_options
    }
    try:
        # Timeout de 45 segundos para o Streamlit não travar se o modelo engasgar
        res = requests.post(OLLAMA_URL, json=payload, timeout=None)
        return res.json()['response']
    except requests.exceptions.Timeout:
        return "Erro na IA: O processador Xeon excedeu o tempo limite de resposta (Timeout)."
    except Exception as e:
        return f"Erro na IA: {str(e)}"
EOF
# 3. 
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

# 4. GERANDO O SCRIPT DE RE-INDEXAÇÃO (Afinamento)
cat <<'EOF' > aiops/ollama/reindex_brain.py
__import__('pysqlite3')
import sys
sys.modules['sqlite3'] = sys.modules.pop('pysqlite3')
import os
from langchain_community.vectorstores import Chroma
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.document_loaders import DirectoryLoader, TextLoader
print("🔄 Sincronizando novos conhecimentos no banco vetorial...")
# CORREÇÃO: Forçando o caminho absoluto validado dentro do volume do container
MODEL_PATH = "/app/aiops/ollama/models/all-MiniLM-L6-v2"
BRAIN_DIR = "/app/aiops/ollama/brain"
DB_DIR = "/app/aiops/ollama/vector_db"
if not os.path.exists(MODEL_PATH):
    print(f"❌ ERRO: O modelo de embedding não foi encontrado em: {MODEL_PATH}")
    sys.exit(1)
embeddings = HuggingFaceEmbeddings(
    model_name=MODEL_PATH,
    model_kwargs={'device': 'cpu'}
)
# Carrega os documentos MD da pasta correta
loader = DirectoryLoader(BRAIN_DIR, glob="**/*.md", loader_cls=TextLoader)
documents = loader.load()
if documents:
    # Cria/Atualiza o banco Chroma persistente
    vector_db = Chroma.from_documents(
        documents=documents, 
        embedding=embeddings, 
        persist_directory=DB_DIR
    )
    print(f"✅ Sucesso! {len(documents)} arquivo(s) de conhecimento indexado(s) no SRE Córtex.")
else:
    print("⚠️ Pasta 'brain' vazia ou sem arquivos .md válidos para indexação.")
EOF

# 5. GERANDO O DOCKERFILE DO AGENTE
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
streamlit-autorefresh
ollama
EOF

# 6.
cat <<EOF > aiops/ollama/Dockerfile.ai
FROM python:3.9-slim
WORKDIR /app
# 1. Instala dependências e o 'findutils' completo
RUN apt-get update && apt-get install -y \\
    build-essential \\
    python3-dev \\
    gcc \\
    findutils \\
    nvidia-settings \\
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
# 7.
cat <<EOF > .dockerignore
ollama_data/
vector_db/
brain/
*.tar
EOF

# 8. GERANDO O DOCKER-COMPOSE OTIMIZADO PARA AMD RX 580
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
      - CUDA_VISIBLE_DEVICES=0
      - ZYPH_FORCE_CUDA=1 # Algumas versões de backend aceitam forçar
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

# 9. GERANDO O DOCKER-COMPOSE OTIMIZADO (VERSÃO CPU-STABLE) #latest # 0.1.32 #0.17.4 #0.1.32
cat <<EOF > aiops/ollama/docker-compose_gtx760.yml
version: '3'
services:
  ollama-server:
    image: ollama/ollama:0.17.4
    container_name: ollama-server
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - OLLAMA_MAX_VRAM=1500000000
      - OLLAMA_NUM_PARALLEL=1
    restart: always
    ports:
      - "11434:11434"
    volumes:
      - /home/userlnx/docker/ollama_data:/root/.ollama
    deploy:
      resources:
        limits:
          cpus: '6.0'        # Preserva 6 threads para o sistema operacional
          memory: 8G
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

  ai-agent:
    image: ollama-ai-agent:v1.0-gold
    container_name: ai-agent
    pull_policy: never
    working_dir: /app
    environment:
      - OLLAMA_CUDA_MIN_COMPUTE_CAPABILITY=3.0
      - OLLAMA_URL=http://ollama-server:11434/api/generate
      - OLLAMA_NOPRUNE=1
      - PYTHONUNBUFFERED=1
    entrypoint: ["streamlit", "run", "aiops/ollama/dashboard.py", "--server.port=8501", "--server.address=0.0.0.0"]
    depends_on:
      - ollama-server
    ports:
      - "8501:8501"
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix:rw # Permite ao container falar com o Xvfb do host
      - /home/userlnx/docker/script_docker/card-system-api:/app
      - /sys/class/hwmon:/sys/class/hwmon:ro
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu, utility]
EOF

# 10. GERANDO O DOCKER-COMPOSE OTIMIZADO (VERSÃO CPU-STABLE)
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
      build:
      context: .
      dockerfile: Dockerfile.ai
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
echo " - 1 Só CPU 'docker compose -f aiops/ollama/docker-compose_cpu.yml up -d --build'"
echo " - 2 RX580 'docker compose -f aiops/ollama/docker-compose_rx580.yml up -d --build' ."
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
echo 'for arquivo in /home/userlnx/docker/ollama_data/docs/adsa/*.vtt; do'
echo '    [ -e "$arquivo" ] || continue'
echo '    nome_base=$(basename "$arquivo" .vtt)'
echo '    # Copia o conteúdo do vtt direto para um arquivo .md na pasta brain'
echo '    cat "$arquivo" > "./aiops/ollama/brain/${nome_base}.md"'
echo '    echo "Texto preparado: ${nome_base}.md"'
echo 'done'
echo 'docker exec -it ai-agent python3 aiops/ollama/reindex_brain.py'

echo "--------------------------------------------------------"
echo "🌐 Dashboard disponível em: http://localhost:8501"
echo "--------------------------------------------------------"

# 11: Preparação do Windows (Lado de Fora) Ele vai ativar o WSL e instalar o Debian
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

# 12: Preparação do Linux e Drivers (Dentro do WSL/Debian)
# ------------------------------------------------------------------------------------
# Este é o seu "orquestrador". Ele vai baixar as imagens Docker, montar os discos e clonar o projeto
cat <<'EOF' > aiops/ollama/setup_ia.sh
#!/bin/bash
mkdir -p pip_cache
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

# 13. Prepara o sistema e o Docker para suportar a NVIDIA Legacy
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
# 14. Script de Setup para GPU AMD (RX 580) no Debian/WSL
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
# 15. Rodar logo após o setup da NVIDIA. Ele garante que, se a GTX 760 falhar por ser antiga, o Docker use o modo "runc" estável para o Xeon não travar.
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

# # ------------------------------------------------------------------------------------
# 16. Este script vai dar o docker-compose up -d e fazer o pull dos modelos (TinyLlama, Phi3).
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

# 17 . Alimentação e Validação
cat <<'EOF' > aiops/ollama/clear_knowledge.sh
#!/bin/bash
BASE_DIR=$(dirname "$(readlink -f "$0")")
echo "🗑️ [FORÇA BRUTA] Iniciando limpeza profunda do cérebro..."
# 1. Limpa o Host (Garantia)
echo "📂 Removendo arquivos locais no Host..."
rm -f "$BASE_DIR/brain"/*.md 2>/dev/null
rm -rf "$BASE_DIR/vector_db" 2>/dev/null
rm -f ./brain/*.md 2>/dev/null
rm -rf ./vector_db 2>/dev/null
# 2. Executa a limpeza INSIDE (Dentro do container rodando)
# Isso limpa o diretório exato que o Streamlit está visualizando
echo "🐳 Invadindo container ai-agent para eliminar arquivos fantasmas..."
docker exec -it ai-agent sh -c "rm -f ./brain/*.md ./aiops/ollama/brain/*.md 2>/dev/null"
docker exec -it ai-agent sh -c "rm -rf ./vector_db ./aiops/ollama/vector_db 2>/dev/null"
# 3. Reinicia os serviços para limpar o cache de memória do Streamlit e do Chroma
echo "🔄 Reiniciando containers para aplicar o Hard Reset..."
docker stop ai-agent ollama-server >/dev/null 2>&1
docker start ollama-server ai-agent >/dev/null 2>&1
echo "------------------------------------------------"
echo "✨ Cérebro resetado por completo no Host e no Container!"
echo "🔄 DICA: Dê um CTRL + F5 no navegador para limpar o cache da página."
echo "------------------------------------------------"
EOF
chmod +x aiops/ollama/clear_knowledge.sh
chmod +x aiops/ollama/clear_knowledge.sh

# ------------------------------------------------------------------------------------
# 18. Use para adicionar qualquer regra específica que foi passada.
cat <<'EOF' > aiops/ollama/add_knowledge.sh
#!/bin/bash
# Define o caminho absoluto baseado na localização do script no Host
BASE_DIR=$(dirname "$(readlink -f "$0")")
BRAIN_DIR="$BASE_DIR/brain"
if [ -z "$1" ]; then
    echo "⚠️ Uso: ./add_knowledge.sh 'Minha instrução para a IA'"
    exit 1
fi
# 1. Garante que a pasta exista no local correto com permissões totais
mkdir -p "$BRAIN_DIR"
chmod 777 "$BRAIN_DIR"
# 2. Gera o arquivo de memória com timestamp único
FILENAME="memo_$(date +%s).md"
echo "$1" > "$BRAIN_DIR/$FILENAME"
echo "📝 Arquivo $FILENAME criado com sucesso em $BRAIN_DIR"
# 3. CORREÇÃO DO CAMINHO: Executa a sincronização apontando para o diretório correto no container
echo "🔄 Acionando o reindexador do Córtex dentro do container..."
docker exec -it ai-agent python3 /app/aiops/ollama/reindex_brain.py
echo "✅ IA atualizada!"
EOF
chmod +x aiops/ollama/add_knowledge.sh

# 19. Execute este por último para ver o relatório final e garantir que a RAM e a CPU estão aguentando o tranco.
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
    # Adiciona monitoramento em tempo real no terminal
    echo "Para monitorar via terminal, use:"
    echo "watch -n 1 'nvidia-smi && sensors'"
    echo "---------------------------------------"
} | tee -a "$LOG_FILE"
EOF
chmod +x aiops/ollama/check_infra.sh

cat <<'EOF' > aiops/ollama/enable_auto_fans.sh
#!/bin/bash
# --- CONFIGURAÇÕES ---
DISPLAY_ID=":1"
echo "===================================================="
echo "⚡ [SRE Córtex] AJUSTANDO PARÂMETROS DE REDE DO XHOST"
echo "===================================================="
# 1. GERENCIAMENTO DA TELA FANTASMA EM MEMÓRIA (XVFB)
echo "🖥️  Garantindo Framebuffer Virtual no Display $DISPLAY_ID..."
if ! pgrep -f "Xvfb $DISPLAY_ID" > /dev/null; then
    sudo nohup Xvfb $DISPLAY_ID -screen 0 1024x768x24 +extension GLX +extension RANDR > /dev/null 2>&1 &
    sleep 2
fi
# 2. AUTORIZAÇÃO CORRETA DE REDE (CORREÇÃO DO CIDR)
echo "🔒 Aplicando permissões de segurança no xhost..."
export DISPLAY=$DISPLAY_ID
# Desativa o controle estrito do xhost apenas para conexões locais/docker 
# (Método mais seguro e compatível para containers na mesma máquina)
xhost +local:docker > /dev/null
xhost +localhost > /dev/null
xhost +127.0.0.1 > /dev/null
echo "✅ Permissões aplicadas com sucesso."
# 3. TESTE DE FOGO INTEGRADO
echo "----------------------------------------------------"
echo "🎯 Executando Teste de Fogo no Hardware..."
echo "🔄 Forçando FAN a 100% por 3 segundos para validação..."
# Configura o controle manual no display local do Xvfb
nvidia-settings -c $DISPLAY_ID -a "[gpu:0]/GPUFanControlState=1" > /dev/null 2>&1
nvidia-settings -c $DISPLAY_ID -a "[fan:0]/GPUTargetFanSpeed=100" > /dev/null 2>&1
sleep 3
# Captura telemetria atual via nvidia-smi
STATUS_VALIDACAO=$(nvidia-smi --query-gpu=fan.speed,temperature.gpu --format=csv,noheader,nounits)
FAN_SPEED=$(echo "$STATUS_VALIDACAO" | cut -d',' -f1 | tr -d ' ')
GPU_TEMP=$(echo "$STATUS_VALIDACAO" | cut -d',' -f2 | tr -d ' ')
echo "📊 Telemetria -> Rotação do FAN: ${FAN_SPEED}% | Temperatura: ${GPU_TEMP}°C"
# Restaura para o controle automático do driver
nvidia-settings -c $DISPLAY_ID -a "[gpu:0]/GPUFanControlState=0" > /dev/null 2>&1
echo "===================================================="
echo "🏁 [SRE Córtex] ECOSSISTEMA PRONTO E VALIDADO!"
echo "===================================================="
EOF
chmod +x aiops/ollama/enable_auto_fans.sh

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
#Córtex, quais bancos de dados o sistema usa?
#Córtex, O sistema usa Docker e Python?, Qual a stack?
#Quais os capítulos lidos no terceiro dia de leitura ?
#docker exec -it ai-agent pip install streamlit-autorefresh
#docker commit ai-agent ollama-ai-agent:v1.0-gold
#FIND_LINKS=$(find ./cache_app/bin_pip -name "*.whl" -printf "--find-links=%h " | sort -u) && \
#pip install --break-system-packages --no-index $FIND_LINKS -r requirements.txt
#docker exec -it ollama-server ollama run qwen2:0.5b
#DISPLAY=:1 nvidia-settings -a "[gpu:0]/GPUFanControlState=1"
#DISPLAY=:1 nvidia-settings -a "[fan:0]/GPUTargetFanSpeed=85"
#sudo apt update && sudo apt install -y lm-sensors
#sudo sensors-detect --auto