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
        Uri.parse('http://$host:8080/api/v1/transactions'),
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
      messenger.showSnackBar(SnackBar(content: Text('Erro ao conectar em $host')));
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
                  const Text("Valor (R\$)"), 
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
                    Text("ID: ${_result!['transactionId'] ?? '---'}", style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
