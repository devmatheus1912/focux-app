import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/alunos/widgets/aluno_inset_form_field.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../ia/data/ia_repository.dart';
import '../../ia/widgets/ia_quota_upgrade.dart';
import '../data/alimentar_repository.dart';
import '../utils/alimentar_display.dart';
import '../widgets/alimentar_help_sheet.dart';

part 'plano_alimentar_detail_sheets.part.dart';

class PlanoAlimentarDetailScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final int planoId;
  final PlanoAlimentar? initial;

  const PlanoAlimentarDetailScreen({
    super.key,
    required this.alunoId,
    required this.planoId,
    this.initial,
  });

  @override
  ConsumerState<PlanoAlimentarDetailScreen> createState() =>
      _PlanoAlimentarDetailScreenState();
}

class _PlanoAlimentarDetailScreenState
    extends ConsumerState<PlanoAlimentarDetailScreen> {
  PlanoAlimentar? _plano;
  List<Refeicao> _refeicoes = [];
  bool _loading = true;
  String? _erro;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    final seed = widget.initial;
    if (seed != null && seed.id == widget.planoId) {
      _plano = seed;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final repo = AlimentarRepository(ref.read(apiClientProvider));
      var plano = _plano;
      if (plano == null || plano.id != widget.planoId) {
        plano = await repo.obter(widget.alunoId, widget.planoId);
      }
      if (plano == null) {
        if (!mounted) return;
        setState(() {
          _plano = null;
          _refeicoes = [];
          _loading = false;
          _erro = 'Este plano não está mais disponível.';
        });
        return;
      }
      final lista = await repo.listarRefeicoes(widget.alunoId, plano.id);
      if (!mounted) return;
      setState(() {
        _plano = plano;
        _refeicoes = lista;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = friendlyError(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _excluir(Refeicao r) async {
    final ok = await showFxConfirmSheet(
      context,
      title: 'Remover refeição?',
      subtitle: r.nomeRefeicao,
      message: 'Ela some do plano. Dá para cadastrar de novo depois.',
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final plano = _plano;
    if (plano == null) return;
    try {
      final repo = AlimentarRepository(ref.read(apiClientProvider));
      await repo.excluirRefeicao(widget.alunoId, plano.id, r.id);
      if (mounted) {
        setState(() => _refeicoes.removeWhere((x) => x.id == r.id));
        FeedbackHelper.showSuccess(context, 'Refeição removida.');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _plano;
    final chrome = ShellChrome.of(context);
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final ready = p != null && _erro == null;
    final showSticky = !_loading && _erro == null && p != null;
    return fxScreenA11yScope(
      label: 'Plano alimentar',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Plano alimentar',
          onBack:
              () => safePopOrGo(context, '/alunos/${widget.alunoId}/alimentar'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar este plano',
              onTap: () => showAlimentarPlanoHelpSheet(context),
            ),
            if (ready)
              ShellHeaderIconButton(
                icon: 'spark',
                tooltip: 'Gerar dieta IA',
                onTap: _abrirGerarIa,
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child:
                  _loading
                      ? const Padding(
                        padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                        child: SkeletonList(count: 4),
                      )
                      : _erro != null
                      ? FxErrorState(
                        chromeOnDark: chrome.isDark,
                        primary: Theme.of(context).colorScheme.primary,
                        message: _erro!,
                        onRetry: _load,
                        title: 'Não conseguimos carregar as refeições',
                      )
                      : FxContentWidthLimiter(
                        child: _buildBody(freshnessLabel),
                      ),
            ),
            if (showSticky)
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    FxSettingsLayout.pageInset,
                    TokensStrip.s2,
                    FxSettingsLayout.pageInset,
                    TokensStrip.s3 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: FxLiquidPrimaryButton(
                    label: 'Nova refeição',
                    onPressed: _abrirNovaRefeicao,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(String? freshnessLabel) {
    final p = _plano!;
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = ShellChrome.of(context).mute;
    final header = FxHubHeader(
      title: p.nome,
      subtitle: alimentarDetailSubtitle(freshnessLabel),
    );
    final metrics = _metricTiles(p, primary, isDark);

    return RefreshIndicator(
      onRefresh: _load,
      child:
          _refeicoes.isEmpty
              ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s4,
                  FxSettingsLayout.pageInset,
                  32,
                ),
                children: [
                  header,
                  ...metrics,
                  const SizedBox(height: TokensStrip.s3),
                  const FxEmptyState(
                    icon: 'article',
                    title: 'Nenhuma refeição cadastrada',
                    subtitle:
                        'O botão de baixo adiciona a primeira refeição do plano.',
                  ),
                ],
              )
              : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s4,
                  FxSettingsLayout.pageInset,
                  32,
                ),
                itemCount: _refeicoes.length + 2,
                itemBuilder: (_, i) {
                  if (i == 0) return header;
                  if (i == 1) {
                    return Column(
                      children: [
                        ...metrics,
                        const SizedBox(height: TokensStrip.s3),
                      ],
                    );
                  }
                  final r = _refeicoes[i - 2];
                  final alimentos = r.alimentos?.trim();
                  final hasAlimentos = alimentos != null && alimentos.isNotEmpty;
                  return FxSatelliteListTile(
                    title: alimentarRefeicaoTitle(r.nomeRefeicao, r.horario),
                    titleCase: false,
                    isThreeLine: hasAlimentos,
                    leading: FxIcon(
                      name: r.calorias != null ? 'flame' : 'article',
                      size: 18,
                      color: primary,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alimentarRefeicaoSubtitle(
                            calorias: r.calorias,
                            proteinaG: r.proteinaG,
                            carboG: r.carboG,
                            gorduraG: r.gorduraG,
                          ),
                        ),
                        if (hasAlimentos) ...[
                          const SizedBox(height: 4),
                          Text(alimentos),
                        ],
                      ],
                    ),
                    trailing: IconButton(
                      tooltip: 'Remover refeição',
                      onPressed: () => _excluir(r),
                      icon: Icon(Icons.delete_outline_rounded, color: mute),
                    ),
                    onTap: () => _abrirRefeicaoSheet(existing: r),
                  );
                },
              ),
    );
  }

  List<Widget> _metricTiles(PlanoAlimentar p, Color primary, bool isDark) {
    Widget tile(String label, String value, String hint) {
      return Padding(
        padding: const EdgeInsets.only(
          top: TokensStrip.s2,
          bottom: TokensStrip.s2,
        ),
        child: OperationalMetricTile(
          label: label,
          value: value,
          hint: hint,
          color: primary,
          isDark: isDark,
        ),
      );
    }

    return [
      const SizedBox(height: TokensStrip.s2),
      tile(
        'Calorias',
        alimentarKcalMetricValue(p.caloriasDia),
        alimentarKcalMetricHint(p.caloriasDia),
      ),
      tile(
        'Refeições',
        alimentarRefeicoesMetricValue(_refeicoes.length),
        alimentarRefeicoesMetricHint(_refeicoes.length),
      ),
      tile(
        'Macros',
        alimentarMacrosMetricValue(
          proteinaG: p.proteinaG,
          carboidratoG: p.carboidratoG,
          gorduraG: p.gorduraG,
        ),
        alimentarMacrosMetricHint(
          proteinaG: p.proteinaG,
          carboidratoG: p.carboidratoG,
          gorduraG: p.gorduraG,
        ),
      ),
    ];
  }
}
