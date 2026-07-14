#!/bin/bash
# Força o script a parar imediatamente se qualquer comando falhar
set -e

echo "=========================================================="
echo "===             INICIANDO BUILD DO APK                 ==="
echo "=========================================================="

# 0. CONFIGURAÇÃO AUTOMÁTICA DE AMBIENTE (Facilitando sua vida)
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
export ANDROID_HOME="/home/userlnx/Android/Sdk"
export FLUTTER_HOME="/home/userlnx/development/flutter"
export PATH="$FLUTTER_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$JAVA_HOME/bin:$PATH"

# 1. Limpeza preventiva de processos travados
echo "[1/7] Matando processos antigos do Gradle/Java..."
pkill -f gradle || true
pkill -f java || true

# 1.5. AUTO-INSTALAÇÃO DO NDK (se o zip estiver no local do script)
echo "[1.5/7] Verificando se há pacotes NDK para instalar..."
NDK_ZIP="android-ndk-r28b-linux.zip"
# Atualizado para a versão exata exigida pelo seu Gradle moderno
NDK_TARGET_DIR="$ANDROID_HOME/ndk/28.2.13676358"

if [ -f "$NDK_ZIP" ]; then
    if [ ! -d "$NDK_TARGET_DIR" ] || [ ! -f "$NDK_TARGET_DIR/source.properties" ]; then
        echo "[+] Detectado $NDK_ZIP. Removendo resíduos e instalando NDK r28b..."
        rm -rf "$NDK_TARGET_DIR"
        mkdir -p "$ANDROID_HOME/ndk"
        
        # Descompacta o zip temporariamente
        unzip -q "$NDK_ZIP" -d "$ANDROID_HOME/ndk/"
        
        # Renomeia a pasta extraída para a versão exata que o Gradle quer
        mv "$ANDROID_HOME/ndk/android-ndk-r28b" "$NDK_TARGET_DIR"
        
        # Ajusta as permissões de execução do NDK recém-instalado
        chown -R userlnx:userlnx "$ANDROID_HOME/ndk" || true
        chmod -R +x "$NDK_TARGET_DIR/toolchains" || true
        echo "[+] NDK r28b instalado e configurado com sucesso em: $NDK_TARGET_DIR"
    else
        echo "[+] NDK r28b já está instalado corretamente."
    fi
fi

# 2. Garantir a estrutura correta do Gradle 9.1.0 localmente
GRADLE_VERSION="9.1.0"
GRADLE_DIST="all"
GRADLE_DIR="/home/userlnx/.gradle/wrapper/dists/gradle-${GRADLE_VERSION}-${GRADLE_DIST}"
HASH_DIR="7wzd0jkjit61aq2p43wpjgij9" 
TARGET_PATH="${GRADLE_DIR}/${HASH_DIR}"

echo "[2/7] Verificando integridade local do Gradle ${GRADLE_VERSION}..."
if [ ! -f "${TARGET_PATH}/gradle-${GRADLE_VERSION}-${GRADLE_DIST}.zip.ok" ] || [ ! -f "${TARGET_PATH}/gradle-${GRADLE_VERSION}-${GRADLE_DIST}.zip" ]; then
    echo "[-] Gradle ${GRADLE_VERSION} não encontrado ou incompleto."
    echo "[+] Baixando manualmente com barra de progresso para evitar travamento..."
    mkdir -p "${TARGET_PATH}"
    
    curl -L --progress-bar -o "${TARGET_PATH}/gradle-${GRADLE_VERSION}-${GRADLE_DIST}.zip" \
        "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-${GRADLE_DIST}.zip"
    
    touch "${TARGET_PATH}/gradle-${GRADLE_VERSION}-${GRADLE_DIST}.zip.ok"
    echo "[+] Download do Gradle concluído com sucesso!"
else
    echo "[+] Gradle ${GRADLE_VERSION}-${GRADLE_DIST} já está pronto e validado localmente."
fi

# 3. Preparação do ambiente Flutter
echo "[3/7] Preparando o projeto Flutter..."
flutter create . --platforms=android
flutter clean
flutter pub get

# 4. Compilação do APK
echo "[4/7] Iniciando compilação do APK Release..."
flutter build apk --release

# 5. Verificação do APK gerado
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
find . -type f -name "*.apk"
echo "[5/7] Verificando arquivos gerados..."
if [ -f "$APK_PATH" ]; then
    echo "=========================================================="
    echo "===          COMPILAÇÃO CONCLUÍDA COM SUCESSO!         ==="
    echo "Seu APK gerado está em: $APK_PATH"
    echo "=========================================================="
    
    # 6. Upload opcional via FTP
    if [ -f "upload_apk.py" ]; then
        echo "[6/7] === Conectando ao FTP para Upload ==="
        python3 upload_apk.py upload_cfg.json "cfg_a"
    else
        echo "[6/7] Script upload_apk.py não encontrado. Pulando upload."
    fi
else
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "[-] ERRO CRÍTICO: O processo terminou, mas o APK não foi encontrado."
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi
#cardsystem/build/app/outputs/flutter-apk/app-release.apk
#Olá! Preciso retomar o processo de build de um APK Flutter exatamente de onde parei. Aqui estão todos os dados do meu ambiente (Debian 13 VM Headless, usuário "userlnx") que já foram validados e configurados:
#
#1. Caminhos e Versões:
#- Flutter SDK: 3.44.6 em '/home/userlnx/development/flutter'
#- Android SDK: v36.1.0 (Platform 36, Build-tools 36.1.0) em '/home/userlnx/Android/Sdk'
#- Java: OpenJDK 21 em '/usr/lib/jvm/java-21-openjdk-amd64/bin/java' (mapeado no $JAVA_HOME)
#- Gradle: 9.1.0-all descompactado manualmente e validado com sucesso em '/home/userlnx/.gradle/wrapper/dists/gradle-9.1.0-all/7wzd0jkjit61aq2p43wpjgij9/' (com os arquivos .ok e .lck configurados).
#- Limite de Memória Global: Criado em '~/.gradle/gradle.properties' com '-Xmx2048m -XX:MaxMetaspaceSize=512m' para evitar OOM na VM.
#
#2. Caminho do Projeto:
#'/home/userlnx/docker/script_docker/java-ia/card-system-front-flutter/cardsystem'
#
#3. Último Status:
#Para evitar travamentos de memória, matamos todos os processos fantasmas (pkill -9 para java, gradle e dart) e executamos na raiz do projeto o comando síncrono:
#$ flutter build apk --release --no-pub
#
#A execução estava em andamento na etapa 'Running Gradle task assembleRelease...'. 
#
#Se a conexão caiu, preciso que você me guie para:
#1. Verificar se o build anterior terminou com sucesso no background ou se falhou.
#2. Como validar se o APK 'app-release.apk' foi gerado na pasta de saída.
#3. Quais comandos executar a partir de agora caso o build tenha falhado novamente.


#[Seu Código Flutter] 
#       │
#       ▼ (Compilado para código nativo C/C++ e Kotlin/Java)
#[Gradle (Gerenciador de Build)] 
#       │
#       ├─► Baixa dependências e bibliotecas do Android
#       ├─► Usa o Android SDK (ferramentas para empacotar o app)
#       └─► Usa o NDK (ferramentas para compilar as partes C/C++ do Flutter)