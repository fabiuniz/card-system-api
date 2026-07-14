import os
import sys
import json
from ftplib import FTP

# Valores base padrão caso falte alguma chave no JSON
CONFIG_PADRAO = {
    "FTP_HOST": "192.168.1.120",
    "FTP_PORT": 2121,
    "FTP_USER": "F",
    "FTP_PASS": "1",
    "LOCAL_APK_PATH": "app/build/outputs/apk/debug/app-debug.apk",
    "REMOTE_APK_NAME": "wordquiz-debug.apk",
    "SDCARD_DIR": "Download"
}

def carregar_configuracao():
    """Lê o arquivo config.json e filtra pelo bloco escolhido no terminal"""
    if len(sys.argv) < 3:
        print("[-] Erro de uso!")
        print("    Modo correto: python enviar_ftp.py <arquivo.json> <nome_da_config> <path_apk>")
        print("    Exemplo:      python enviar_ftp.py config.json 'cfg a' '/file.apk'")
        sys.exit(1)

    json_path = sys.argv[1]
    config_escolhida = sys.argv[2]
    path_apk = sys.argv[3]

    if not os.path.exists(json_path):
        print(f"[-] Erro: Arquivo {json_path} não encontrado.")
        sys.exit(1)

    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            banco_de_configs = json.load(f)
            
            if config_escolhida in banco_de_configs:
                # Mescla o padrão com o que foi escolhido no JSON
                config_final = CONFIG_PADRAO.copy()
                config_final.update(banco_de_configs[config_escolhida])
                print(f"[+] Aplicada com sucesso a configuração: [{config_escolhida}]")
                return config_final
            else:
                print(f"[-] Erro: A chave '{config_escolhida}' não existe dentro do arquivo {json_path}.")
                sys.exit(1)
    except Exception as e:
        print(f"[-] Erro ao processar o arquivo JSON: {e}")
        sys.exit(1)

def enviar_apk():
    # Carrega o bloco do cliente selecionado
    cfg = carregar_configuracao()
    if len(sys.argv) >= 4 and sys.argv[3].strip() != "":
        local_path = sys.argv[3]
        print(f"[+] Usando o APK do parâmetro: {local_path}")
    else:
        local_path = cfg["LOCAL_APK_PATH"]
        print(f"[+] Usando o APK padrão da configuração: {local_path}")
    
    remote_name = cfg["REMOTE_APK_NAME"]
    pasta_destino = cfg["SDCARD_DIR"]

    if not os.path.exists(local_path):
        print(f"[-] Erro: O arquivo local {local_path} não foi encontrado.")
        return

    print(f"[+] Conectando em {cfg['FTP_HOST']}:{cfg['FTP_PORT']}...")

    try:
        ftp = FTP()
        ftp.connect(cfg["FTP_HOST"], int(cfg["FTP_PORT"]), timeout=30)
        ftp.login(cfg["FTP_USER"], cfg["FTP_PASS"])
        ftp.set_pasv(True)
        print("[+] Login efetuado com sucesso!")
        
        # Tenta navegar dinamicamente para a pasta configurada no JSON
        print(f"[+] Acessando o diretório de destino: {pasta_destino}")
        try:
            ftp.cwd(pasta_destino)
        except Exception:
            # Se falhar (ex: falta a barra inicial), tenta forçar raiz
            try:
                ftp.cwd(f"/{pasta_destino}")
            except Exception as e:
                print(f"[-] Não foi possível acessar a pasta '{pasta_destino}'. Enviando na raiz. Erro: {e}")

        print(f"[+] Enviando arquivo...")
        with open(local_path, 'rb') as arquivo:
            ftp.storbinary(f'STOR {remote_name}', arquivo)

        print(f"[==>] SUCESSO! Arquivo enviado para [{cfg['FTP_HOST']}] como '{remote_name}'.")
        ftp.quit()

    except Exception as e:
        print(f"[-] Falha crítica no upload: {e}")

if __name__ == "__main__":
    enviar_apk()