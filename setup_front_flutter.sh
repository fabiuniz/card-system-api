#!/bin/bash

# Configurações iniciais
BASE_FOLDER="card-system-front-flutter"
rm -rf $BASE_FOLDER
mkdir -p $BASE_FOLDER
cd $BASE_FOLDER
ROOT_DIR=$(pwd)

echo "🏗️ Criando estrutura Monorepo (Versão Santander Transações - FIX)..."

create_app_structure() {
    local APP_NAME=$1
    local PACKAGE=$2
    local DISPLAY_NAME=$3
    local COLOR=$4

    echo "📦 Configurando sub-projeto: $APP_NAME..."
    
    flutter create --project-name "$APP_NAME" --org "com.fabiano" --platforms android "$APP_NAME"
    
    rm -rf $APP_NAME/test
    mkdir -p $APP_NAME/lib/models
    mkdir -p $APP_NAME/lib/services

    # 1. Pubspec.yaml
    cat <<EOF > $APP_NAME/pubspec.yaml
name: $APP_NAME
description: App $DISPLAY_NAME
version: 1.0.0+1
environment:
  sdk: ">=3.0.0 <4.0.0"
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
flutter:
  uses-material-design: true
EOF

# 2. AndroidManifest.xml
    cat <<EOF > $APP_NAME/android/app/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="$PACKAGE">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application
        android:label="$DISPLAY_NAME"
        android:name="\${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true">

        <meta-data android:name="flutterEmbedding" android:value="2" />

        <activity
            android:name="io.flutter.embedding.android.FlutterActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

    # 3. lib/main.dart (Ajustado com campo de Host e Correção de Const)
    cat <<EOF > $APP_NAME/lib/main.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Santander Card System',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEC1C24)),
      ),
      home: const TransactionScreen(),
    );
  }
}

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final TextEditingController _cardController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _hostController = TextEditingController(text: "10.0.2.2"); 
  bool _loading = false;
  Map<String, dynamic>? _result;

  Future<void> _sendTransaction() async {
    final double? amount = double.tryParse(_amountController.text);
    final messenger = ScaffoldMessenger.of(context);
    final host = _hostController.text.trim();

    if (amount == null || amount <= 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Insira um valor válido')));
      return;
    }

    setState(() { _loading = true; _result = null; });

    try {
      final response = await http.post(
        Uri.parse('http://\$host:8080/api/v1/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cardNumber': _cardController.text,
          'amount': amount,
        }),
      ).timeout(const Duration(seconds: 5));

      if (!mounted) return;
      setState(() { _result = json.decode(response.body); });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Erro ao conectar em \$host')));
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    const santanderRed = Color(0xFFEC1C24);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: santanderRed,
        title: const Text("Santander Card System | F1RST", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 🌐 CONFIGURAÇÃO DE REDE
            ExpansionTile(
              title: const Text("Configurações de Rede", style: TextStyle(fontSize: 14, color: Colors.grey)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: _hostController,
                    decoration: const InputDecoration(labelText: "IP do Servidor Backend"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: const Border(top: BorderSide(color: santanderRed, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Simular Nova Transação", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  const Text("Número do Cartão"),
                  TextField(controller: _cardController),
                  const SizedBox(height: 20),
                  const Text("Valor (R\\$)"), 
                  TextField(controller: _amountController, keyboardType: TextInputType.number),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _sendTransaction,
                      style: ElevatedButton.styleFrom(backgroundColor: santanderRed),
                      child: Text(_loading ? "PROCESSANDO..." : "AUTORIZAR COMPRA", style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // ✅ RESULTADO (Removido const dos Text dinâmicos)
            if (_result != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _result!['status'] == 'APPROVED' ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                  border: Border.all(color: _result!['status'] == 'APPROVED' ? Colors.green : Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(_result!['status'] == 'APPROVED' ? "✅ APROVADA" : "❌ REJEITADA",
                        style: TextStyle(fontWeight: FontWeight.bold, color: _result!['status'] == 'APPROVED' ? Colors.green[800] : Colors.red[800])),
                    Text("ID: \${_result!['transactionId'] ?? '---'}", style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
EOF
}

# --- Execução ---
create_app_structure "cardsystem" "com.fabiano.cardsystem" "Santander Card System" "Colors.red"
create_app_structure "techtaste" "com.fabiano.techtaste" "TechTaste Delivery" "Colors.orange"

# --- Script de Build ---
cat <<'EOF' > build_all.sh
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
EOF

chmod +x build_all.sh
./build_all.sh
cd ..

echo "--------------------------------------------------------"
echo "✅ Estrutura finalizada!"
echo "📂 Localização dos APKs: $ROOT_DIR/dist"
echo " Comandos para rodar:"
echo " (cd card-system-front-flutter/cardsystem && flutter pub get && flutter run -d emulator-5554)"
echo "--------------------------------------------------------"