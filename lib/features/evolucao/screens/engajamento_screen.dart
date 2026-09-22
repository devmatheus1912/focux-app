import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/evolucao_repository.dart';
import '../utils/engajamento_display.dart';
import '../widgets/engajamento_help_sheet.dart';

class EngajamentoScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;
  final String? initialSection;
  const EngajamentoScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
    this.initialSection,
  });

  @override
  ConsumerState<EngajamentoScreen> createState() => _EngajamentoScreenState();
}

class _EngajamentoScreenState extends ConsumerState<EngajamentoScreen> {
  int _dias = 30;
  List<EventoEngajamento> _eventos = [];
  bool _loading = true;
  String? _erro;
  DateTime? _fetchedAt;
  final _checkinsSectionKey = GlobalKey();

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
      final repo = EvolucaoRepository(ref.read(apiClientProvider));
      final eventos = await repo.engajamento(widget.alunoId, dias: _dias);
      if (mounted) {
        setState(() {
          _eventos = eventos;
          _loading = false;
          _fetchedAt = DateTime.now();
        });
        _scrollToInitialSectionIfNeeded();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = friendlyError(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickPeriodo() async {
    HapticFeedback.selectionClick();
    final picked = await showFxInsetPickerSheet<int>(
      context,
      title: 'Período',
      selected: _dias,
      items: [
        for (final d in engajamentoPeriodos)
          FxInsetPickerSheetItem(value: d, label: engajamentoPeriodoLabel(d)),
      ],
    );
    if (!mounted || picked == null || picked == _dias) return;
    setState(() => _dias = picked);
    await _load();
  }

  void _verNoventaDias() {
    if (_dias == 90) return;
    setState(() => _dias = 90);
    _load();
  }

  void _abrirEvolucao() {
    context.push(
      '/alunos/${widget.alunoId}/evolucao',
      extra: widget.alunoNome,
    );
  }

  void _abrirAluno() {
    context.push('/alunos/${widget.alunoId}', extra: widget.alunoNome);
  }

  void _abrirChat() {
    context.push(
      '/alunos/${widget.alunoId}/chat',
      extra: widget.alunoNome,
    );
  }

  void _scrollToInitialSectionIfNeeded() {
    if (widget.initialSection != 'checkins') return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _checkinsSectionKey.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        alignment: 0.08,
        duration: Duration(milliseconds: fxMotionDurationMs(context)),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _abrirEvento(EventoEngajamento evento) {
    final rota = engajamentoEventoRota(evento.tipo, widget.alunoId);
    if (rota == null) return;
    context.push(rota, extra: widget.alunoNome);
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final showSticky = !_loading && _erro == null;
    return fxScreenA11yScope(
      label: 'Engajamento — ${widget.alunoNome}',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          safePopOrGo(context, '/alunos/${widget.alunoId}');
        },
        child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Engajamento',
          subtitle: freshness,
          onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar o engajamento',
              onTap: () => showEngajamentoHelpSheet(context),
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
                        child: SkeletonList(count: 6),
                      )
                      : _erro != null
                      ? FxErrorState(
                        chromeOnDark: chrome.isDark,
                        primary: primary,
                        message: _erro!,
                        onRetry: _load,
                        title: 'Não conseguimos carregar o engajamento',
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
                    label: 'Registrar evolução',
                    onPressed: _abrirEvolucao,
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final header = FxHubHeader(
      title: fxTitleCaseName(widget.alunoNome),
      subtitle: engajamentoHubSubtitle(
        alunoNome: widget.alunoNome,
        dias: _dias,
      ),
    );
    final metric = Padding(
      padding: const EdgeInsets.only(
        top: TokensStrip.s4,
        bottom: TokensStrip.s3,
      ),
      child: Column(
        children: [
          OperationalMetricTile(
            label: 'Eventos',
            value: '${_eventos.length}',
            hint: engajamentoEventosMetricHint(_eventos.length, _dias),
            color: primary,
            isDark: isDark,
          ),
          const SizedBox(height: TokensStrip.s2),
          OperationalMetricTile(
            key: _checkinsSectionKey,
            label: 'Treinos',
            value: '${engajamentoTreinosCount(_eventos)}',
            hint: 'Check-ins e treinos na janela',
            color: primary,
            isDark: isDark,
          ),
          const SizedBox(height: TokensStrip.s2),
          OperationalMetricTile(
            label: 'Mensagens',
            value: '${engajamentoMensagensCount(_eventos)}',
            hint: 'Chat na janela',
            color: primary,
            isDark: isDark,
          ),
          const SizedBox(height: TokensStrip.s2),
          OperationalMetricTile(
            label: 'Último',
            value: engajamentoUltimoValue(_eventos),
            hint: engajamentoUltimoHint(_eventos),
            color: primary,
            isDark: isDark,
          ),
        ],
      ),
    );
    final periodoChip = Wrap(
      spacing: TokensStrip.s2,
      runSpacing: TokensStrip.s2,
      children: [
        DashboardHomeActionChip(
          label: engajamentoPeriodoLabel(_dias),
          accent: primary,
          isDark: isDark,
          onPressed: _pickPeriodo,
        ),
        DashboardHomeActionChip(
          label: 'Aluno',
          accent: primary,
          isDark: isDark,
          onPressed: _abrirAluno,
        ),
        DashboardHomeActionChip(
          label: 'Evolução',
          accent: primary,
          isDark: isDark,
          onPressed: _abrirEvolucao,
        ),
        DashboardHomeActionChip(
          label: 'Chat',
          accent: primary,
          isDark: isDark,
          onPressed: _abrirChat,
        ),
      ],
    );

    return RefreshIndicator(
      onRefresh: _load,
      child: _eventos.isEmpty
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
                metric,
                periodoChip,
                const SizedBox(height: TokensStrip.s5),
                FxEmptyState(
                  icon: 'trend',
                  title: 'Nenhum evento registrado',
                  subtitle:
                      'Treinos, medidas e mensagens do aluno aparecem aqui na janela escolhida.',
                  action:
                      _dias == 90
                          ? null
                          : FxEmptyAction(
                            label: 'Ver 90 dias',
                            onTap: _verNoventaDias,
                          ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                TokensStrip.s4,
                FxSettingsLayout.pageInset,
                TokensStrip.s6,
              ),
              itemCount: _eventos.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      metric,
                      periodoChip,
                      const SizedBox(height: TokensStrip.s5),
                      const DashboardSectionHeader(title: 'Eventos'),
                      const SizedBox(height: TokensStrip.s3),
                    ],
                  );
                }
                final evento = _eventos[i - 1];
                return FxSatelliteListTile(
                  title: engajamentoEventoLabel(
                    evento.descricao,
                    evento.tipo,
                  ),
                  titleCase: false,
                  onTap:
                      engajamentoEventoRota(evento.tipo, widget.alunoId) ==
                              null
                          ? null
                          : () => _abrirEvento(evento),
                  subtitle: Text(
                    engajamentoEventoSubtitle(
                      tipo: evento.tipo,
                      dataHora: evento.dataHora,
                    ),
                  ),
                  leading: FxIcon(
                    name: engajamentoFxIcon(evento.tipo),
                    size: 18,
                    color: primary,
                  ),
                  trailing: Text(
                    engajamentoWhenLabel(evento.dataHora),
                    style: FocuxHubTypography.bodyMuted(
                      color: fxScreenMute(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
