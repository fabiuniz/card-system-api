import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/http_server.dart';
import 'apps_webview_screen.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final HttpService _httpService = HttpService();
  final TextEditingController _inputController = TextEditingController(
    text: "Aguardando mensagens ou arquivos...",
  );
  bool _copiedCurl = false;
  bool _copiedUploadCurl = false;
  bool _copiedHelpCurl = false;
  bool _copiedLogText = false;
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

  void _showSendToIpDialog() {
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              String targetIp = ipController.text.trim();
              if (targetIp.isEmpty) return;

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
      final directory = await _httpService.getStorageDirectory();
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

        final directory = await _httpService.getStorageDirectory();
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

  Future<void> _startHttpServer() async {
    await _httpService.startServer(
      currentIp: _currentIp,
      onMessageReceived: (message, status) {
        setState(() {
          _inputController.text = message;
          _serverStatus = status;
        });
      },
      onFileReceived: (savedFile, status) {
        setState(() {
          if (!_receivedFiles.any((f) => f.path == savedFile.path)) {
            _receivedFiles.add(savedFile);
          }
          _inputController.text = "Arquivo recebido: ${savedFile.uri.pathSegments.last}\nSalvo em: ${savedFile.path}";
          _serverStatus = status;
        });
      },
      onStarted: (localIp, status) {
        setState(() {
          _currentIp = localIp;
          _serverStatus = status;
        });
      },
      onError: (errorStatus) {
        setState(() {
          _serverStatus = errorStatus;
        });
      },
    );
  }

  @override
  void dispose() {
    _httpService.close();
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
            tooltip: 'Apps Home',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppsWebViewScreen(),
                ),
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