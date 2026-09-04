import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_inset_picker_row.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/grupo_aula_repository.dart';
import '../utils/grupo_aula_display.dart';

class GrupoAulasPersonalScreen extends ConsumerStatefulWidget {
  const GrupoAulasPersonalScreen({super.key});

  @override
  ConsumerState<GrupoAulasPersonalScreen> createState() =>
      _GrupoAulasPersonalScreenState();
}

class _GrupoAulasPersonalScreenState
    extends ConsumerState<GrupoAulasPersonalScreen> {
  List<GrupoAula> _aulas = [];
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
      final aulas =
          await GrupoAulaRepository(
            ref.read(apiClientProvider),
          ).listarPersonal();
      if (mounted) {
        setState(() {
          _aulas = aulas;
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

  Future<DateTime?> _pickDateTime(
    BuildContext context, {
    required DateTime initial,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final today = DateTime.now();
    final options = grupoAulaDateOptions(
      firstDate: firstDate,
      lastDate: lastDate,
      initial: initial,
      now: today,
    );
    final pickedDate = await showFxInsetPickerSheet<DateTime>(
      context,
      title: 'Data',
      selected: grupoAulaDay(initial),
      sameValue: grupoAulaSameDay,
      items: [
        for (final day in options)
          FxInsetPickerSheetItem(
            value: day,
            label: grupoAulaDateOptionLabel(day, today),
            subtitle: grupoAulaDateLabel(day),
            icon: Icons.event_outlined,
          ),
      ],
    );
    if (pickedDate == null || !context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _criar() async {
    HapticFeedback.selectionClick();
    final agora = DateTime.now();
    var inicio = DateTime(agora.year, agora.month, agora.day + 1, 7, 0);
    var fim = inicio.add(const Duration(hours: 1));
    final tituloCtrl = TextEditingController();
    final descricaoCtrl = TextEditingController();
    final localCtrl = TextEditingController();
    final capacidadeCtrl = TextEditingController(text: '20');
    var created = false;

    try {
      if (!mounted) return;
      final ok = await showFxFormSheet(
        context,
        title: 'Nova aula em grupo',
        subtitle: 'Defina horário, capacidade e local.',
        icon: Icons.groups_outlined,
        confirmLabel: 'Criar aula',
        child: StatefulBuilder(
          builder:
              (ctx, setDialogState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AlunoInsetFormField(
                    controller: tituloCtrl,
                    label: 'Título',
                    icon: Icons.title_outlined,
                    hint: 'Ex: Funcional ao ar livre',
                  ),
                  AlunoInsetFormField(
                    controller: descricaoCtrl,
                    label: 'Descrição (opcional)',
                    icon: Icons.notes_outlined,
                    maxLines: 2,
                  ),
                  FxInsetPickerRow(
                    icon: Icons.event_outlined,
                    label: 'Início',
                    value: grupoAulaWhenLabel(inicio),
                    onTap: () async {
                      final picked = await _pickDateTime(
                        ctx,
                        initial: inicio,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 1),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked == null) return;
                      setDialogState(() {
                        inicio = picked;
                        if (!fim.isAfter(inicio)) {
                          fim = inicio.add(const Duration(hours: 1));
                        }
                      });
                    },
                  ),
                  FxInsetPickerRow(
                    icon: Icons.event_available_outlined,
                    label: 'Fim',
                    value: grupoAulaWhenLabel(fim),
                    onTap: () async {
                      final picked = await _pickDateTime(
                        ctx,
                        initial: fim,
                        firstDate: inicio,
                        lastDate: inicio.add(const Duration(days: 1)),
                      );
                      if (picked == null) return;
                      setDialogState(() => fim = picked);
                    },
                  ),
                  AlunoInsetFormField(
                    controller: capacidadeCtrl,
                    label: 'Capacidade',
                    icon: Icons.groups_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  AlunoInsetFormField(
                    controller: localCtrl,
                    label: 'Local (opcional)',
                    icon: Icons.place_outlined,
                    hint: 'Studio, Praia, Online…',
                    showDivider: false,
                  ),
                ],
              ),
        ),
      );
      if (ok != true) return;
      if (tituloCtrl.text.trim().isEmpty) {
        if (mounted) {
          FeedbackHelper.showWarn(context, 'Título é obrigatório.');
        }
        return;
      }
      if (!fim.isAfter(inicio)) {
        if (mounted) {
          FeedbackHelper.showWarn(
            context,
            'Horário de fim deve ser depois do início.',
          );
        }
        return;
      }
      await GrupoAulaRepository(ref.read(apiClientProvider)).criar(
        titulo: tituloCtrl.text.trim(),
        descricao:
            descricaoCtrl.text.trim().isEmpty
                ? null
                : descricaoCtrl.text.trim(),
        inicio: inicio,
        fim: fim,
        capacidadeMax: int.tryParse(capacidadeCtrl.text.trim()) ?? 20,
        localAula:
            localCtrl.text.trim().isEmpty ? null : localCtrl.text.trim(),
      );
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Aula criada!');
      }
      created = true;
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      tituloCtrl.dispose();
      descricaoCtrl.dispose();
      localCtrl.dispose();
      capacidadeCtrl.dispose();
    }
    if (created) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    return fxScreenA11yScope(
      label: 'Aulas em grupo',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Aulas em grupo',
          subtitle: grupoAulaHubSubtitle(freshnessLabel),
          onBack: () => context.pop(),
          actions: [
            ShellHeaderIconButton(
              icon: 'plus',
              tooltip: 'Nova aula',
              onTap: _criar,
            ),
          ],
        ),
        body:
            _loading
                ? const Padding(
                  padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                  child: SkeletonList(count: 4),
                )
                : _erro != null
                ? FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: primary,
                  message: _erro!,
                  onRetry: _load,
                )
                : FxContentWidthLimiter(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _load,
      child: _aulas.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                8,
                FxSettingsLayout.pageInset,
                32,
              ),
              children: [
                FxEmptyState(
                  icon: 'calendar',
                  title: 'Nenhuma aula criada ainda',
                  subtitle:
                      'Crie uma aula em grupo para abrir vagas aos seus alunos.',
                  action: FxEmptyAction(label: 'Nova aula', onTap: _criar),
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
              itemCount: _aulas.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: TokensStrip.s3),
                    child: DashboardSectionHeader(title: 'Próximas aulas'),
                  );
                }
                final aula = _aulas[i - 1];
                final lotada = grupoAulaLotada(
                  inscritos: aula.inscritos,
                  capacidadeMax: aula.capacidadeMax,
                );
                return FxSatelliteListTile(
                  title: aula.titulo,
                  subtitle: Text(
                    grupoAulaSubtitle(
                      inicio: aula.inicio,
                      localAula: aula.localAula,
                    ),
                  ),
                  trailing: Text(
                    grupoAulaVagasLabel(
                      inscritos: aula.inscritos,
                      capacidadeMax: aula.capacidadeMax,
                    ),
                    style: FocuxHubTypography.bodyMuted(
                      color: lotada
                          ? EagleTokens.bad
                          : fxScreenMute(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  accent: lotada ? EagleTokens.bad : null,
                );
              },
            ),
    );
  }
}
