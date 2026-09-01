import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          32,
        ),
        children: [
          FxSettingsGroup(
            header: 'Período',
            children: [
              FxSettingsTile(
                fxIcon: 'calendar',
                label: 'Janela',
                value: engajamentoPeriodoLabel(_dias),
                picker: true,
                showDivider: false,
                onTap: _pickPeriodo,
              ),
            ],
          ),
          if (_eventos.isEmpty)
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
            )
          else
            FxSettingsGroup(
              header: 'Eventos',
              caption:
                  'Treinos, medidas e mensagens nos últimos ${engajamentoPeriodoLabel(_dias)}.',
              children: [
                for (var i = 0; i < _eventos.length; i++)
                  FxSettingsTile(
                    fxIcon: engajamentoFxIcon(_eventos[i].tipo),
                    label: engajamentoEventoLabel(
                      _eventos[i].descricao,
                      _eventos[i].tipo,
                    ),
                    subtitle: engajamentoEventoSubtitle(
                      tipo: _eventos[i].tipo,
                      dataHora: _eventos[i].dataHora,
                    ),
                    value: engajamentoWhenLabel(_eventos[i].dataHora),
                    showDivider: i != _eventos.length - 1,
                    onTap: () {},
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
