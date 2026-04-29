import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../subscription/models/subscription_plan.dart';

// BUG-03: ConumerStatefulWidget para acesso ao ref (apiClientProvider autenticado)
class MigracaoMagicaScreen extends ConsumerStatefulWidget {
  const MigracaoMagicaScreen({super.key});

  @override
  ConsumerState<MigracaoMagicaScreen> createState() =>
      _MigracaoMagicaScreenState();
}

class _MigracaoMagicaScreenState extends ConsumerState<MigracaoMagicaScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;
  List<dynamic>? _alunosEncontrados;

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
      // BUG-03: usa cliente autenticado via ref
      final api = ref.read(apiClientProvider);
      final response = await api.dio.post(
        '/api/v1/migracao/texto',
        data: {'conteudo': _controller.text},
      );

      if (mounted) {
        final resultadoEstruturado = response.data['resultadoEstruturado'];
        setState(() {
          _alunosEncontrados = _parsarResultado(resultadoEstruturado);
        });
        if (_alunosEncontrados != null && _alunosEncontrados!.isNotEmpty) {
          FeedbackHelper.showSuccess(context, 'Alunos lidos com sucesso pela IA!');
        } else {
          FeedbackHelper.showError(context, 'A IA não encontrou alunos. Revise o texto.');
        }
      }
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, 'Falha na migração. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // BUG-04: chama /confirmar para realmente salvar no DB
  Future<void> _salvarAlunos() async {
    if (_alunosEncontrados == null || _alunosEncontrados!.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.dio.post(
        '/api/v1/migracao/confirmar',
        data: {'alunos': _alunosEncontrados},
      );

      if (mounted) {
        final importados = response.data['importados'] ?? _alunosEncontrados!.length;
        FeedbackHelper.showSuccess(
          context,
          '$importados aluno(s) importado(s) com sucesso!',
        );
        setState(() {
          _alunosEncontrados = null;
          _controller.clear();
        });
      }
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, 'Erro ao salvar alunos. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  List<dynamic>? _parsarResultado(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map && decoded.containsKey('alunos')) {
          final lista = decoded['alunos'];
          if (lista is List) return lista;
        }
        if (decoded is List) return decoded;
      } catch (_) {
        return null;
      }
    }
    if (data is Map && data.containsKey('alunos')) {
      final lista = data['alunos'];
      if (lista is List) return lista;
    }
    if (data is List) return data;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FeatureGate(
      featureName: 'Migração Mágica IA',
      requiredPlan: SubscriptionPlan.PREMIUM,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final brand = Theme.of(context).colorScheme.primary;
    final brandDeep = BrandPalette.deep(brand);
    final brandSoft = BrandPalette.soft(brand, dark: isDark);
    final brandSofter = BrandPalette.softer(brand, dark: isDark);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: ink),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.15) : brandSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.auto_awesome, size: 16, color: brand),
                      ),
                      const SizedBox(width: 8),
                      Text('IA FOCUX', style: TextStyle(fontSize: 12, color: brand, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Migração Mágica ✨', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.5, height: 1.1)),
                  const SizedBox(height: 6),
                  Text('Traga seus alunos de qualquer app. Cole o texto e a IA extrai tudo automaticamente.', style: TextStyle(fontSize: 14, color: mute, height: 1.55)),
                ],
              ),
            ),

            // Hero Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: isDark ? LinearGradient(colors: [brandDeep, const Color(0xFF0A0F1E)]) : LinearGradient(colors: [brand, brandDeep]),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Como funciona', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 10),
                    ...['Cole PDF, Excel ou print de outro app', 'A IA lê e extrai nome, email, telefone e objetivo', 'Confirme e todos os alunos são salvos no Focux'].asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text('${entry.key + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'monospace')),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(entry.value, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.82), height: 1.4))),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Text paste area
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DADOS BAGUNÇADOS', style: TextStyle(fontSize: 12, color: mute, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : brandSofter,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? EagleTokens.darkLine : brand.withValues(alpha: 0.12)),
                      ),
                      child: TextField(
                        controller: _controller,
                        maxLines: 8,
                        minLines: 4,
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: mute, height: 1.6),
                        decoration: InputDecoration.collapsed(
                          hintText: 'Beatriz Carvalho — 28 anos — (11)99999-1111 — bia@gmail.com — objetivo: hipertrofia\nLucas Andrade, 34, lucas@gmail.com, emagrecimento\n...',
                          hintStyle: TextStyle(color: mute.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _isLoading ? null : _processarMigracao,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: brand,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: brand.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 4))],
                        ),
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                  SizedBox(width: 10),
                                  Text('Conectando ao servidor IA...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                                ],
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_awesome, color: Colors.white, size: 15),
                                  const SizedBox(width: 6),
                                  const Text('Iniciar migração', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Results
            if (_alunosEncontrados != null && _alunosEncontrados!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text('${_alunosEncontrados!.length} alunos encontrados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ink, letterSpacing: -0.5)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: _alunosEncontrados!.map((a) {
                    final nome = a['nome'] ?? 'Desconhecido';
                    final email = a['email'] ?? '';
                    final obj = a['objetivo'] ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: line),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(color: isDark ? brandDeep : brand, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text(nome.toString().isNotEmpty ? nome.toString()[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nome, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 1),
                                Text('$email ${obj.isNotEmpty ? '· $obj' : ''}'.trim(), style: TextStyle(fontSize: 11.5, color: mute), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0x266FE296) : EagleTokens.goodSoft,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(Icons.check, size: 16, color: isDark ? const Color(0xFF6FE296) : EagleTokens.good),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: InkWell(
                  // BUG-04: chama API real
                  onTap: _isSaving ? null : _salvarAlunos,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A3A1A) : EagleTokens.goodSoft,
                      border: Border.all(color: isDark ? const Color(0xFF2BB673) : EagleTokens.good, width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, size: 16, color: isDark ? const Color(0xFF6FE296) : EagleTokens.good),
                              const SizedBox(width: 8),
                              Text('Confirmar e salvar ${_alunosEncontrados!.length} alunos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF6FE296) : EagleTokens.good)),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
