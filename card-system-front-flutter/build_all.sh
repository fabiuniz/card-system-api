#!/bin/bash
ROOT_DIR="$(pwd)"
DIST_DIR="$ROOT_DIR/dist"
mkdir -p "$DIST_DIR"

up_file(){
    local FOLDER=$1
    local APK_PATH=$2
    if [ -f "$FOLDER/upload_apk.py" ] && [ -f "$FOLDER/upload_cfg.json" ]; then
        echo "[6/6] === Conectando ao FTP para Upload ==="
        python3 "$FOLDER/upload_apk.py" "$FOLDER/upload_cfg.json" "cfg_a" "$APK_PATH"
    else
        echo "[6/6] Scripts de upload \"$FOLDER\" não encontrados. Pulando upload."
    fi
}

build_app() {
    local FOLDER=$1
    local APK_NAME=$2
    local APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    echo "🏗️ Compilando $FOLDER..."
    if cd "$ROOT_DIR/$FOLDER"; then
        flutter pub get
        flutter build apk --release
        if [ -f "$APK_PATH" ]; then
            cp "$APK_PATH" "$DIST_DIR/$APK_NAME.apk"
            echo "✅ $APK_NAME concluído com sucesso!"
        else
            echo "❌ Erro: APK não encontrado para $APK_NAME."
        fi
        cd "$ROOT_DIR"
    fi    
    up_file "$FOLDER" "$DIST_DIR/$APK_NAME.apk"
}

build_app "cardsystem" "CardSystem"
#build_app "techtaste" "TechTaste"