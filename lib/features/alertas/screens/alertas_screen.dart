import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/alertas_repository.dart';
import '../widgets/alerta_risco_card.dart';
import '../widgets/alertas_config_strip.dart';
import '../widgets/alertas_summary_row.dart';

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
  DateTime? _fetchedAt;

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
      final home =
          await AlertasRepository(ref.read(apiClientProvider)).getHome();
      if (mounted) {
        setState(() {
          _alertas = home.riscos;
          _config = home.configuracao;
          _loading = false;
          _fetchedAt = DateTime.now();
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

  void _openAlerta(AlertaRisco alerta) {
    AnalyticsService.instance.track(
      ProductEvents.alertaRiscoOpened,
      props: {
        'feature': 'alertas',
        'aluno_id': alerta.alunoId,
        'score': alerta.score,
      },
    );
    context.push('/alertas/aluno/${alerta.alunoId}', extra: alerta.alunoNome);
  }

  void _openFiltros() {
    showFxHomeSheet<void>(
      context,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final primary = Theme.of(sheetContext).colorScheme.primary;
        Widget option({
          required String title,
          required IconData icon,
          required VoidCallback onTap,
        }) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, color: primary, size: 20),
            title: Text(title),
            onTap: onTap,
            minVerticalPadding: 12,
          );
        }

        return FxHomeSheetSurface(
          isDark: isDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FxHomeSheetHandle(isDark: isDark),
              SizedBox(height: TokensStrip.s4),
              FxHomeSheetHeader(
                isDark: isDark,
                title: 'Filtrar alertas',
                subtitle: 'Mostre só o nível de risco que você quer ver agora.',
                leading: Icon(
                  Icons.filter_list_rounded,
                  color: primary,
                  size: 18,
                ),
              ),
              option(
                title: 'Todos',
                icon: Icons.all_inclusive_rounded,
                onTap: () {
                  setState(() => _filtroScoreMin = null);
                  Navigator.pop(sheetContext);
                },
              ),
              option(
                title: 'Score ≥ 2 (alto)',
                icon: Icons.priority_high_rounded,
                onTap: () {
                  setState(() => _filtroScoreMin = 2);
                  Navigator.pop(sheetContext);
                },
              ),
              option(
                title: 'Score = 1 (médio)',
                icon: Icons.remove_rounded,
                onTap: () {
                  setState(() => _filtroScoreMin = 1);
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final brand = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);

    final altos = _alertas.where((a) => a.score >= 2).length;
    final medios = _alertas.where((a) => a.score == 1).length;
    const saudaveis = 0;

    return fxScreenA11yScope(
      label: 'Alertas de Risco',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Alertas de Risco',
          subtitle: freshnessLabel ?? 'MOTOR ANTI-CHURN',
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
          actions: [
            IconButton(
              tooltip: 'Filtrar',
              onPressed: _openFiltros,
              icon: Icon(Icons.filter_list, color: chrome.mute),
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
                    chromeOnDark: chrome.isDark,
                    primary: brand,
                    message: _erro!,
                    onRetry: _load,
                  ),
                )
              else ...[
                if (_config != null)
                  AlertasConfigStrip(
                    config: _config!,
                    onEditar: _editarConfiguracao,
                  ),
                AlertasSummaryRow(
                  altos: altos,
                  medios: medios,
                  saudaveis: saudaveis,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child:
                        _filtrados.isEmpty
                            ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height: 320,
                                  child:
                                      _filtroScoreMin != null
                                          ? FxEmptyState(
                                            icon: 'search',
                                            title: 'Nenhum alerta neste filtro',
                                            subtitle:
                                                'Nenhum aluno bate o score selecionado. Volte para "Todos" para ver a base inteira.',
                                            action: FxEmptyAction(
                                              label: 'Limpar filtro',
                                              onTap:
                                                  () => setState(
                                                    () =>
                                                        _filtroScoreMin = null,
                                                  ),
                                            ),
                                          )
                                          : const FxEmptyState(
                                            icon: 'circle-check',
                                            title: 'Nenhum aluno em risco',
                                            subtitle:
                                                'Sua base está saudável. Avisamos aqui quando alguém começar a esfriar.',
                                          ),
                                ),
                              ],
                            )
                            : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                TokensStrip.s4,
                                0,
                                16,
                                100,
                              ),
                              itemCount: _filtrados.length,
                              itemBuilder: (_, i) {
                                final a = _filtrados[i];
                                return AlertaRiscoCard(
                                  alerta: a,
                                  onOpen: () => _openAlerta(a),
                                  onMensagem: () => _enviarMensagemChat(a),
                                  onResolver: () => _resolverAlerta(a),
                                );
                              },
                            ),
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
