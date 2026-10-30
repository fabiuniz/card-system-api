import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MessageSendApp());

class MessageSendApp extends StatelessWidget {
  const MessageSendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Message & File Tool',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      ),
      home: const MessageScreen(),
    );
  }
}

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _inputController = TextEditingController(
    text: "Aguardando mensagens ou arquivos...",
  );
  bool _copiedCurl = false;
  bool _copiedUploadCurl = false;
  bool _copiedHelpCurl = false;
  bool _copiedLogText = false;
  HttpServer? _server;
  String _serverStatus = "Iniciando servidor...";
  String _currentIp = "192.168.X.X";
  
  final List<File> _receivedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadExistingFiles().then((_) {
      _startHttpServer();
    });
  }
  
  Future<void> _sendToAnotherDevice(String targetIp, String textMessage) async {
    try {
      final url = Uri.parse('http://$targetIp:8080/api/message');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': textMessage}),
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enviado com sucesso para o outro dispositivo! ✅")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao enviar: $e ❌")),
        );
      }
    }
  }

  // Função para enviar arquivo via HTTP POST para outro dispositivo
  Future<void> _sendFileToAnotherDevice(String targetIp, File fileToShare) async {
    try {
      final url = Uri.parse('http://$targetIp:8080/api/upload');
      final bytes = await fileToShare.readAsBytes();
      final fileName = fileToShare.uri.pathSegments.last;

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/octet-stream',
          'X-File-Name': fileName,
        },
        body: bytes,
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Arquivo '$fileName' enviado com sucesso! ✅")),
        );
      } else {
        throw "Erro HTTP: ${response.statusCode}";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao enviar arquivo: $e ❌")),
        );
      }
    }
  }

  // Caixa de diálogo aprimorada com sugestão de IP e opção de enviar arquivos ou texto
  void _showSendToIpDialog() {
    // Sugere o IP atual (removendo o último segmento para facilitar preenchimento, ou o IP completo)
    final TextEditingController ipController = TextEditingController(text: _currentIp);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enviar para outro Dispositivo"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                hintText: "Ex: 192.168.1.15",
                labelText: "IP do Aparelho Destino",
                helperText: "Dica: O IP atual está pré-preenchido",
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Escolha o que deseja enviar:",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          // Botão para Enviar Apenas o Texto atual
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              String targetIp = ipController.text.trim();
              if (targetIp.isNotEmpty) {
                _sendToAnotherDevice(targetIp, _inputController.text);
              }
            },
            child: const Text("Enviar Texto"),
          ),
          // Botão para Selecionar e Enviar um Arquivo
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              String targetIp = ipController.text.trim();
              if (targetIp.isEmpty) return;

              // Abre o seletor de arquivos para escolher o que enviar
              FilePickerResult? result = await FilePicker.platform.pickFiles();
              if (result != null && result.files.single.path != null) {
                File fileToSend = File(result.files.single.path!);
                _sendFileToAnotherDevice(targetIp, fileToSend);
              }
            },
            child: const Text("Enviar Arquivo"),
          ),
        ],
      ),
    );
  }

  Future<void> _loadExistingFiles() async {
    try {
      final directory = await _getStorageDirectory();
      if (directory != null && await directory.exists()) {
        final List<File> loadedFiles = [];
        await for (var entity in directory.list()) {
          if (entity is File) {
            loadedFiles.add(entity);
          }
        }
        setState(() {
          _receivedFiles.clear();
          _receivedFiles.addAll(loadedFiles);
        });
      }
    } catch (_) {}
  }

  Future<void> _shareFile(File sourceFile) async {
    try {
      await Share.shareXFiles(
        [XFile(sourceFile.path)],
        text: 'Arquivo recebido via Message & File Tool',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao compartilhar: $e ❌")),
        );
      }
    }
  }

  Future<void> _deleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
      setState(() {
        _receivedFiles.removeWhere((f) => f.path == file.path);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Arquivo apagado com sucesso! 🗑️")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao apagar arquivo: $e ❌")),
        );
      }
    }
  }

  Future<void> _pickAndImportFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        final sourcePath = result.files.single.path!;
        final sourceFile = File(sourcePath);
        final fileName = result.files.single.name;

        final directory = await _getStorageDirectory();
        if (directory != null) {
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }

          final destinationFile = File('${directory.path}/$fileName');
          await sourceFile.copy(destinationFile.path);

          setState(() {
            if (!_receivedFiles.any((f) => f.path == destinationFile.path)) {
              _receivedFiles.add(destinationFile);
            }
            _inputController.text = "Arquivo importado: $fileName\nSalvo em: ${destinationFile.path}";
            _serverStatus = "Arquivo importado localmente! 📁";
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Arquivo importado com sucesso: $fileName ✅")),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao importar arquivo: $e ❌")),
        );
      }
    }
  }

  void _copyLogText() {
    Clipboard.setData(ClipboardData(text: _inputController.text));
    setState(() {
      _copiedLogText = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedLogText = false;
        });
      }
    });
  }

  Future<Directory?> _getStorageDirectory() async {
    if (Platform.isAndroid) {
      return await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }

  Future<String> _getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      
      String fallbackIp = '127.0.0.1';

      for (var interface in interfaces) {
        String name = interface.name.toLowerCase();
        if (name.contains('rmnet') || name.contains('ccmni') || name.contains('pdp')) {
          continue; 
        }

        for (var addr in interface.addresses) {
          if (addr.address.isNotEmpty) {
            fallbackIp = addr.address;
            if (addr.address.startsWith('192.168.') || 
                addr.address.startsWith('10.') || 
                addr.address.startsWith('172.')) {
              return addr.address;
            }
          }
        }
      }
      return fallbackIp;
    } catch (_) {}
    return '127.0.0.1';
  }

  Future<void> _startHttpServer() async {
    if (_server != null) return;

    try {
      final router = shelf_router.Router();

      router.get('/api/help', (shelf.Request request) async {
        final ip = _currentIp;
        final helpText = '''
==================================================
        MESSAGE & FILE TOOL API - AJUDA
==================================================

[1] GET /api/help
    Descrição: Exibe este manual de comandos.
    Exemplo:   curl http://$ip:8080/api/help

[2] GET /api/files
    Descrição: Lista todos os arquivos salvos em formato de tabela.
    Exemplo:   curl http://$ip:8080/api/files

[3] GET /api/files/<name>
    Descrição: Baixa um arquivo específico do celular.
    Exemplo:   curl -o "nome_do_arquivo.ext" "http://$ip:8080/api/files/nome_do%20arquivo.ext"

[4] POST /api/message
    Descrição: Envia uma mensagem de texto para a tela do app.
    Exemplo:   curl -X POST http://$ip:8080/api/message \\
               -H "Content-Type: application/json" \\
               -d '{"message": "Olá do terminal!"}'

[5] POST /api/upload
    Descrição: Envia um arquivo do computador para o celular.
    Exemplo:   curl -X POST http://$ip:8080/api/upload \\
               -H "X-File-Name: foto.png" \\
               --data-binary "@caminho/para/foto.png"
==================================================
''';

        return shelf.Response.ok(
          helpText,
          headers: {'Content-Type': 'text/plain; charset=utf-8'},
        );
      });

      router.get('/api/files', (shelf.Request request) async {
        try {
          final directory = await _getStorageDirectory();
          if (directory == null || !await directory.exists()) {
            return shelf.Response.ok("Nenhum arquivo encontrado.\n", headers: {'Content-Type': 'text/plain; charset=utf-8'});
          }

          final buffer = StringBuffer();
          buffer.writeln("==================================================");
          buffer.writeln("         ARQUIVOS DISPONÍVEIS PARA DOWNLOAD");
          buffer.writeln("==================================================");
          buffer.writeln("${'ARQUIVO'.padRight(45)} | ${'TAMANHO'.padRight(10)}");
          buffer.writeln('--------------------------------------------------');

          int count = 0;
          await for (var entity in directory.list()) {
            if (entity is File) {
              count++;
              final name = entity.uri.pathSegments.last;
              final stat = await entity.stat();
              
              String sizeStr = '';
              if (stat.size > 1024 * 1024) {
                sizeStr = '${(stat.size / (1024 * 1024)).toStringAsFixed(2)} MB';
              } else {
                sizeStr = '${(stat.size / 1024).toStringAsFixed(2)} KB';
              }

              buffer.writeln("${name.padRight(45)} | ${sizeStr.padRight(10)}");
            }
          }

          if (count == 0) {
            return shelf.Response.ok("Nenhum arquivo recebido ainda.\n", headers: {'Content-Type': 'text/plain; charset=utf-8'});
          }

          buffer.writeln("==================================================");
          buffer.writeln("Dica: Use 'curl -O http://$_currentIp:8080/api/files/NOME' para baixar.");

          return shelf.Response.ok(
            buffer.toString(),
            headers: {'Content-Type': 'text/plain; charset=utf-8'},
          );
        } catch (e) {
          return shelf.Response.internalServerError(body: "Erro ao listar arquivos: $e");
        }
      });

      router.get('/api/files/<name>', (shelf.Request request, String name) async {
        try {
          final directory = await _getStorageDirectory();
          if (directory == null) {
            return shelf.Response.notFound('Diretório não disponível.');
          }

          final decodedName = Uri.decodeComponent(name);
          final file = File('${directory.path}/$decodedName');

          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            return shelf.Response.ok(
              bytes,
              headers: {
                'Content-Type': 'application/octet-stream',
                'Content-Disposition': 'attachment; filename="$decodedName"',
              },
            );
          } else {
            return shelf.Response.notFound('Arquivo não encontrado.');
          }
        } catch (e) {
          return shelf.Response.internalServerError(body: "Erro ao ler arquivo: $e");
        }
      });

      router.post('/api/message', (shelf.Request request) async {
        try {
          final bodyBytes = await request.read().expand((chunk) => chunk).toList();
          final payload = utf8.decode(bodyBytes, allowMalformed: true);
          String message = payload;

          try {
            final data = jsonDecode(payload);
            if (data is Map && data.containsKey('message')) {
              message = data['message'].toString();
            }
          } catch (_) {
            message = payload;
          }

          setState(() {
            _inputController.text = message;
            _serverStatus = "Mensagem recebida às ${DateTime.now().toLocal().toString().substring(11, 19)}";
          });

          return shelf.Response.ok(
            jsonEncode({"status": "success", "received": message}),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
          );
        } catch (e) {
          return shelf.Response.internalServerError(body: 'Erro interno ao processar mensagem: $e');
        }
      });

      router.post('/api/upload', (shelf.Request request) async {
        try {
          final bodyBytes = await request.read().expand((chunk) => chunk).toList();
          final fileName = request.headers['x-file-name'] ?? 'arquivo_${DateTime.now().millisecondsSinceEpoch}.bin';
          
          final directory = await _getStorageDirectory();
          if (!await directory!.exists()) {
            await directory.create(recursive: true);
          }
          
          final savedFile = File('${directory.path}/$fileName');
          await savedFile.writeAsBytes(bodyBytes);

          setState(() {
            if (!_receivedFiles.any((f) => f.path == savedFile.path)) {
              _receivedFiles.add(savedFile);
            }
            _inputController.text = "Arquivo recebido: $fileName\nSalvo em: ${savedFile.path}";
            _serverStatus = "Arquivo recebido com sucesso! 📁";
          });

          return shelf.Response.ok(
            jsonEncode({"status": "success", "filename": fileName, "path": savedFile.path}),
            headers: {'Content-Type': 'application/json'},
          );
        } catch (e) {
          return shelf.Response.internalServerError(body: 'Erro ao salvar arquivo: $e');
        }
      });

      final handler = const shelf.Pipeline()
          .addMiddleware(shelf.logRequests())
          .middleware(router.call);

      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8080);
      
      final localIp = await _getLocalIpAddress();
      final port = _server?.port ?? 8080;

      setState(() {
        _currentIp = localIp;
        _serverStatus = "Servidor ativo em: http://$localIp:$port ✅";
      });
    } catch (e) {
      setState(() {
        _serverStatus = "Erro ao iniciar servidor: $e ❌";
      });
    }
  }

  @override
  void dispose() {
    _server?.close();
    super.dispose();
  }

  void _copyCurlExample() {
    final curlCommand = 'curl -X POST http://$_currentIp:8080/api/message \\\n -H "Content-Type: application/json" \\\n -d \'{"message": "Olá do Bash!"}\'';
    Clipboard.setData(ClipboardData(text: curlCommand));
    setState(() { _copiedCurl = true; });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() { _copiedCurl = false; });
    });
  }

  void _copyUploadCurlExample() {
    final curlCommand = 'curl -X POST http://$_currentIp:8080/api/upload \\\n -H "X-File-Name: foto.png" \\\n --data-binary "@caminho/para/seu/arquivo.png"';
    Clipboard.setData(ClipboardData(text: curlCommand));
    setState(() { _copiedUploadCurl = true; });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() { _copiedUploadCurl = false; });
    });
  }

  void _copyHelpCurlExample() {
    final curlCommand = 'curl http://$_currentIp:8080/api/help';
    Clipboard.setData(ClipboardData(text: curlCommand));
    setState(() { _copiedHelpCurl = true; });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() { _copiedHelpCurl = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2563EB);
    final curlExampleText = 'curl -X POST http://$_currentIp:8080/api/message \\\n -H "Content-Type: application/json" \\\n -d \'{"message": "Sua mensagem aqui"}\'';
    final uploadCurlText = 'curl -X POST http://$_currentIp:8080/api/upload \\\n -H "X-File-Name: nome_do_arquivo.ext" \\\n --data-binary "@seu_arquivo"';
    final helpCurlText = 'curl http://$_currentIp:8080/api/help';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          "Message & File Tool | API Ativa",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            tooltip: 'Home',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Início selecionado")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.mic, color: Colors.white),
            tooltip: 'Microfone',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Microfone acionado")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code, color: Colors.white),
            tooltip: 'QR Code',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Leitor de QR Code")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: 'Compartilhar',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Menu de Compartilhamento")),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'settings') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Abrindo Configurações...")),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'settings',
                child: Text('Configurações'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi, color: primaryColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _serverStatus,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.blueAccent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("📖 Ver Ajuda da API (cURL):", style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: _copyHelpCurlExample,
                        child: Text(_copiedHelpCurl ? "Copiado!" : "Copiar cURL", style: TextStyle(color: _copiedHelpCurl ? Colors.green : Colors.white70, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(helpCurlText, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("💻 Enviar Mensagem (cURL):", style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: _copyCurlExample,
                        child: Text(_copiedCurl ? "Copiado!" : "Copiar cURL", style: TextStyle(color: _copiedCurl ? Colors.green : Colors.white70, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(curlExampleText, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("📁 Enviar Arquivo para o App (cURL):", style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: _copyUploadCurlExample,
                        child: Text(_copiedUploadCurl ? "Copiado!" : "Copiar cURL", style: TextStyle(color: _copiedUploadCurl ? Colors.green : Colors.white70, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(uploadCurlText, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 11)),
                ],
              ),
            ),

            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Texto ou Log Recebido:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                GestureDetector(
                  onTap: _copyLogText,
                  child: Text(
                    _copiedLogText ? "Copiado! ✅" : "📋 Copiar Texto",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _copiedLogText ? Colors.green : primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            TextField(
              controller: _inputController,
              maxLines: 4,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("📂 Arquivos:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                Row(
                  children: [
                    // 1. Botão Enviar para outro Smart
                    ElevatedButton.icon(
                      onPressed: _showSendToIpDialog,
                      icon: const Icon(Icons.send, size: 14, color: Colors.white),
                      label: const Text("Enviar", style: TextStyle(fontSize: 11, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 6),
                    
                    // 2. Botão Importar Existente
                    ElevatedButton.icon(
                      onPressed: _pickAndImportFile,
                      icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      label: const Text("Importar", style: TextStyle(fontSize: 11, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            _receivedFiles.isEmpty
                ? const Text("Nenhum arquivo na pasta do app ainda.", style: TextStyle(color: Colors.grey, fontSize: 12))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _receivedFiles.length,
                    itemBuilder: (context, index) {
                      final file = _receivedFiles[index];
                      final fileName = file.uri.pathSegments.last;
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.insert_drive_file, color: primaryColor),
                        title: Text(fileName, style: const TextStyle(fontSize: 13)),
                        subtitle: const Text("Disponível na API", style: TextStyle(fontSize: 10)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.share, color: primaryColor, size: 20),
                              tooltip: "Compartilhar / Salvar",
                              onPressed: () => _shareFile(file),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              tooltip: "Apagar Arquivo",
                              onPressed: () => _deleteFile(file),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}