#!/bin/bash
# Força o script a parar imediatamente se qualquer comando falhar
set -e

echo "=========================================================="
echo "===      INICIANDO BUILD DO APK (MESSAGESEND)            ==="
echo "=========================================================="

# === [CONFIGURAÇÃO DO AMBIENTE COM JAVA 21 NATIVO] ===
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
# Ajustado para o diretório correto do SDK na máquina (root)
export ANDROID_HOME="/root/android-sdk"
export FLUTTER_HOME="/opt/flutter"
export PATH="$FLUTTER_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$JAVA_HOME/bin:$PATH"

echo "[+] Usando JAVA_HOME apontado para: $JAVA_HOME"
java -version

# 1. Preparação correta do projeto Flutter (limpa ANTES de criar a estrutura)
echo "[3/5] Preparando o projeto Flutter..."
flutter clean
flutter pub get
flutter create . --platforms=android

# Inicialização para gerar arquivos base do Gradle
flutter build apk --config-only --no-pub 2>/dev/null || true

# 2. Injetando travas de SDK compatíveis no local.properties
echo "[+] Injetando variáveis compatíveis no local.properties..."
mkdir -p android
if [ -f "android/local.properties" ]; then
    sed -i '/flutter.minSdkVersion/d' android/local.properties
    sed -i '/flutter.targetSdkVersion/d' android/local.properties
    sed -i '/flutter.compileSdkVersion/d' android/local.properties
fi
echo "flutter.minSdkVersion=21" >> android/local.properties
echo "flutter.targetSdkVersion=34" >> android/local.properties
echo "flutter.compileSdkVersion=34" >> android/local.properties

if [ -f "android/app/build.gradle.kts" ]; then
    sed -i 's/compileSdk = .*/compileSdk = 34/g' android/app/build.gradle.kts
    sed -i 's/minSdk = .*/minSdk = 21/g' android/app/build.gradle.kts
    sed -i 's/targetSdk = .*/targetSdk = 34/g' android/app/build.gradle.kts
fi

# 3. Compilação do APK Release (Adicionado --no-tree-shake-icons para evitar conflito de watcher)
echo "[4/5] Iniciando compilação do APK Release com Java 21..."
flutter build apk --release --target-platform android-arm,android-arm64 --no-pub --no-version-check --no-tree-shake-icons

# 4. Organização do APK gerado na pasta dist raiz
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
mkdir -p "$DIST_DIR"

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
    
    if [ -f "../upload_apk.py" ] && [ -f "../upload_cfg.json" ]; then
        echo "[6/6] === Conectando ao FTP para Upload ==="
        python3 ../upload_apk.py ../upload_cfg.json "cfg_a" "$APK_PATH"
    else
        echo "[6/6] Scripts de upload não encontrados. Pulando upload."
    fi
else
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "[-] ERRO CRÍTICO: Nenhum APK foi encontrado nas pastas de output."
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi