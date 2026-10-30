#!/usr/bin/env bash
ROOT_DIR="$(pwd)"
DIST_DIR="$ROOT_DIR/dist"
mkdir -p "$DIST_DIR"

up_file(){
    local APK_NAME=$1
    local APK_CFG=$2
    local APK_PATH="$DIST_DIR/$APK_NAME.apk"
    
    # Como o upload_apk.py e upload_cfg.json estão na raiz de card-system-front-flutter
    if [ -f "upload_apk.py" ] && [ -f "upload_cfg.json" ]; then
        echo "[6/6] === Conectando ao FTP para Upload de $APK_NAME ==="
        python3 upload_apk.py upload_cfg.json "$APK_CFG" "$APK_PATH"
    else
        echo "[6/6] Scripts de upload na raiz não encontrados. Pulando upload."
    fi
}

build_app() {
    local FOLDER=$1
    local APK_NAME=$2
    local APK_CFG=$3
    local APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    
    echo "🏗️ Compilando $FOLDER..."
    if cd "$ROOT_DIR/$FOLDER"; then
        flutter clean
        flutter pub get
        flutter create . --platforms=android
        flutter build apk --release --target-platform android-arm --no-tree-shake-icons        
        
        if [ -f "$APK_PATH" ]; then
            cp "$APK_PATH" "$DIST_DIR/$APK_NAME.apk"
            echo "✅ $APK_NAME concluído com sucesso!"
        else
            echo "❌ Erro: APK não encontrado para $APK_NAME."
        fi
        cd "$ROOT_DIR"
    fi     
    
    # Executa o upload usando os scripts que estão na raiz
    up_file "$APK_NAME" "$APK_CFG"
}

#
#python3 upload_apk.py upload_cfg.json "cfg_a" "$APK_PATH"
#python3 upload_apk.py upload_cfg.json "cfg_a" "techtaste/build/app/outputs/flutter-apk/app-release.apk"
#

#ao abrir o apk no dispositivo galaxy L2 prime SM-G532MT da "Ocorreu um problema ao analisar o pacote"

build_app "cardsystem" "CardSystem" "cfg_a"
build_app "techtaste" "TechTaste" "cfg_b"
build_app "tvcastapp" "TvCastApp" "cfg_c"
build_app "messagesend" "MessageSend" "cfg_d"

#MessageSend
#curl -X POST http://192.168.1.120:8080/api/message \
#  -H "Content-Type: application/json" \
#  -d '{"message": "https://www.youtube.com/watch?v=pzwpJXgaVWM&pp=ugUEEgJlbg%3D%3D"}'
#  
#curl -X POST http://192.168.1.120:8080/api/upload \
#  -H "X-File-Name: MessageSend.apk" \
#  --data-binary "@C:\Users\Fabiano\Downloads\MessageSend.apk"
#  
#curl http://192.168.1.120:8080/api/files
#curl http://192.168.1.120:8080/api/help