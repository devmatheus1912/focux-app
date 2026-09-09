import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_inset_picker_row.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
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
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;
  List<GrupoAula> _aulas = [];
  bool _loading = true;
  String? _erro;
  DateTime? _fetchedAt;
  var _query = '';
  var _chip = GrupoAulaChip.todas;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _query = value);
    });
  }

  void _clearQuery() {
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    setState(() => _query = '');
  }

  void _leave() {
    FxKeyboardDismissScope.dismiss();
    safePopOrGo(context, '/dashboard/personal');
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

  List<GrupoAula> get _visible => _aulas
      .where(
        (aula) => grupoAulaMatches(
          titulo: aula.titulo,
          localAula: aula.localAula,
          lotada: grupoAulaLotada(
            inscritos: aula.inscritos,
            capacidadeMax: aula.capacidadeMax,
          ),
          query: _query,
          chip: _chip,
        ),
      )
      .toList();

  void _openAula(GrupoAula aula) {
    final chrome = ShellChrome.of(context);
    final lotada = grupoAulaLotada(
      inscritos: aula.inscritos,
      capacidadeMax: aula.capacidadeMax,
    );
    showFxHomeSheet<void>(
      context,
      builder: (sheetContext) => FxHomeSheetSurface(
        isDark: chrome.isDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FxHomeSheetHandle(isDark: chrome.isDark),
            FxHomeSheetHeader(
              isDark: chrome.isDark,
              leading: Icon(
                Icons.groups_outlined,
                color: Theme.of(sheetContext).colorScheme.primary,
                size: 18,
              ),
              title: aula.titulo,
              subtitle: grupoAulaVagasLabel(
                inscritos: aula.inscritos,
                capacidadeMax: aula.capacidadeMax,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                0,
                FxSettingsLayout.pageInset,
                TokensStrip.s4,
              ),
              child: Text(
                [
                  grupoAulaSubtitle(
                    inicio: aula.inicio,
                    localAula: aula.localAula,
                  ),
                  if ((aula.descricao ?? '').trim().isNotEmpty)
                    aula.descricao!.trim(),
                  if (lotada) 'Sem vagas no momento.',
                ].join('\n'),
                style: TextStyle(color: chrome.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final visible = _visible;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return fxScreenA11yScope(
      label: 'Aulas em grupo',
      child: PopScope(
        canPop: !keyboardOpen && !_searchFocus.hasFocus,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (keyboardOpen || _searchFocus.hasFocus) {
            FxKeyboardDismissScope.dismiss();
            return;
          }
          _leave();
        },
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Aulas em grupo',
            subtitle: FxHubFreshness.joinCount(
              grupoAulaCountLabel(_aulas.length),
              FxHubFreshness.fromFetchedAt(_fetchedAt),
            ),
            onBack: _leave,
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar aulas em grupo',
                onTap: () => showFxHelpSheet(
                  context,
                  title: 'Aulas em grupo',
                  subtitle: 'Turmas com vaga para o aluno se inscrever.',
                  tips: const [
                    FxHelpTip(
                      'Criar',
                      'O botão no rodapé abre título, horário e capacidade.',
                    ),
                    FxHelpTip(
                      'Detalhe',
                      'Toque na aula vê local, vagas e a descrição.',
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TokensStrip.s4,
                  TokensStrip.s2,
                  TokensStrip.s4,
                  TokensStrip.s2,
                ),
                child: DecoratedBox(
                  decoration: fxStripCardDecoration(
                    context,
                    accent: primary,
                    radius: TokensStrip.rCard,
                    glowStrength: 0.03,
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    onChanged: _onQueryChanged,
                    onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Buscar aula ou local',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: primary,
                        size: 20,
                      ),
                      suffixIcon: _query.trim().isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpar busca',
                              onPressed: _clearQuery,
                              icon: Icon(
                                Icons.close_rounded,
                                color: chrome.mute,
                                size: 18,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TokensStrip.s4,
                  0,
                  TokensStrip.s4,
                  TokensStrip.s2,
                ),
                child: Wrap(
                  spacing: TokensStrip.s2,
                  runSpacing: TokensStrip.s2,
                  children: [
                    for (final chip in GrupoAulaChip.values)
                      FxToggleChip(
                        label: grupoAulaChipLabel(chip),
                        selected: _chip == chip,
                        isDark: chrome.isDark,
                        onTap: () => setState(() => _chip = chip),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
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
                    : FxContentWidthLimiter(child: _buildBody(visible)),
              ),
              if (!_loading && _erro == null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      TokensStrip.s2,
                      FxSettingsLayout.pageInset,
                      TokensStrip.s3 +
                          MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: FxLiquidPrimaryButton(
                      label: 'Nova aula',
                      onPressed: _criar,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<GrupoAula> visible) {
    final primary = Theme.of(context).colorScheme.primary;
    if (visible.isEmpty) {
      final filtered =
          _query.trim().isNotEmpty || _chip != GrupoAulaChip.todas;
      return RefreshIndicator(
        color: primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            FxEmptyState(
              icon: filtered ? 'search' : 'calendar',
              title: filtered
                  ? 'Nenhuma aula encontrada'
                  : 'Nenhuma aula criada ainda',
              subtitle: filtered
                  ? 'Ajuste a busca ou o filtro.'
                  : 'Crie uma aula em grupo para abrir vagas aos seus alunos.',
              action: FxEmptyAction(
                label: filtered ? 'Limpar filtros' : 'Nova aula',
                onTap: filtered ? _clearQuery : _criar,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: primary,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s3,
          FxSettingsLayout.pageInset,
          TokensStrip.s4 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        itemCount: visible.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return const Padding(
              padding: EdgeInsets.only(bottom: TokensStrip.s3),
              child: DashboardSectionHeader(title: 'Próximas aulas'),
            );
          }
          final aula = visible[i - 1];
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
                color: lotada ? EagleTokens.bad : fxScreenMute(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            accent: lotada ? EagleTokens.bad : null,
            onTap: () => _openAula(aula),
          );
        },
      ),
    );
  }
}
