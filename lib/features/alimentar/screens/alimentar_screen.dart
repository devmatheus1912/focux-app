import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/alunos/widgets/aluno_inset_form_field.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import '../data/alimentar_repository.dart';
import '../utils/alimentar_display.dart';
import '../widgets/alimentar_help_sheet.dart';
import 'plano_alimentar_detail_screen.dart';

class AlimentarScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String? alunoNome;
  const AlimentarScreen({super.key, required this.alunoId, this.alunoNome});
  @override
  ConsumerState<AlimentarScreen> createState() => _AlimentarScreenState();
}

class _AlimentarScreenState extends ConsumerState<AlimentarScreen> {
  List<PlanoAlimentar> _planos = [];
  bool _loading = true;
  String? _erro;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _erro = null;
      });
    }
    try {
      final r = await AlimentarRepository(
        ref.read(apiClientProvider),
      ).listar(widget.alunoId);
      if (!mounted) return;
      setState(() {
        _planos = r;
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

  Future<void> _novoPlano() async {
    HapticFeedback.selectionClick();
    final nome = TextEditingController();
    final cal = TextEditingController();
    final prot = TextEditingController();
    final carb = TextEditingController();
    final gord = TextEditingController();
    final obs = TextEditingController();
    var created = false;

    try {
      if (!mounted) return;
      final ok = await showFxFormSheet(
        context,
        title: 'Novo plano alimentar',
        subtitle: 'Defina metas e macros do plano.',
        icon: Icons.restaurant_outlined,
        confirmLabel: 'Criar plano',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AlunoInsetFormField(
              controller: nome,
              label: 'Nome do plano',
              icon: Icons.title_outlined,
            ),
            AlunoInsetFormField(
              controller: cal,
              label: 'Calorias/dia (kcal)',
              icon: Icons.local_fire_department_outlined,
              keyboardType: TextInputType.number,
            ),
            AlunoInsetFormField(
              controller: prot,
              label: 'Proteína (g)',
              icon: Icons.egg_outlined,
              keyboardType: TextInputType.number,
            ),
            AlunoInsetFormField(
              controller: carb,
              label: 'Carboidrato (g)',
              icon: Icons.breakfast_dining_outlined,
              keyboardType: TextInputType.number,
            ),
            AlunoInsetFormField(
              controller: gord,
              label: 'Gordura (g)',
              icon: Icons.water_drop_outlined,
              keyboardType: TextInputType.number,
            ),
            AlunoInsetFormField(
              controller: obs,
              label: 'Observações',
              icon: Icons.notes_outlined,
              maxLines: 3,
              showDivider: false,
            ),
          ],
        ),
      );
      if (ok != true) return;
      if (nome.text.trim().isEmpty) {
        if (mounted) {
          FeedbackHelper.showWarn(context, 'Nome do plano é obrigatório.');
        }
        return;
      }
      await AlimentarRepository(ref.read(apiClientProvider)).criar(
        widget.alunoId,
        {
          'nome': nome.text.trim(),
          if (cal.text.isNotEmpty) 'caloriasDia': int.tryParse(cal.text),
          if (prot.text.isNotEmpty) 'proteinaG': int.tryParse(prot.text),
          if (carb.text.isNotEmpty) 'carboidratoG': int.tryParse(carb.text),
          if (gord.text.isNotEmpty) 'gorduraG': int.tryParse(gord.text),
          if (obs.text.isNotEmpty) 'observacoes': obs.text.trim(),
        },
      );
      created = true;
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      nome.dispose();
      cal.dispose();
      prot.dispose();
      carb.dispose();
      gord.dispose();
      obs.dispose();
    }
    if (created) await _load();
  }

  void _abrirPlano(PlanoAlimentar plano) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PlanoAlimentarDetailScreen(
              alunoId: widget.alunoId,
              plano: plano,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final showSticky = !_loading && _erro == null;
    return fxScreenA11yScope(
      label: 'Planos Alimentares',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Planos alimentares',
          onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar a nutrição',
              onTap: () => showAlimentarHelpSheet(context),
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
                        child: SkeletonList(count: 5),
                      )
                      : _erro != null
                      ? FxErrorState(
                        chromeOnDark: chrome.isDark,
                        primary: primary,
                        message: _erro!,
                        onRetry: _load,
                        title: 'Não conseguimos carregar os planos',
                      )
                      : FxContentWidthLimiter(child: _buildBody(primary, freshnessLabel)),
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
                    label: 'Criar plano',
                    onPressed: _novoPlano,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Color primary, String? freshnessLabel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nome = widget.alunoNome?.trim();
    final header = FxHubHeader(
      title:
          nome != null && nome.isNotEmpty
              ? fxTitleCaseName(nome)
              : 'Nutrição',
      subtitle: alimentarHubSubtitle(
        alunoNome: widget.alunoNome,
        freshness: freshnessLabel,
      ),
    );
    final metric = Padding(
      padding: const EdgeInsets.only(
        top: TokensStrip.s4,
        bottom: TokensStrip.s3,
      ),
      child: OperationalMetricTile(
        label: 'Planos',
        value: '${_planos.length}',
        hint: alimentarPlanosMetricHint(_planos.length),
        color: primary,
        isDark: isDark,
      ),
    );

    if (_planos.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            FxSettingsLayout.pageInset,
            TokensStrip.s4,
            FxSettingsLayout.pageInset,
            32,
          ),
          children: [
            header,
            metric,
            FxEmptyState(
              key: const ValueKey('alimentar_empty'),
              icon: 'target',
              title: 'Nenhum plano alimentar',
              subtitle:
                  widget.alunoNome != null
                      ? 'Monte o primeiro plano de ${satelliteFirstName(widget.alunoNome)} com metas de calorias e macros.'
                      : 'Crie o primeiro plano com metas de calorias e macros.',
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s4,
          FxSettingsLayout.pageInset,
          32,
        ),
        itemCount: _planos.length + 2,
        itemBuilder: (_, i) {
          if (i == 0) return header;
          if (i == 1) return metric;
          final p = _planos[i - 2];
          final hasMacros =
              p.proteinaG != null ||
              p.carboidratoG != null ||
              p.gorduraG != null;
          return FxSatelliteListTile(
            title: p.nome,
            titleCase: false,
            isThreeLine: hasMacros,
            onTap: () => _abrirPlano(p),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alimentarKcalLabel(p.caloriasDia)),
                if (hasMacros) ...[
                  const SizedBox(height: 8),
                  _MacroBar(
                    proteinaG: p.proteinaG,
                    carboidratoG: p.carboidratoG,
                    gorduraG: p.gorduraG,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final int? proteinaG;
  final int? carboidratoG;
  final int? gorduraG;

  const _MacroBar({
    required this.proteinaG,
    required this.carboidratoG,
    required this.gorduraG,
  });

  @override
  Widget build(BuildContext context) {
    final proteinKcal = (proteinaG ?? 0) * 4;
    final carbKcal = (carboidratoG ?? 0) * 4;
    final fatKcal = (gorduraG ?? 0) * 9;
    final totalKcal = proteinKcal + carbKcal + fatKcal;

    if (totalKcal <= 0) return const SizedBox.shrink();

    return Container(
      height: 8,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          if (proteinKcal > 0)
            Flexible(
              flex: proteinKcal,
              child: Container(color: EagleTokens.macroProtein),
            ),
          if (carbKcal > 0)
            Flexible(flex: carbKcal, child: Container(color: EagleTokens.warn)),
          if (fatKcal > 0)
            Flexible(
              flex: fatKcal,
              child: Container(color: EagleTokens.macroCarb),
            ),
        ],
      ),
    );
  }
}
