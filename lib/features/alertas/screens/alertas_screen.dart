import 'package:flutter/material.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/alertas_repository.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../dashboard/utils/dashboard_readability.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

class AlertasScreen extends ConsumerStatefulWidget {
  const AlertasScreen({super.key});

  @override
  ConsumerState<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends ConsumerState<AlertasScreen> {
  List<AlertaRisco> _alertas = [];
  AlertasConfiguracao? _config;
  bool _loading = true;
  String? _erro;
  int? _filtroScoreMin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final repo = AlertasRepository(ref.read(apiClientProvider));
      final results = await Future.wait([
        repo.listarRiscos(),
        repo.getConfiguracao(),
      ]);
      if (mounted) {
        setState(() {
          _alertas = results[0] as List<AlertaRisco>;
          _config = results[1] as AlertasConfiguracao;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = friendlyError(e);
        });
      }
    }
  }

  Future<void> _editarConfiguracao() async {
    if (_config == null) return;
    int dias = _config!.diasSemTreino;
    int aderencia = _config!.aderenciaMinima;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, set) => AlertDialog(
                  title: const Text('Configurar Alertas'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Dias sem treino: $dias'),
                      Slider(
                        value: dias.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        label: '$dias dias',
                        onChanged: (v) => set(() => dias = v.toInt()),
                      ),
                      const SizedBox(height: 8),
                      Text('Aderência mínima: $aderencia%'),
                      Slider(
                        value: aderencia.toDouble(),
                        min: 10,
                        max: 100,
                        divisions: 18,
                        label: '$aderencia%',
                        onChanged: (v) => set(() => aderencia = v.toInt()),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    FxLiquidPrimaryButton(
                      label: 'Salvar',
                      expand: false,
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ],
                ),
          ),
    );
    if (confirm != true) return;
    try {
      await AlertasRepository(
        ref.read(apiClientProvider),
      ).atualizarConfiguracao(dias, aderencia);
      _load();
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _resolverAlerta(AlertaRisco alerta) async {
    try {
      await AlertasRepository(
        ref.read(apiClientProvider),
      ).resolver(alerta.alunoId);
      setState(() => _alertas.removeWhere((a) => a.alunoId == alerta.alunoId));
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Alerta resolvido!');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _enviarMensagemChat(AlertaRisco alerta) async {
    final ctrl = TextEditingController(
      text:
          'Olá ${alerta.alunoNome.split(' ').first}! Vi que faz um tempo que não treina. Que tal retomarmos hoje? 💪',
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Enviar mensagem'),
            content: TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                border: FxInputDeco.outlineBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FxLiquidPrimaryButton(
                label: 'Enviar',
                icon: Icons.send,
                expand: false,
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
    );

    if (confirm != true || ctrl.text.trim().isEmpty) return;

    try {
      await AlertasRepository(
        ref.read(apiClientProvider),
      ).enviarMensagemChat(alerta.alunoId, ctrl.text.trim());
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Mensagem enviada!');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  List<AlertaRisco> get _filtrados {
    if (_filtroScoreMin == null) return _alertas;
    return _alertas.where((a) => a.score >= _filtroScoreMin!).toList();
  }

  Color _scoreColor(int s, bool isDark) =>
      s >= 2
          ? EagleTokens.semanticBad(isDark: isDark)
          : EagleTokens.semanticWarn(isDark: isDark);

  Color _scoreBg(int s, bool isDark) =>
      s >= 2
          ? EagleTokens.semanticBadSoft(isDark: isDark)
          : EagleTokens.semanticWarnSoft(isDark: isDark);

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final ink = chrome.ink;
    final mute = chrome.mute;
    final line = chrome.line;
    final brand = Theme.of(context).colorScheme.primary;
    final brandDeep = BrandPalette.deep(brand);

    final altos = _alertas.where((a) => a.score >= 2).length;
    final medios = _alertas.where((a) => a.score == 1).length;
    const saudaveis = 0;

    void openFiltros() {
      showModalBottomSheet(
        context: context,
        builder:
            (sheetContext) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Todos'),
                    onTap: () {
                      setState(() => _filtroScoreMin = null);
                      Navigator.pop(sheetContext);
                    },
                  ),
                  ListTile(
                    title: const Text('Score ≥ 2 (alto)'),
                    onTap: () {
                      setState(() => _filtroScoreMin = 2);
                      Navigator.pop(sheetContext);
                    },
                  ),
                  ListTile(
                    title: const Text('Score = 1 (médio)'),
                    onTap: () {
                      setState(() => _filtroScoreMin = 1);
                      Navigator.pop(sheetContext);
                    },
                  ),
                ],
              ),
            ),
      );
    }

    return fxScreenA11yScope(
      label: 'Alertas de Risco',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Alertas de Risco',
          subtitle: 'MOTOR ANTI-CHURN',
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
          actions: [
            IconButton(
              tooltip: 'Filtrar',
              onPressed: openFiltros,
              icon: Icon(Icons.filter_list, color: mute),
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_loading)
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(TokensStrip.s4),
                    child: SkeletonList(count: 6),
                  ),
                )
              else if (_erro != null)
                Expanded(
                  child: FxErrorState(
                    chromeOnDark: isDark,
                    primary: brand,
                    message: _erro!,
                    onRetry: _load,
                  ),
                )
              else ...[
                // Config strip
                if (_config != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      0,
                      16,
                      16,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? heroTealSurface(0.04)
                                : brand.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? line : brand.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: mute),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Dispara se: ',
                                    style: TextStyle(fontSize: 12, color: mute),
                                  ),
                                  TextSpan(
                                    text:
                                        'sem treino > ${_config!.diasSemTreino} dias ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ink,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'ou ',
                                    style: TextStyle(fontSize: 12, color: mute),
                                  ),
                                  TextSpan(
                                    text:
                                        'aderência < ${_config!.aderenciaMinima}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ink,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _editarConfiguracao,
                            child: Text(
                              'Editar',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: brand,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Summary chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: EagleTokens.semanticBadSoft(isDark: isDark),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: EagleTokens.semanticBad(isDark: isDark)
                                  .withValues(alpha: isDark ? 0.2 : 0.15),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$altos',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: EagleTokens.semanticBad(isDark: isDark),
                                ),
                              ),
                              Text(
                                'Score alto',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: EagleTokens.semanticBad(isDark: isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: EagleTokens.semanticWarnSoft(isDark: isDark),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: EagleTokens.semanticWarn(isDark: isDark)
                                  .withValues(alpha: isDark ? 0.2 : 0.15),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$medios',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: EagleTokens.semanticWarn(isDark: isDark),
                                ),
                              ),
                              Text(
                                'Score médio',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: EagleTokens.semanticWarn(isDark: isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: EagleTokens.semanticGoodSoft(isDark: isDark),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: EagleTokens.semanticGood(isDark: isDark)
                                  .withValues(alpha: isDark ? 0.15 : 0.15),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$saudaveis',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: EagleTokens.semanticGood(isDark: isDark),
                                ),
                              ),
                              Text(
                                'Saudáveis',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: EagleTokens.semanticGood(isDark: isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Alert List
                Expanded(
                  child:
                      _filtrados.isEmpty
                          ? (_filtroScoreMin != null
                              ? FxEmptyState(
                                icon: 'search',
                                title: 'Nenhum alerta neste filtro',
                                subtitle:
                                    'Nenhum aluno bate o score selecionado. Volte para "Todos" para ver a base inteira.',
                                action: FxEmptyAction(
                                  label: 'Limpar filtro',
                                  onTap:
                                      () => setState(
                                        () => _filtroScoreMin = null,
                                      ),
                                ),
                              )
                              : const FxEmptyState(
                                icon: 'circle-check',
                                title: 'Nenhum aluno em risco',
                                subtitle:
                                    'Sua base está saudável. Avisamos aqui quando alguém começar a esfriar.',
                              ))
                          : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              TokensStrip.s4,
                              0,
                              16,
                              100,
                            ),
                            itemCount: _filtrados.length,
                            itemBuilder: (_, i) {
                              final a = _filtrados[i];
                              final sColor = _scoreColor(a.score, isDark);
                              final sBg = _scoreBg(a.score, isDark);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: fxListCardDecoration(
                                  context,
                                  accent: a.score >= 2 ? EagleTokens.bad : null,
                                  radius: 20,
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        14,
                                        14,
                                        14,
                                        12,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: isDark ? brandDeep : brand,
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              fxInitials(a.alunoNome),
                                              style: TextStyle(
                                                color: heroTealInk(),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        a.alunoNome,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: ink,
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 7,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: sBg,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              999,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'Score ${a.score}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: sColor,
                                                          fontFamily:
                                                              'monospace',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                ...a.motivos.map(
                                                  (m) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 2,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: 4,
                                                          height: 4,
                                                          decoration:
                                                              BoxDecoration(
                                                                color: sColor,
                                                                shape:
                                                                    BoxShape
                                                                        .circle,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Flexible(
                                                          child: Text(
                                                            m,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: sColor,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${a.diasSemTreino ?? 0}d',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                  color: sColor,
                                                ),
                                              ),
                                              Text(
                                                '${a.aderenciaPercent?.toStringAsFixed(0) ?? 0}% ader.',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  color: mute,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(color: line),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: InkWell(
                                              onTap:
                                                  () => _enviarMensagemChat(a),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    right: BorderSide(
                                                      color: line,
                                                    ),
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '💬 Mensagem',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: brand,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: InkWell(
                                              onTap: () => _resolverAlerta(a),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '✓ Resolvido',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        isDark
                                                            ? const Color(
                                                              0xFF6FE296,
                                                            )
                                                            : EagleTokens.good,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
