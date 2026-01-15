import requests
import time

# Configurações
BASE_URL = "http://localhost:8080/actuator"
HEALTH_URL = f"{BASE_URL}/health"
METRICS_URL = f"{BASE_URL}/metrics/transactions_total"

def run_aiops_check():
    print("🚀 [F1RST AIOps] Iniciando monitoramento inteligente...")
    
    try:
        # 1. Check de Saúde Básico
        health = requests.get(HEALTH_URL, timeout=5).json()
        print(f"📊 Status do Sistema: {health['status']}")

        # 2. Check de Métricas de Negócio (Onde a mágica acontece)
        metrics_resp = requests.get(METRICS_URL, timeout=5)
        
        if metrics_resp.status_code == 200:
            measurements = metrics_resp.json().get('measurements', [])
            total_tx = measurements[0]['value'] if measurements else 0
            print(f"📈 Telemetria: {total_tx} transações processadas desde o último boot.")
        else:
            print("⚠️ Métricas ainda não geradas. Processe uma transação primeiro.")

    except Exception as e:
        print(f"🚨 ALERTA: Falha na coleta de dados. Verifique se a API Java está UP. Erro: {e}")

if __name__ == "__main__":
    run_aiops_check()