import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/evolucao_repository.dart';
import '../utils/engajamento_display.dart';

class EngajamentoScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;
  const EngajamentoScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
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

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    return fxScreenA11yScope(
      label: 'Engajamento — ${widget.alunoNome}',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Engajamento',
          subtitle: engajamentoHubSubtitle(
            alunoNome: widget.alunoNome,
            dias: _dias,
            freshness: freshness,
          ),
          onBack: () => safePopOrGo(context, '/evolucao'),
        ),
        body:
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
    );
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return RefreshIndicator(
      onRefresh: _load,
      child: _eventos.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                8,
                FxSettingsLayout.pageInset,
                32,
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: DashboardHomeActionChip(
                    label: engajamentoPeriodoLabel(_dias),
                    accent: primary,
                    isDark: isDark,
                    onPressed: _pickPeriodo,
                  ),
                ),
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
                TokensStrip.s3,
                FxSettingsLayout.pageInset,
                TokensStrip.s6,
              ),
              itemCount: _eventos.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: DashboardHomeActionChip(
                          label: engajamentoPeriodoLabel(_dias),
                          accent: primary,
                          isDark: isDark,
                          onPressed: _pickPeriodo,
                        ),
                      ),
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
                  subtitle: Text(
                    engajamentoEventoSubtitle(
                      tipo: evento.tipo,
                      dataHora: evento.dataHora,
                    ),
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
