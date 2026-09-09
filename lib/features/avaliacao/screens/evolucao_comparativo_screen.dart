import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/alunos/widgets/aluno_inset_form_field.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../evolucao/data/evolucao_repository.dart';
import '../data/avaliacao_repository.dart';
import '../utils/evolucao_comparativo_display.dart';
import '../widgets/evolucao_comparativo_table.dart';

class EvolucaoComparativoScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;
  const EvolucaoComparativoScreen({
    super.key,
    required this.alunoId,
    this.alunoNome = 'Aluno',
  });
  @override
  ConsumerState<EvolucaoComparativoScreen> createState() =>
      _EvolucaoComparativoScreenState();
}

class _EvolucaoComparativoScreenState
    extends ConsumerState<EvolucaoComparativoScreen> {
  ComparativoEvolucao? _comparativo;
  bool _loading = true;
  String? _erro;
  bool _semAvaliacao = false;
  bool _compartilhando = false;
  bool _registrando = false;
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
      _semAvaliacao = false;
    });
    try {
      final c = await AvaliacaoRepository(
        ref.read(apiClientProvider),
      ).comparativo(widget.alunoId);
      if (!mounted) return;
      setState(() {
        _comparativo = c;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      final msg = friendlyError(e);
      if (!mounted) return;
      setState(() {
        if (evolucaoComparativoIsEmptyError(msg)) {
          _semAvaliacao = true;
          _comparativo = null;
        } else {
          _erro = msg;
        }
        _loading = false;
      });
    }
  }

  void _showHelp() {
    showFxHelpSheet(
      context,
      title: 'Comparativo',
      subtitle: evolucaoComparativoHubSubtitle(),
      tips: const [
        FxHelpTip(
          'Janela',
          'Primeira e última avaliação física do aluno. A tabela não mistura outras métricas.',
          icon: 'trend',
        ),
        FxHelpTip(
          'Delta',
          'Verde é melhora no sentido da métrica. Vermelho é piora. Cinza não mudou.',
          icon: 'target',
        ),
        FxHelpTip(
          'Chat',
          'Compartilhar envia um resumo na conversa. Confirme antes — o aluno vê a mensagem.',
          icon: 'message-circle',
        ),
      ],
    );
  }

  Future<void> _compartilhar() async {
    if (_compartilhando || _comparativo == null) return;
    HapticFeedback.mediumImpact();
    final ok = await showFxConfirmSheet(
      context,
      title: evolucaoComparativoConfirmTitle(),
      message: evolucaoComparativoConfirmMessage(),
      icon: Icons.chat_bubble_outline_rounded,
      confirmLabel: evolucaoComparativoConfirmLabel(),
    );
    if (!ok || !mounted) return;
    setState(() => _compartilhando = true);
    try {
      await EvolucaoRepository(
        ref.read(apiClientProvider),
      ).compartilharEvolucao(widget.alunoId);
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      FeedbackHelper.showSuccess(context, 'Evolução compartilhada via chat.');
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(
          context,
          friendlyError(e, fallback: 'Não deu para compartilhar. Tente de novo.'),
        );
      }
    } finally {
      if (mounted) setState(() => _compartilhando = false);
    }
  }

  Future<void> _registrar() async {
    if (_registrando) return;
    HapticFeedback.selectionClick();
    final peso = TextEditingController();
    final altura = TextEditingController();
    final gordura = TextEditingController();
    final cintura = TextEditingController();
    var saved = false;
    try {
      if (!mounted) return;
      final ok = await showFxFormSheet(
        context,
        title: 'Nova avaliação',
        subtitle: 'Peso é obrigatório. O resto entra se você tiver.',
        icon: Icons.monitor_weight_outlined,
        confirmLabel: 'Salvar',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AlunoInsetFormField(
              controller: peso,
              label: 'Peso (kg)',
              icon: Icons.monitor_weight_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            AlunoInsetFormField(
              controller: altura,
              label: 'Altura (cm)',
              icon: Icons.height_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            AlunoInsetFormField(
              controller: gordura,
              label: '% Gordura',
              icon: Icons.percent_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            AlunoInsetFormField(
              controller: cintura,
              label: 'Cintura (cm)',
              icon: Icons.straighten_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              showDivider: false,
            ),
          ],
        ),
      );
      if (ok != true) return;
      final pesoKg = double.tryParse(peso.text.trim().replaceAll(',', '.'));
      if (pesoKg == null) {
        if (mounted) {
          FeedbackHelper.showWarn(context, 'Informe o peso em kg.');
        }
        return;
      }
      setState(() => _registrando = true);
      await AvaliacaoRepository(ref.read(apiClientProvider)).registrar(
        widget.alunoId,
        {
          'pesoKg': pesoKg,
          if (altura.text.trim().isNotEmpty)
            'alturaCm': double.tryParse(altura.text.trim().replaceAll(',', '.')),
          if (gordura.text.trim().isNotEmpty)
            'percGordura':
                double.tryParse(gordura.text.trim().replaceAll(',', '.')),
          if (cintura.text.trim().isNotEmpty)
            'cinturaCm':
                double.tryParse(cintura.text.trim().replaceAll(',', '.')),
        },
      );
      saved = true;
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      peso.dispose();
      altura.dispose();
      gordura.dispose();
      cintura.dispose();
      if (mounted) setState(() => _registrando = false);
    }
    if (saved) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = chrome.isDark;
    final showSticky = !_loading && _erro == null;
    final empty = _semAvaliacao || _comparativo == null;
    return fxScreenA11yScope(
      label: 'Evolução de ${widget.alunoNome}',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          safePopOrGo(context, '/alunos/${widget.alunoId}');
        },
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Comparativo',
            subtitle: FxHubFreshness.fromFetchedAt(_fetchedAt),
            onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
            actions: [
              FxHelpIconButton(tooltip: 'Como comparar', onTap: _showHelp),
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
                          chromeOnDark: isDark,
                          primary: primary,
                          message: _erro!,
                          onRetry: _load,
                          title: 'Não conseguimos carregar o comparativo',
                        )
                        : FxContentWidthLimiter(child: _buildBody()),
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
                      label:
                          empty
                              ? evolucaoComparativoStickyRegistrar()
                              : evolucaoComparativoStickyShare(),
                      loading: _compartilhando || _registrando,
                      onPressed:
                          empty
                              ? (_registrando ? null : _registrar)
                              : (_compartilhando ? null : _compartilhar),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chips({required Color primary, required bool isDark}) {
    return Wrap(
      spacing: TokensStrip.s2,
      runSpacing: TokensStrip.s2,
      children: [
        DashboardHomeActionChip(
          label: 'Lista',
          accent: primary,
          isDark: isDark,
          onPressed:
              () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
        ),
        DashboardHomeActionChip(
          label: 'Evolução',
          accent: primary,
          isDark: isDark,
          onPressed:
              () => context.push(
                '/alunos/${widget.alunoId}/evolucao',
                extra: widget.alunoNome,
              ),
        ),
        DashboardHomeActionChip(
          label: 'Chat',
          accent: primary,
          isDark: isDark,
          onPressed:
              () => context.push(
                '/alunos/${widget.alunoId}/chat',
                extra: widget.alunoNome,
              ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final c = _comparativo;
    if (c == null || _semAvaliacao) {
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
            FxHubHeader(
              title: fxTitleCaseName(widget.alunoNome),
              subtitle: evolucaoComparativoHubSubtitle(),
            ),
            const SizedBox(height: TokensStrip.s3),
            _chips(
              primary: Theme.of(context).colorScheme.primary,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
            const SizedBox(height: TokensStrip.s5),
            FxEmptyState(
              icon: 'trend',
              title: 'Nenhuma avaliação para comparar',
              subtitle:
                  'Registre ao menos duas avaliações físicas para ver a evolução.',
              action: FxEmptyAction(
                label: evolucaoComparativoStickyRegistrar(),
                onTap: _registrando ? () {} : _registrar,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s4,
          FxSettingsLayout.pageInset,
          TokensStrip.s6,
        ),
        children: [
          FxHubHeader(
            title: fxTitleCaseName(widget.alunoNome),
            subtitle: evolucaoComparativoJanelaCaption(
              primeira: evolucaoComparativoFmtData(c.primeira.avaliadoEm),
              atual: evolucaoComparativoFmtData(c.atual.avaliadoEm),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: TokensStrip.s4,
              bottom: TokensStrip.s2,
            ),
            child: OperationalMetricTile(
              label: 'Peso atual',
              value: evolucaoComparativoFmtValor(c.atual.pesoKg, 'kg'),
              hint: evolucaoComparativoPesoMetricHint(c.diferencaPeso),
              color: Theme.of(context).colorScheme.primary,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
          ),
          OperationalMetricTile(
            label: 'IMC',
            value: evolucaoComparativoFmtValor(
              c.atual.imc ??
                  evolucaoComparativoImc(c.atual.pesoKg, c.atual.alturaCm),
              '',
            ),
            hint: 'Da última avaliação',
            color: Theme.of(context).colorScheme.primary,
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          const SizedBox(height: TokensStrip.s2),
          OperationalMetricTile(
            label: 'Gordura',
            value: evolucaoComparativoFmtValor(c.atual.percGordura, '%'),
            hint: evolucaoComparativoDelta(
              primeira: c.primeira.percGordura,
              atual: c.atual.percGordura,
              menorEMelhor: true,
            ).text,
            color: Theme.of(context).colorScheme.primary,
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          const SizedBox(height: TokensStrip.s2),
          OperationalMetricTile(
            label: 'Cintura',
            value: evolucaoComparativoFmtValor(c.atual.circCintura, 'cm'),
            hint: evolucaoComparativoDelta(
              primeira: c.primeira.circCintura,
              atual: c.atual.circCintura,
              menorEMelhor: true,
            ).text,
            color: Theme.of(context).colorScheme.primary,
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          const SizedBox(height: TokensStrip.s3),
          _chips(
            primary: Theme.of(context).colorScheme.primary,
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          const SizedBox(height: TokensStrip.s3),
          EvolucaoComparativoTable(primeira: c.primeira, atual: c.atual),
          const SizedBox(height: TokensStrip.s3),
          _LegendaComparativo(),
        ],
      ),
    );
  }
}

class _LegendaComparativo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mute = ShellChrome.of(context).mute;
    final style = FocuxHubTypography.bodyMuted(color: mute);
    return Row(
      children: [
        const Icon(Icons.circle, size: 10, color: EagleTokens.good),
        const SizedBox(width: TokensStrip.s1),
        Text('Melhora', style: style),
        const SizedBox(width: TokensStrip.s3),
        const Icon(Icons.circle, size: 10, color: EagleTokens.bad),
        const SizedBox(width: TokensStrip.s1),
        Text('Piora', style: style),
        const SizedBox(width: TokensStrip.s3),
        Icon(Icons.circle, size: 10, color: mute),
        const SizedBox(width: TokensStrip.s1),
        Text('Sem alteração', style: style),
      ],
    );
  }
}
