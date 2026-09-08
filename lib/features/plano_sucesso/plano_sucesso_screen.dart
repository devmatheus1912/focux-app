import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/safe_navigation.dart';
import '../../core/theme/fx_settings_layout.dart';
import '../../core/theme/shell_chrome.dart';
import '../../core/theme/tokens_strip.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/utils/fx_utils.dart';
import '../../core/ux/fx_hub_freshness.dart';
import '../../core/widgets/feedback_helper.dart';
import '../../core/widgets/fx_content_width_limiter.dart';
import '../../core/widgets/fx_empty_state.dart';
import '../../core/widgets/fx_error_state.dart';
import '../../core/widgets/fx_form_sheet.dart';
import '../../core/widgets/fx_help.dart';
import '../../core/widgets/fx_hub_header.dart';
import '../../core/widgets/fx_inset_picker_sheet.dart';
import '../../core/widgets/fx_icon.dart';
import '../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../core/widgets/fx_motion.dart';
import '../../core/widgets/fx_screen_a11y.dart';
import '../../core/widgets/fx_shell_scaffold.dart';
import '../../core/widgets/operational_metric_tile.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../alunos/utils/satellite_screen_utils.dart';
import '../alunos/widgets/aluno_inset_form_field.dart';
import '../dashboard/widgets/dashboard_home_action_chip.dart';
import 'plano_sucesso_display.dart';
import 'plano_sucesso_model.dart';
import 'plano_sucesso_provider.dart';
import 'widgets/plano_sucesso_help_sheet.dart';

class PlanoSucessoScreen extends StatefulWidget {
  final int alunoId;
  final String? alunoNome;
  const PlanoSucessoScreen({super.key, required this.alunoId, this.alunoNome});

  @override
  State<PlanoSucessoScreen> createState() => _PlanoSucessoScreenState();
}

