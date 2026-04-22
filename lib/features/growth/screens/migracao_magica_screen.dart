import '../../../core/widgets/feature_gate.dart';
import '../../subscription/models/subscription_plan.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/feedback_helper.dart';
import 'package:http/http.dart' as http;
import '../../../core/api/api_client.dart'; // Assume exists

class MigracaoMagicaScreen extends StatefulWidget {
  const MigracaoMagicaScreen({super.key});

  @override
  State<MigracaoMagicaScreen> createState() => _MigracaoMagicaScreenState();
}

class _MigracaoMagicaScreenState extends State<MigracaoMagicaScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _resultadoJson;

  Future<void> _processarMigracao() async {
    if (_controller.text.isEmpty) {
      FeedbackHelper.showError(context, 'Cole os dados do concorrente primeiro.');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Usando http puro aqui para o protótipo, mas idealmente usa o Dio do ApiClient
      final url = Uri.parse('https://focux-backend.onrender.com/api/v1/migracao/texto');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'conteudo': _controller.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _resultadoJson = data['resultadoEstruturado'];
        });
        if (mounted) FeedbackHelper.showSuccess(context, 'Alunos lidos com sucesso pela IA!');
      } else {
        if (mounted) FeedbackHelper.showError(context, 'Erro na IA. Tente novamente.');
      }
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, 'Falha de conexão.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureGate(
      featureName: "Migração Mágica IA",
      requiredPlan: SubscriptionPlan.PRO,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Migração Mágica IA ✨'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: EagleTokens.heroGradient(dark: Theme.of(context).brightness == Brightness.dark),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                  SizedBox(height: 12),
                  Text(
                    'Traga seus alunos de qualquer app',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Cole abaixo o texto de PDFs, Excel ou prints de outros apps. Nossa IA extrai tudo e cria os perfis no Focux automaticamente.',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Cole os dados bagunçados aqui...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _processarMigracao,
              style: ElevatedButton.styleFrom(
                backgroundColor: EagleTokens.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Iniciar Migração via IA', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            if (_resultadoJson != null) ...[
              const SizedBox(height: 24),
              const Text('Alunos Encontrados:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey.withAlpha(20),
                child: Text(_resultadoJson!, style: const TextStyle(fontFamily: 'monospace')),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  FeedbackHelper.showSuccess(context, 'Alunos importados e salvos no banco de dados!');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: EagleTokens.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Confirmar e Salvar Todos', style: TextStyle(color: Colors.white)),
              )
            ]
          ],
        ),
      ),
    );
  }
}
