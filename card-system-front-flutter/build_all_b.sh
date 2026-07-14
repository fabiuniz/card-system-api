pkill -f gradle
flutter create . --platforms=android
flutter clean
flutter pub get
flutter build apk --release
#flutter build apk --release --verbose
if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
    echo "=========================================================="
    echo "=== COMPILAÇÃO CONCLUÍDA COM SUCESSO! ==="
    echo "Seu APK gerado está em: app/build/outputs/apk/debug/app-debug.apk"
    echo "=========================================================="
    
    if [ -f "upload_apk.py" ]; then
        echo "=== Conectando ao FTP para Upload ==="
        python3 upload_apk.py upload_cfg.json "cfg_a"
    fi
else
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "[-] ERRO CRÍTICO: O Gradle terminou, mas o APK nao foi gerado!"
    echo "Verifique os erros do log do Gradle logo acima."
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi

#watch -n 1 "echo '=== STATUS DO DOWNLOAD DO GRADLE ===' && find /home/userlnx/.gradle/wrapper/dists/ -name '*zip*' -o -name '*.part' 2>/dev/null | xargs du -h 2>/dev/null && echo '----------------------------------' && echo 'Tamanho total ocupado por versões do Gradle:' && du -sh /home/userlnx/.gradle/wrapper/dists/ 2>/dev/null"