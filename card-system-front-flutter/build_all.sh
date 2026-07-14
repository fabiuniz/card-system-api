#!/bin/bash
ROOT_DIR="$(pwd)"
DIST_DIR="$ROOT_DIR/dist"
mkdir -p "$DIST_DIR"

build_app() {
    local FOLDER=$1
    local APK_NAME=$2
    echo "🏗️ Compilando $FOLDER..."
    if cd "$ROOT_DIR/$FOLDER"; then
        flutter pub get
        flutter build apk --release
        if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
            cp build/app/outputs/flutter-apk/app-release.apk "$DIST_DIR/$APK_NAME.apk"
            echo "✅ $APK_NAME concluído com sucesso!"
        else
            echo "❌ Erro: APK não encontrado para $APK_NAME."
        fi
        cd "$ROOT_DIR"
    fi
}
build_app "cardsystem" "CardSystem"
build_app "techtaste" "TechTaste"
