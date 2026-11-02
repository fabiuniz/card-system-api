import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class HttpService {
  HttpServer? server;

  Future<Directory?> getStorageDirectory() async {
    if (Platform.isAndroid) {
      return await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }

  Future<String> getLocalIpAddress() async {
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

  Future<void> startServer({
    required String currentIp,
    required Function(String message, String status) onMessageReceived,
    required Function(File file, String status) onFileReceived,
    required Function(String localIp, String serverStatus) onStarted,
    required Function(String errorStatus) onError,
  }) async {
    if (server != null) return;

    try {
      final router = shelf_router.Router();

      router.get('/api/help', (shelf.Request request) async {
        final ip = currentIp;
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
          final directory = await getStorageDirectory();
          if (directory == null || !await directory.exists()) {
            return shelf.Response.ok("Nenhum arquivo encontrado.\n", headers: {'Content-Type': 'text/plain; charset=utf-8'});
          }

          final buffer = StringBuffer();
          buffer.writeln("==================================================");
          buffer.writeln("         ARQUIVOS DISPONÍVEIS PARA DOWNLOAD");
          buffer.writeln("==================================================");
          buffer.writeln("${'ARQUIVO'.padRight(45)} \vert{}${'TAMANHO'.padRight(10)}");
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

              buffer.writeln("${name.padRight(45)} \vert{}${sizeStr.padRight(10)}");
            }
          }

          if (count == 0) {
            return shelf.Response.ok("Nenhum arquivo recebido ainda.\n", headers: {'Content-Type': 'text/plain; charset=utf-8'});
          }

          buffer.writeln("==================================================");
          buffer.writeln("Dica: Use 'curl -O http://$currentIp:8080/api/files/NOME' para baixar.");

          return shelf.Response.ok(
            buffer.toString(),
            headers: {'Content-Type': 'text/plain; charset=utf-8'},
          );
        } catch (e) {
          return shelf.Response.internalServerError(body: "Erro ao listar arquivos: $e");
        }
      });
// Rota para servir o apps.htm e qualquer arquivo da pasta assets dinamicamente via HTTP
      router.get('/assets/<path|.*>', (shelf.Request request, String path) async {
        try {
          // Normaliza o caminho do asset
          final assetPath = 'assets/$path';
          
          // Carrega o arquivo dos assets do Flutter
          final byteData = await rootBundle.load(assetPath);
          final bytes = byteData.buffer.asUint8List();

          // Define o Content-Type correto baseado na extensão
          String contentType = 'text/plain';
          if (path.endsWith('.html') || path.endsWith('.htm')) {
            contentType = 'text/html; charset=utf-8';
          } else if (path.endsWith('.css')) {
            contentType = 'text/css; charset=utf-8';
          } else if (path.endsWith('.js')) {
            contentType = 'application/javascript; charset=utf-8';
          } else if (path.endsWith('.png')) {
            contentType = 'image/png';
          } else if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
            contentType = 'image/jpeg';
          }

          return shelf.Response.ok(
            bytes,
            headers: {'Content-Type': contentType},
          );
        } catch (e) {
          return shelf.Response.notFound('Arquivo não encontrado nos assets: $path');
        }
      });
      
      router.get('/api/files/<name>', (shelf.Request request, String name) async {
        try {
          final directory = await getStorageDirectory();
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

          final timeStr = DateTime.now().toLocal().toString().substring(11, 19);
          onMessageReceived(message, "Mensagem recebida às $timeStr");

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
          
          final directory = await getStorageDirectory();
          if (!await directory!.exists()) {
            await directory.create(recursive: true);
          }
          
          final savedFile = File('${directory.path}/$fileName');
          await savedFile.writeAsBytes(bodyBytes);

          onFileReceived(savedFile, "Arquivo recebido com sucesso! 📁");

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

      server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8080);
      
      final localIp = await getLocalIpAddress();
      final port = server?.port ?? 8080;

      onStarted(localIp, "Servidor ativo em: http://$localIp:$port ✅");
    } catch (e) {
      onError("Erro ao iniciar servidor: $e ❌");
    }
  }

  void close() {
    server?.close();
  }
}