class _PlanoSucessoScreenState extends State<PlanoSucessoScreen> {
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reload();
    });
  }

  Future<void> _reload() async {
    await context.read<PlanoSucessoProvider>().fetchPlano(widget.alunoId);
    if (!mounted) return;
    setState(() => _fetchedAt = DateTime.now());
  }

  Future<void> _marcarMarco(PlanoSucessoProvider provider, int marcoId) async {
    try {
      await provider.atingirMarco(marcoId);
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Marco atingido!');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(
        context,
        friendlyError(e, fallback: 'Erro ao atualizar o marco.'),
      );
    }
  }

  Future<void> _criarPlano() async {
    HapticFeedback.selectionClick();
    final objetivo = TextEditingController();
    final marco1 = TextEditingController();
    final marco2 = TextEditingController();
    final marco3 = TextEditingController();
    var created = false;

    try {
      if (!mounted) return;
      final ok = await showFxFormSheet(
        context,
        title: 'Novo plano de sucesso',
        subtitle: 'Objetivo e as primeiras etapas do aluno.',
        icon: Icons.flag_outlined,
        confirmLabel: 'Criar plano',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AlunoInsetFormField(
              controller: objetivo,
              label: 'Objetivo',
              icon: Icons.flag_outlined,
            ),
            AlunoInsetFormField(
              controller: marco1,
              label: 'Primeira etapa',
              icon: Icons.check_circle_outline,
            ),
            AlunoInsetFormField(
              controller: marco2,
              label: 'Segunda etapa (opcional)',
              icon: Icons.check_circle_outline,
            ),
            AlunoInsetFormField(
              controller: marco3,
              label: 'Terceira etapa (opcional)',
              icon: Icons.check_circle_outline,
              showDivider: false,
            ),
          ],
        ),
      );
      if (ok != true) return;
      final objetivoTxt = objetivo.text.trim();
      final titulos =
          [marco1.text, marco2.text, marco3.text]
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList();
      if (objetivoTxt.isEmpty) {
        if (mounted) {
          FeedbackHelper.showWarn(context, 'Objetivo é obrigatório.');
        }
        return;
      }
      if (titulos.isEmpty) {
        if (mounted) {
          FeedbackHelper.showWarn(context, 'Inclua ao menos uma etapa.');
        }
        return;
      }
      if (!mounted) return;
      await context.read<PlanoSucessoProvider>().criarPlano(
        alunoId: widget.alunoId,
        objetivoPrincipal: objetivoTxt,
        titulosMarcos: titulos,
      );
      created = true;
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      objetivo.dispose();
      marco1.dispose();
      marco2.dispose();
      marco3.dispose();
    }
    if (created && mounted) {
      setState(() => _fetchedAt = DateTime.now());
    }
  }

  Future<void> _remarcarRevisao() async {
    final plano = context.read<PlanoSucessoProvider>().plano;
    if (plano == null) return;
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var initial = DateTime(
      plano.proximaRevisao.year,
      plano.proximaRevisao.month,
      plano.proximaRevisao.day,
    );
    if (initial.isBefore(today)) initial = today;
    final opcoes = planoSucessoRevisaoOpcoes(today);
    final picked = await showFxInsetPickerSheet<DateTime>(
      context,
      title: 'Próxima revisão',
      subtitle: 'Quando você revisa este plano com o aluno.',
      headerIcon: Icons.event_outlined,
      selected: planoSucessoRevisaoOpcaoSelecionada(
        opcoes: opcoes,
        atual: initial,
      ),
      sameValue:
          (a, b) => a.year == b.year && a.month == b.month && a.day == b.day,
      items: [
        for (final opcao in opcoes)
          FxInsetPickerSheetItem(
            value: opcao.data,
            label: opcao.label,
            subtitle: opcao.subtitle,
            icon: Icons.event_outlined,
          ),
      ],
    );
    if (picked == null || !mounted) return;
    FxKeyboardDismissScope.dismiss();
    try {
      await context.read<PlanoSucessoProvider>().revisarPlano(
        planoId: plano.id,
        alunoId: widget.alunoId,
        novaProximaRevisao: picked,
      );
      if (!mounted) return;
      setState(() => _fetchedAt = DateTime.now());
      FeedbackHelper.showSuccess(context, 'Revisão remarcada.');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanoSucessoProvider>();
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final plano = provider.plano;
    final proximo =
        plano == null ? null : planoSucessoProximoMarco(plano.marcos);
    final showSticky = !provider.isLoading && provider.erro == null;
    final stickyLabel = planoSucessoStickyLabel(
      hasPlano: plano != null,
      proximo: proximo,
    );
    final showCalendario = plano != null && proximo != null;

    return fxScreenA11yScope(
      label: 'Plano de Sucesso',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          safePopOrGo(context, '/alunos/${widget.alunoId}');
        },
        child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Plano de sucesso',
          subtitle: freshness,
          onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar o plano de sucesso',
              onTap: () => showPlanoSucessoHelpSheet(context),
            ),
            if (showCalendario)
              ShellHeaderIconButton(
                icon: 'calendar',
                tooltip: 'Remarcar revisão',
                onTap: _remarcarRevisao,
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child:
                  provider.isLoading
                      ? const Padding(
                        padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                        child: SkeletonList(count: 5),
                      )
                      : provider.erro != null
                      ? FxErrorState(
                        chromeOnDark: chrome.isDark,
                        primary: primary,
                        message: provider.erro!,
                        onRetry: _reload,
                        title: 'Não conseguimos carregar o plano',
                      )
                      : FxContentWidthLimiter(
                        child: RefreshIndicator(
                          onRefresh: _reload,
                          child: _buildBody(
                            plano: plano,
                            primary: primary,
                            isDark: chrome.isDark,
                            freshness: freshness,
                            proximo: proximo,
                            onMarcar:
                                (id) => _marcarMarco(provider, id),
                          ),
                        ),
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
                    label: stickyLabel,
                    onPressed:
                        plano == null
                            ? _criarPlano
                            : proximo != null
                            ? () => _marcarMarco(provider, proximo.id)
                            : _remarcarRevisao,
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildBody({
    required PlanoSucesso? plano,
    required Color primary,
    required bool isDark,
    required String? freshness,
    required MarcoSucesso? proximo,
    required ValueChanged<int> onMarcar,
  }) {
    final nome = widget.alunoNome?.trim();
    final headerTitle =
        nome != null && nome.isNotEmpty
            ? fxTitleCaseName(nome)
            : 'Plano de sucesso';

    if (plano == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s4,
          FxSettingsLayout.pageInset,
          32,
        ),
        children: [
          FxHubHeader(
            title: headerTitle,
            subtitle: planoSucessoHubSubtitle(
              base: 'Metas e prazos do aluno',
              freshness: freshness,
            ),
          ),
          const SizedBox(height: TokensStrip.s4),
          ..._planoMetricTiles(
            primary: primary,
            isDark: isDark,
            progressoValue: '0%',
            progressoHint: 'Nenhum plano ativo',
            etapasValue: planoSucessoEtapasValue(0, 0),
            etapasHint: planoSucessoEtapasHint(
              done: 0,
              total: 0,
              proximo: null,
            ),
            revisaoValue: planoSucessoRevisaoMetricValue(null),
            revisaoHint: planoSucessoRevisaoMetricHint(null),
          ),
          const SizedBox(height: TokensStrip.s4),
          _alunoChips(primary: primary, isDark: isDark),
          const SizedBox(height: TokensStrip.s5),
          FxEmptyState(
            icon: 'target',
            title: 'Nenhum plano ativo',
            subtitle:
                widget.alunoNome != null
                    ? '${satelliteFirstName(widget.alunoNome)} ainda não possui marcos de sucesso definidos.'
                    : 'Este aluno ainda não possui plano de sucesso.',
            action: FxEmptyAction(label: 'Criar plano', onTap: _criarPlano),
          ),
        ],
      );
    }

    final total = plano.marcos.length;
    final done = plano.marcos.where((m) => m.atingido).length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        TokensStrip.s4,
        FxSettingsLayout.pageInset,
        32,
      ),
      children: [
        FxHubHeader(
          title: headerTitle,
          subtitle: planoSucessoHubSubtitle(
            base: plano.objetivoPrincipal,
            freshness: freshness,
          ),
        ),
        const SizedBox(height: TokensStrip.s4),
        ..._planoMetricTiles(
          primary: primary,
          isDark: isDark,
          progressoValue: planoSucessoPercentLabel(done, total),
          progressoHint: planoSucessoMetricHint(
            done: done,
            total: total,
            proximaRevisao: plano.proximaRevisao,
          ),
          etapasValue: planoSucessoEtapasValue(done, total),
          etapasHint: planoSucessoEtapasHint(
            done: done,
            total: total,
            proximo: proximo,
          ),
          revisaoValue: planoSucessoRevisaoMetricValue(plano.proximaRevisao),
          revisaoHint: planoSucessoRevisaoMetricHint(plano.proximaRevisao),
        ),
        const SizedBox(height: TokensStrip.s4),
        _alunoChips(primary: primary, isDark: isDark),
        const SizedBox(height: TokensStrip.s5),
        for (var i = 0; i < plano.marcos.length; i++)
          FxSatelliteListTile(
            title: plano.marcos[i].titulo,
            titleCase: false,
            onTap:
                plano.marcos[i].atingido
                    ? null
                    : () => onMarcar(plano.marcos[i].id),
            subtitle: Text(
              planoSucessoMarcoSubtitle(
                atingido: plano.marcos[i].atingido,
                atual: plano.marcos[i].id == proximo?.id,
              ),
            ),
            leading: FxIcon(
              name: plano.marcos[i].atingido ? 'circle-check' : 'target',
              size: 18,
              color: plano.marcos[i].atingido ? TokensStrip.textSecondary : primary,
            ),
          ),
      ],
    );
  }

  List<Widget> _planoMetricTiles({
    required Color primary,
    required bool isDark,
    required String progressoValue,
    required String progressoHint,
    required String etapasValue,
    required String etapasHint,
    required String revisaoValue,
    required String revisaoHint,
  }) {
    Widget tile(String label, String value, String hint) {
      return Padding(
        padding: const EdgeInsets.only(bottom: TokensStrip.s2),
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
      tile('Progresso', progressoValue, progressoHint),
      tile('Etapas', etapasValue, etapasHint),
      tile('Revisão', revisaoValue, revisaoHint),
    ];
  }

  Widget _alunoChips({required Color primary, required bool isDark}) {
    return Wrap(
      spacing: TokensStrip.s2,
      runSpacing: TokensStrip.s2,
      children: [
        DashboardHomeActionChip(
          label: 'Aluno',
          accent: primary,
          isDark: isDark,
          onPressed: () => context.push(
            '/alunos/${widget.alunoId}',
            extra: widget.alunoNome,
          ),
        ),
        DashboardHomeActionChip(
          label: 'Chat',
          accent: primary,
          isDark: isDark,
          onPressed: () => context.push(
            '/alunos/${widget.alunoId}/chat',
            extra: widget.alunoNome,
          ),
        ),
      ],
    );
  }
}
