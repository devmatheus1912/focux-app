import 'dart:convert';

import 'package:file_picker/file_picker.dart';
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
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../utils/migracao_file_parser.dart';

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
  bool _isImportingFile = false;
  String? _importedFileLabel;
  List<Map<String, dynamic>>? _alunosEncontrados;
  bool _emptyResult = false;

  static const _passos = [
    'Importe .csv/.xlsx/.txt ou cole texto — planilha estruturada não precisa de IA',
    'Revise, edite ou remova linhas antes de confirmar',
    'Confirme e salve: duplicados são ignorados automaticamente',
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
      _importedFileLabel != null ||
      (_alunosEncontrados != null && _alunosEncontrados!.isNotEmpty);

  Future<void> _importarArquivo() async {
    if (_isLoading || _isImportingFile) return;

    setState(() => _isImportingFile = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'txt'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        FeedbackHelper.showError(
          context,
          'Não foi possível ler o arquivo selecionado.',
        );
        return;
      }

      final parsed = MigracaoFileParser.parse(
        bytes: bytes,
        filename: file.name,
      );

      if (parsed.usesDirectParse) {
        var alunos = parsed.directAlunos!;
        alunos = await _enriquecerComPreview(alunos) ?? alunos;
        if (!mounted) return;
        setState(() {
          _importedFileLabel = parsed.sourceLabel;
          _controller.clear();
          _alunosEncontrados = alunos;
          _emptyResult = alunos.isEmpty;
        });
        if (alunos.isNotEmpty) {
          FeedbackHelper.showSuccess(
            context,
            '${alunos.length} aluno(s) lidos de ${file.name}.',
          );
        }
        return;
      }

      final text = parsed.textForIa?.trim() ?? '';
      if (!mounted) return;
      setState(() {
        _importedFileLabel = parsed.sourceLabel;
        _controller.text = text;
        _alunosEncontrados = null;
        _emptyResult = false;
      });
      if (text.isEmpty) {
        FeedbackHelper.showError(context, 'Arquivo vazio ou ilegível.');
      } else {
        FeedbackHelper.showSuccess(
          context,
          'Texto carregado de ${file.name}. Toque Iniciar migração.',
        );
      }
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _isImportingFile = false);
    }
  }

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
      _importedFileLabel = null;
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
      var parsed = _parsarResultado(response.data['resultadoEstruturado']);
      parsed = await _enriquecerComPreview(parsed);
      setState(() {
        _alunosEncontrados = parsed;
        _emptyResult = parsed == null || parsed.isEmpty;
      });

      if (parsed != null && parsed.isNotEmpty && mounted) {
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

    final toSave =
        alunos.where((a) => a['duplicado'] != true).toList(growable: false);
    if (toSave.isEmpty) {
      FeedbackHelper.showError(
        context,
        'Todos os alunos já estão cadastrados. Remova duplicados ou edite e-mails.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.dio.post(
        '/api/v1/migracao/confirmar',
        data: {'alunos': toSave},
      );

      if (!mounted) return;
      await _mostrarResumoImportacao(
        Map<String, dynamic>.from(response.data as Map),
      );
      setState(() {
        _alunosEncontrados = null;
        _emptyResult = false;
        _importedFileLabel = null;
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

  Future<void> _mostrarResumoImportacao(Map<String, dynamic> data) async {
    final importados = data['importados'] ?? 0;
    final duplicados = data['duplicados'] ?? 0;
    final erros = data['erros'] ?? 0;
    final mensagem = (data['mensagem'] ?? '').toString();
    final detalhesRaw = data['detalhes'];
    final detalhes =
        detalhesRaw is List
            ? detalhesRaw.whereType<Map>().toList(growable: false)
            : const <Map>[];

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
        final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
        final brand = Theme.of(ctx).colorScheme.primary;

        Widget stat(String label, int value, Color color) {
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(TokensStrip.rSm),
              ),
              child: Column(
                children: [
                  Text(
                    '$value',
                    style: AppTypography.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: mute, height: 1.3),
                  ),
                ],
              ),
            ),
          );
        }

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
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: brand, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Importação concluída',
                        style: AppTypography.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                ),
                if (mensagem.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(mensagem, style: TextStyle(color: mute, height: 1.45)),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    stat('Importados', importados is int ? importados : int.tryParse('$importados') ?? 0, brand),
                    const SizedBox(width: 8),
                    stat(
                      'Duplicados',
                      duplicados is int ? duplicados : int.tryParse('$duplicados') ?? 0,
                      EagleTokens.warn,
                    ),
                    const SizedBox(width: 8),
                    stat(
                      'Erros',
                      erros is int ? erros : int.tryParse('$erros') ?? 0,
                      EagleTokens.bad,
                    ),
                  ],
                ),
                if (detalhes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: detalhes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final item = Map<String, dynamic>.from(detalhes[i]);
                        final nome = (item['nome'] ?? 'Aluno').toString();
                        final status = (item['status'] ?? '').toString();
                        final motivo = (item['motivo'] ?? '').toString();
                        Color badgeColor;
                        switch (status) {
                          case 'IMPORTADO':
                            badgeColor = brand;
                          case 'DUPLICADO':
                            badgeColor = EagleTokens.warn;
                          default:
                            badgeColor = EagleTokens.bad;
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: badgeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nome,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: ink,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (motivo.isNotEmpty)
                                    Text(
                                      motivo,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: mute,
                                        height: 1.35,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removerAluno(int index) {
    final alunos = _alunosEncontrados;
    if (alunos == null) return;
    setState(() {
      alunos.removeAt(index);
      if (alunos.isEmpty) _alunosEncontrados = null;
    });
  }

  Future<void> _editarAluno(int index) async {
    final alunos = _alunosEncontrados;
    if (alunos == null || index < 0 || index >= alunos.length) return;

    final aluno = alunos[index];
    final nomeCtrl = TextEditingController(
      text: (aluno['nome'] ?? '').toString(),
    );
    final emailCtrl = TextEditingController(
      text: (aluno['email'] ?? '').toString(),
    );
    final telCtrl = TextEditingController(
      text: (aluno['telefone'] ?? '').toString(),
    );
    final objCtrl = TextEditingController(
      text: (aluno['objetivo'] ?? '').toString(),
    );

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;

        return Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Editar aluno',
                style: AppTypography.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nomeCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: FxInputDeco.build(ctx, 'Nome'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: FxInputDeco.build(ctx, 'E-mail (opcional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telCtrl,
                keyboardType: TextInputType.phone,
                decoration: FxInputDeco.build(ctx, 'Telefone (opcional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: objCtrl,
                decoration: FxInputDeco.build(ctx, 'Objetivo (opcional)'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salvar alterações'),
              ),
            ],
          ),
        );
      },
    );

    if (saved != true || !mounted) {
      nomeCtrl.dispose();
      emailCtrl.dispose();
      telCtrl.dispose();
      objCtrl.dispose();
      return;
    }

    final updated = <String, dynamic>{
      'nome':
          nomeCtrl.text.trim().isEmpty
              ? 'Aluno importado'
              : nomeCtrl.text.trim(),
    };
    if (emailCtrl.text.trim().isNotEmpty) {
      updated['email'] = emailCtrl.text.trim();
    }
    if (telCtrl.text.trim().isNotEmpty) {
      updated['telefone'] = telCtrl.text.trim();
    }
    if (objCtrl.text.trim().isNotEmpty) {
      updated['objetivo'] = objCtrl.text.trim();
    }

    nomeCtrl.dispose();
    emailCtrl.dispose();
    telCtrl.dispose();
    objCtrl.dispose();

    final enriched = await _enriquecerComPreview([updated]);
    setState(() {
      alunos[index] = enriched?.first ?? updated;
    });
  }

  Future<List<Map<String, dynamic>>?> _enriquecerComPreview(
    List<Map<String, dynamic>>? alunos,
  ) async {
    if (alunos == null || alunos.isEmpty) return alunos;
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.dio.post(
        '/api/v1/migracao/preview',
        data: {'alunos': alunos},
      );
      final preview = response.data['alunos'];
      if (preview is List) {
        return preview
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (_) {
      // Preview é enriquecimento; fallback mantém lista da IA.
    }
    return alunos;
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

  Duration _motionDuration(BuildContext context) =>
      TokensStrip.prefersReducedMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 280);

  Widget _stagger(
    BuildContext context, {
    required int index,
    required Widget child,
    Key? key,
  }) {
    final reduce = TokensStrip.prefersReducedMotion(context);
    return FxStaggerItem(
      key: key,
      index: index,
      staggerDelay:
          reduce ? Duration.zero : const Duration(milliseconds: 60),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 400),
      slideOffset: reduce ? 0 : 20,
      child: child,
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
              _stagger(
                context,
                index: 0,
                child: Semantics(
                  header: true,
                  label:
                      'Importe alunos com IA usando planilha ou texto colado.',
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
                        'Importe alunos com IA',
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
                        'Importe planilha (.csv, .xlsx) ou cole texto — a IA estrutura o resto. '
                        'Você revisa e confirma antes de salvar.',
                        style: TextStyle(fontSize: 14, color: mute, height: 1.55),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: TokensStrip.s4),
              _stagger(
                context,
                index: 1,
                child: Semantics(
                  label: 'Como funciona em três passos',
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
                        return Semantics(
                          label: 'Passo ${entry.key + 1}. ${entry.value}',
                          child: Padding(
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
                        ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              ),
              const SizedBox(height: TokensStrip.s4),
              _stagger(
                context,
                index: 2,
                child: Container(
                  padding: const EdgeInsets.all(TokensStrip.s4),
                  decoration: fxListCardDecoration(context, accent: brand),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Importar dados',
                        style: AppTypography.inter(
                          fontSize: 13,
                          color: ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Planilha estruturada vai direto para revisão. Texto livre usa IA.',
                        style: TextStyle(fontSize: 12, color: mute, height: 1.35),
                      ),
                      if (_importedFileLabel != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: brandSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.insert_drive_file_rounded, size: 14, color: brand),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _importedFileLabel!,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: brand,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: TokensStrip.s3),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  (_isLoading || _isImportingFile)
                                      ? null
                                      : _importarArquivo,
                              icon:
                                  _isImportingFile
                                      ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: brand,
                                        ),
                                      )
                                      : const Icon(Icons.upload_file_rounded, size: 18),
                              label: Text(
                                _isImportingFile ? 'Lendo...' : 'Importar arquivo',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: _isLoading ? null : _colarClipboard,
                              icon: const Icon(Icons.content_paste_go_rounded, size: 18),
                              label: const Text('Colar texto'),
                            ),
                          ),
                        ],
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
                duration: _motionDuration(context),
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
      return _stagger(
        context,
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

    return _stagger(
      context,
      key: key,
      index: 3,
      child: Padding(
        padding: const EdgeInsets.only(top: TokensStrip.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              label: '${alunos.length} alunos encontrados para revisão. Toque para editar.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${alunos.length} alunos encontrados',
                    style: AppTypography.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toque para editar · remova duplicados antes de salvar',
                    style: TextStyle(fontSize: 12, color: mute, height: 1.35),
                  ),
                ],
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
              final duplicado = aluno['duplicado'] == true;
              final meta = [
                if (email.isNotEmpty) email,
                if (telefone.isNotEmpty) telefone,
                if (objetivo.isNotEmpty) objetivo,
              ].join(' · ');

              return Padding(
                padding: const EdgeInsets.only(bottom: TokensStrip.s2),
                child: Semantics(
                  label:
                      duplicado
                          ? 'Aluno $nome duplicado. $meta. Toque para editar.'
                          : 'Aluno $nome. $meta. Toque para editar.',
                  button: true,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _editarAluno(index),
                      borderRadius: BorderRadius.circular(TokensStrip.rCard),
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
                              if (duplicado) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: EagleTokens.warnSoft,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Já cadastrado',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: EagleTokens.warn,
                                    ),
                                  ),
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
                  ),
                ),
              );
            }),
            const SizedBox(height: TokensStrip.s3),
            FxLiquidPrimaryButton(
              label: 'Confirmar e salvar ${alunos.where((a) => a['duplicado'] != true).length} alunos',
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
