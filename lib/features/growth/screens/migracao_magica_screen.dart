import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../subscription/models/subscription_plan.dart';

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
  List<Map<String, dynamic>>? _alunosEncontrados;
  bool _emptyResult = false;

  static const _passos = [
    'Cole texto exportado, print ou planilha copiada de outro app',
    'A IA extrai nome, e-mail, telefone e objetivo',
    'Revise a lista, remova o que não quiser e confirme no Focux',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onDraftChanged);
  }

  void _onDraftChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onDraftChanged)
      ..dispose();
    super.dispose();
  }

  bool get _hasUnsavedWork =>
      _controller.text.trim().isNotEmpty ||
      (_alunosEncontrados != null && _alunosEncontrados!.isNotEmpty);

  Future<void> _colarClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      if (!mounted) return;
      FeedbackHelper.showError(context, 'Nada para colar da área de transferência.');
      return;
    }
    setState(() {
      _controller.text = text;
      _emptyResult = false;
      _alunosEncontrados = null;
    });
  }

  Future<void> _processarMigracao() async {
    if (_controller.text.trim().isEmpty) {
      FeedbackHelper.showError(context, 'Cole os dados dos alunos primeiro.');
      return;
    }

    setState(() {
      _isLoading = true;
      _emptyResult = false;
      _alunosEncontrados = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.dio.post(
        '/api/v1/migracao/texto',
        data: {'conteudo': _controller.text.trim()},
      );

      if (!mounted) return;
      final parsed = _parsarResultado(response.data['resultadoEstruturado']);
      setState(() {
        _alunosEncontrados = parsed;
        _emptyResult = parsed == null || parsed.isEmpty;
      });

      if (parsed != null && parsed.isNotEmpty) {
        FeedbackHelper.showSuccess(
          context,
          '${parsed.length} aluno(s) identificado(s) pela IA.',
        );
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
        setState(() => _emptyResult = false);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _salvarAlunos() async {
    final alunos = _alunosEncontrados;
    if (alunos == null || alunos.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.dio.post(
        '/api/v1/migracao/confirmar',
        data: {'alunos': alunos},
      );

      if (!mounted) return;
      final importados = response.data['importados'] ?? alunos.length;
      FeedbackHelper.showSuccess(
        context,
        '$importados aluno(s) importado(s) com sucesso.',
      );
      setState(() {
        _alunosEncontrados = null;
        _emptyResult = false;
        _controller.clear();
      });
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _removerAluno(int index) {
    final alunos = _alunosEncontrados;
    if (alunos == null) return;
    setState(() {
      alunos.removeAt(index);
      if (alunos.isEmpty) _alunosEncontrados = null;
    });
  }

  List<Map<String, dynamic>>? _parsarResultado(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        return _parsarResultado(decoded);
      } catch (_) {
        return null;
      }
    }
    if (data is Map && data.containsKey('alunos')) {
      final lista = data['alunos'];
      if (lista is List) return _normalizarLista(lista);
    }
    if (data is List) return _normalizarLista(data);
    return null;
  }

  List<Map<String, dynamic>>? _normalizarLista(List lista) {
    if (lista.isEmpty) return [];
    return lista
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TokensStrip.rCard),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Sair da migração?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  'Há texto ou alunos revisados que ainda não foram salvos.',
                  style: TextStyle(
                    height: 1.45,
                    color: Theme.of(ctx).brightness == Brightness.dark
                        ? EagleTokens.darkInkMute
                        : TokensStrip.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Continuar migração'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: EagleTokens.bad,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Sair sem salvar'),
                ),
              ],
            ),
          ),
        );
      },
    );
    return discard ?? false;
  }

  Future<void> _handleBack() async {
    if (!_hasUnsavedWork) {
      safePopOrGo(context, '/dashboard/personal');
      return;
    }
    final discard = await _confirmDiscard();
    if (discard && mounted) safePopOrGo(context, '/dashboard/personal');
  }

  @override
  Widget build(BuildContext context) {
    return FeatureGate(
      featureName: 'Migração Focux',
      requiredPlan: SubscriptionPlan.PREMIUM,
      capability: 'iaCopiloto',
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final brand = Theme.of(context).colorScheme.primary;
    final brandDeep = BrandPalette.deep(brand);
    final brandSoft = BrandPalette.soft(brand, dark: isDark);
    final brandSofter = BrandPalette.softer(brand, dark: isDark);
    final alunos = _alunosEncontrados;

    return PopScope(
      canPop: !_hasUnsavedWork,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack();
      },
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Migração Focux',
          onBack: _handleBack,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            TokensStrip.s4,
            TokensStrip.s2,
            TokensStrip.s4,
            TokensStrip.s6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxStaggerItem(
                index: 0,
                child: Semantics(
                  header: true,
                  label:
                      'Migração Focux. Traga alunos de outro app colando texto desestruturado.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : brandSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: brand,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'IA FOCUX',
                            style: TextStyle(
                              fontSize: 12,
                              color: brand,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TokensStrip.s2),
                      Text(
                        'Migração Focux',
                        style: AppTypography.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: ink,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Traga seus alunos de qualquer app. Cole o texto e a IA extrai tudo automaticamente.',
                        style: TextStyle(fontSize: 14, color: mute, height: 1.55),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: TokensStrip.s4),
              FxStaggerItem(
                index: 1,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    TokensStrip.s5,
                    20,
                    TokensStrip.s5,
                    18,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient:
                        isDark
                            ? LinearGradient(
                              colors: [brandDeep, const Color(0xFF080C10)],
                            )
                            : LinearGradient(colors: [brand, brandDeep]),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Como funciona',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._passos.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${entry.key + 1}',
                                  style: AppTypography.mono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.88),
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: TokensStrip.s4),
              FxStaggerItem(
                index: 2,
                child: Container(
                  padding: const EdgeInsets.all(TokensStrip.s4),
                  decoration: fxListCardDecoration(context, accent: brand),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dados desestruturados',
                        style: AppTypography.inter(
                          fontSize: 13,
                          color: ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cole linhas soltas, exportações ou prints transcritos.',
                        style: TextStyle(fontSize: 12, color: mute, height: 1.35),
                      ),
                      const SizedBox(height: TokensStrip.s3),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _isLoading ? null : _colarClipboard,
                          icon: const Icon(Icons.content_paste_go_rounded, size: 18),
                          label: const Text('Colar da área de transferência'),
                        ),
                      ),
                      Semantics(
                        label: 'Campo para colar dados desestruturados dos alunos',
                        child: Container(
                          padding: const EdgeInsets.all(TokensStrip.s3),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : brandSofter,
                            borderRadius: BorderRadius.circular(TokensStrip.rSm),
                            border: Border.all(
                              color:
                                  isDark
                                      ? EagleTokens.darkLine
                                      : brand.withValues(alpha: 0.18),
                            ),
                          ),
                          child: TextField(
                            controller: _controller,
                            maxLines: 8,
                            minLines: 4,
                            style: AppTypography.mono(
                              fontSize: 13,
                              color: ink,
                              height: 1.6,
                            ),
                            decoration: InputDecoration.collapsed(
                              hintText:
                                  'Beatriz Carvalho — 28 anos — (11)99999-1111 — bia@gmail.com — objetivo: hipertrofia\n'
                                  'Lucas Andrade, 34, lucas@gmail.com, emagrecimento\n...',
                              hintStyle: TextStyle(
                                color: mute.withValues(alpha: 0.72),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: TokensStrip.s3),
                      FxLiquidPrimaryButton(
                        label: 'Iniciar migração',
                        icon: Icons.auto_awesome,
                        loading: _isLoading,
                        loadingLabel: 'Conectando à IA...',
                        onPressed: _isLoading ? null : _processarMigracao,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _buildResultsSection(
                  key: ValueKey(
                    '${alunos?.length ?? 0}-$_emptyResult',
                  ),
                  isDark: isDark,
                  ink: ink,
                  mute: mute,
                  brand: brand,
                  brandDeep: brandDeep,
                  alunos: alunos,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection({
    required Key key,
    required bool isDark,
    required Color ink,
    required Color mute,
    required Color brand,
    required Color brandDeep,
    required List<Map<String, dynamic>>? alunos,
  }) {
    if (_emptyResult) {
      return FxStaggerItem(
        key: key,
        index: 3,
        child: Padding(
          padding: const EdgeInsets.only(top: TokensStrip.s4),
          child: Container(
            padding: const EdgeInsets.all(TokensStrip.s4),
            decoration: fxListCardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.search_off_rounded, color: mute, size: 28),
                const SizedBox(height: 10),
                Text(
                  'Nenhum aluno identificado',
                  style: AppTypography.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Revise o texto colado e tente novamente com mais linhas ou campos visíveis.',
                  style: TextStyle(color: mute, height: 1.45),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (alunos == null || alunos.isEmpty) {
      return SizedBox(key: key);
    }

    return FxStaggerItem(
      key: key,
      index: 3,
      child: Padding(
        padding: const EdgeInsets.only(top: TokensStrip.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              label: '${alunos.length} alunos encontrados para revisão',
              child: Text(
                '${alunos.length} alunos encontrados',
                style: AppTypography.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ink,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: TokensStrip.s3),
            ...alunos.asMap().entries.map((entry) {
              final index = entry.key;
              final aluno = entry.value;
              final nome = (aluno['nome'] ?? 'Desconhecido').toString();
              final email = (aluno['email'] ?? '').toString();
              final telefone = (aluno['telefone'] ?? '').toString();
              final objetivo = (aluno['objetivo'] ?? '').toString();
              final meta = [
                if (email.isNotEmpty) email,
                if (telefone.isNotEmpty) telefone,
                if (objetivo.isNotEmpty) objetivo,
              ].join(' · ');

              return Padding(
                padding: const EdgeInsets.only(bottom: TokensStrip.s2),
                child: Semantics(
                  label: 'Aluno $nome. $meta',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: fxListCardDecoration(context, accent: brand),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isDark ? brandDeep : brand,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nome,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (meta.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  meta,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: mute,
                                    height: 1.35,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remover da lista',
                          onPressed: () => _removerAluno(index),
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: mute,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: TokensStrip.s3),
            FxLiquidPrimaryButton(
              label: 'Confirmar e salvar ${alunos.length} alunos',
              icon: Icons.check_rounded,
              loading: _isSaving,
              loadingLabel: 'Salvando alunos...',
              onPressed: _isSaving ? null : _salvarAlunos,
            ),
          ],
        ),
      ),
    );
  }
}
