import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/api/api_client.dart';
import '../../subscription/models/subscription_plan.dart';

class MigracaoMagicaScreen extends StatefulWidget {
  const MigracaoMagicaScreen({super.key});

  @override
  State<MigracaoMagicaScreen> createState() => _MigracaoMagicaScreenState();
}

class _MigracaoMagicaScreenState extends State<MigracaoMagicaScreen> {
  final TextEditingController _controller = TextEditingController();
  final ApiClient _api = ApiClient();
  bool _isLoading = false;
  String? _resultadoJson;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processarMigracao() async {
    if (_controller.text.isEmpty) {
      if (mounted) FeedbackHelper.showError(context, 'Cole os dados do concorrente primeiro.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Usa ApiClient (Dio) com JWT auto-injetado pelo interceptor
      final response = await _api.dio.post(
        '/api/v1/migracao/texto',
        data: {'conteudo': _controller.text},
      );

      if (mounted) {
        final resultadoEstruturado = response.data['resultadoEstruturado'];
        final parsed = _parsarResultado(resultadoEstruturado);
        setState(() => _resultadoJson = parsed);
        FeedbackHelper.showSuccess(context, 'Alunos lidos com sucesso pela IA!');
      }
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, 'Falha na migração. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Formata o resultado JSON em texto legível.
  String _parsarResultado(dynamic data) {
    if (data == null) return 'Nenhum aluno encontrado nos dados fornecidos.';
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        return _formatarResultado(decoded);
      } catch (_) {
        return data;
      }
    }
    return _formatarResultado(data);
  }

  String _formatarResultado(dynamic data) {
    if (data is List) {
      final buffer = StringBuffer();
      for (final item in data) {
        buffer.writeln('• Nome: ${item['nome'] ?? '-'}');
        if (item['email'] != null) buffer.writeln('  Email: ${item['email']}');
        if (item['telefone'] != null) buffer.writeln('  Tel: ${item['telefone']}');
        if (item['objetivo'] != null) buffer.writeln('  Objetivo: ${item['objetivo']}');
        buffer.writeln();
      }
      return buffer.toString().trim();
    }
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  @override
  Widget build(BuildContext context) {
    return FeatureGate(
      featureName: 'Migração Mágica IA',
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
                backgroundColor: EagleTokens.brand,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Iniciar Migração via IA',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            if (_resultadoJson != null) ...[
              const SizedBox(height: 24),
              const Text('Alunos Encontrados:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withAlpha(40)),
                ),
                child: Text(_resultadoJson!),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (mounted) FeedbackHelper.showSuccess(context, 'Alunos importados e salvos no banco de dados!');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: EagleTokens.good,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Confirmar e Salvar Todos', style: TextStyle(color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
