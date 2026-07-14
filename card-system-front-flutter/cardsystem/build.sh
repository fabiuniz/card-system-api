#!/bin/bash
# Força o script a parar imediatamente se qualquer comando falhar
set -e

echo "=========================================================="
echo "===                 INICIANDO BUILD DO APK                ==="
echo "=========================================================="

# === [AUTO-INSTALAÇÃO DO JAVA 17] ===
echo "[+] Verificando se o OpenJDK 17 está disponível no sistema..."
if [ ! -d "/usr/lib/jvm/java-17-openjdk-amd64" ]; then
    echo "[-] Java 17 não encontrado! Iniciando instalação automática..."
    # Atualiza a lista de pacotes e instala o JDK 17 sem pedir confirmação visual
    apt-get update && apt-get install -y openjdk-17-jdk
    echo "[+] Java 17 instalado com sucesso!"
else
    echo "[+] Java 17 já está instalado e pronto para uso."
fi

# 0. CONFIGURAÇÃO AUTOMÁTICA DE AMBIENTE (Alinhado com o padrão estável Java 17)
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
export ANDROID_HOME="/home/userlnx/Android/Sdk"
export FLUTTER_HOME="/home/userlnx/development/flutter"
export PATH="$FLUTTER_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$JAVA_HOME/bin:$PATH"

# CORREÇÃO CRÍTICA ULTRA: Procura e destrói "path/to/jdk" em TODO o projeto e no Gradle global
echo "[+] Caçando e eliminando referências a 'path/to/jdk'..."

# 1. Corrige no gradle.properties local do projeto (Apontando para Java 17)
if [ -f "android/gradle.properties" ]; then
    sed -i 's|org.gradle.java.home=.*|org.gradle.java.home=/usr/lib/jvm/java-17-openjdk-amd64|g' android/gradle.properties
    sed -i '/path\/to\/jdk/d' android/gradle.properties
fi

# 2. Corrige no gradle.properties GLOBAL do usuário do Linux
if [ -f "/home/userlnx/.gradle/gradle.properties" ]; then
    echo "[+] Limpando gradle.properties global em ~/.gradle/..."
    sed -i 's|org.gradle.java.home=.*|org.gradle.java.home=/usr/lib/jvm/java-17-openjdk-amd64|g' /home/userlnx/.gradle/gradle.properties
    sed -i '/path\/to\/jdk/d' /home/userlnx/.gradle/gradle.properties
fi

# 3. Preparação do ambiente Flutter
echo "[3/5] Preparando o projeto Flutter..."
flutter create . --platforms=android
flutter clean
flutter pub get

# ==========================================================
# 🔥 CRÍTICO: MUDANÇA DE ORDEM E TRAVA ANTI-SOBREESCRITA
# ==========================================================

# 1. Primeiro rodamos um pré-build falso ou inicialização para o Flutter gerar/atualizar o que quiser
echo "[+] Inicializando arquivos base do Gradle..."
flutter build apk --config-only 2>/dev/null || true

# 2. AGORA SIM injetamos as travas nos arquivos (O Flutter não vai mais sobrescrevê-los)
echo "[+] Injetando variáveis compatíveis no local.properties..."
if [ -f "android/local.properties" ]; then
    sed -i '/flutter.minSdkVersion/d' android/local.properties
    sed -i '/flutter.targetSdkVersion/d' android/local.properties
    sed -i '/flutter.compileSdkVersion/d' android/local.properties
fi
echo "flutter.minSdkVersion=21" >> android/local.properties
echo "flutter.targetSdkVersion=34" >> android/local.properties
echo "flutter.compileSdkVersion=34" >> android/local.properties

if [ -f "android/app/build.gradle.kts" ]; then
    echo "[+] Ajustando build.gradle.kts para garantir API 34 estável..."
    sed -i 's/compileSdk = .*/compileSdk = 34/g' android/app/build.gradle.kts
    sed -i 's/minSdk = .*/minSdk = 21/g' android/app/build.gradle.kts
    sed -i 's/targetSdk = .*/targetSdk = 34/g' android/app/build.gradle.kts
    
    # Remove qualquer menção antiga ao buildToolsVersion para não duplicar
    sed -i '/buildToolsVersion/d' android/app/build.gradle.kts
    
    # Injeta a versão exata 34.0.0 logo abaixo de compileSdk = 34
    sed -i '/compileSdk = 34/a \    buildToolsVersion = "34.0.0"' android/app/build.gradle.kts
fi

if [ -f "android/gradle.properties" ]; then
    sed -i 's|org.gradle.java.home=.*|org.gradle.java.home=/usr/lib/jvm/java-17-openjdk-amd64|g' android/gradle.properties
fi

# 4. Compilação do APK Release Real
echo "[4/5] Iniciando compilação do APK Release..."
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"

# Usamos a flag '--no-version-check' para mitigar ganchos automáticos de upgrade de SDK
flutter build apk --release --target-platform android-arm --no-pub --no-version-check

# 5. Verificação do APK gerado
APK_ARM_PATH="build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk"
APK_GENERIC_PATH="build/app/outputs/flutter-apk/app-release.apk"
APK_PATH=""

echo "[5/5] Verificando arquivos gerados..."
if [ -f "$APK_ARM_PATH" ]; then
    APK_PATH="$APK_ARM_PATH"
elif [ -f "$APK_GENERIC_PATH" ]; then
    APK_PATH="$APK_GENERIC_PATH"
fi

if [ -n "$APK_PATH" ]; then
    echo "=========================================================="
    echo "===          COMPILAÇÃO CONCLUÍDA COM SUCESSO!         ==="
    echo "Seu APK otimizado está em: $APK_PATH"
    echo "=========================================================="
    
    if [ -f "upload_apk.py" ] && [ -f "upload_cfg.json" ]; then
        echo "[6/6] === Conectando ao FTP para Upload ==="
        python3 upload_apk.py upload_cfg.json "cfg_a" "$APK_PATH"
    else
        echo "[6/6] Scripts de upload não encontrados. Pulando upload."
    fi
else
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "[-] ERRO CRÍTICO: Nenhum APK foi encontrado nas pastas de output."
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
#       
#       ao abrir o apk no dispositivo galaxy L2 prime SM-G532MT da "Ocorreu um problema ao analisar o pacote"
#       
#       /home/userlnx/Android/Sdk/cmdline-tools/latest/bin/sdkmanager --list_installed
#       /home/userlnx/Android/Sdk/cmdline-tools/latest/bin/sdkmanager "build-tools;36.0.0" #ou "34.0.0"

