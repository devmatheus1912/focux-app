import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_chrome.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/widgets/aluno_form_choices.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../data/anamnese_repository.dart';
import '../providers/anamnese_provider.dart';
import '../utils/anamnese_display.dart';
import '../widgets/anamnese_status_banner.dart';

/// S5 — Aluno preenche a ficha (PAR-Q+ → Saúde → Hábitos → Treino → Algo mais).
class AnamneseAlunoScreen extends ConsumerStatefulWidget {
  const AnamneseAlunoScreen({super.key});

  @override
  ConsumerState<AnamneseAlunoScreen> createState() =>
      _AnamneseAlunoScreenState();
}

class _AnamneseAlunoScreenState extends ConsumerState<AnamneseAlunoScreen> {
  // PAR-Q+
  final Map<String, bool?> _parq = {
    for (final q in anamneseParqPerguntas) q.key: null,
  };
  final _parqOutraDetalheCtrl = TextEditingController();

  // Saúde
  final _historicoCtrl = TextEditingController();
  final _cirurgiasCtrl = TextEditingController();
  final _doresCtrl = TextEditingController();
  final _lesoesCtrl = TextEditingController();
  final _medicCtrl = TextEditingController();
  final _alergiasCtrl = TextEditingController();
  final _gestacaoCtrl = TextEditingController();
  final _historicoFamiliarCtrl = TextEditingController();
  final _sintomasCvCtrl = TextEditingController();

  // Hábitos
  double? _sonoHoras;
  final _qualidadeSonoCtrl = TextEditingController();
  final _estresseCtrl = TextEditingController();
  final _tabagismoCtrl = TextEditingController();
  final _alcoolCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  // Treino
  final _objetivoCtrl = TextEditingController();
  final _objDetalhadoCtrl = TextEditingController();
  int _dispSemanal = 3;
  final _prefTreinoCtrl = TextEditingController();
  final _restricoesCtrl = TextEditingController();
  final _historicoAtividadeCtrl = TextEditingController();
  final _motivoInterrupcoesCtrl = TextEditingController();
  final _motivacaoCtrl = TextEditingController();
  final _algoMaisCtrl = TextEditingController();

  Anamnese? _anamnese;
  bool _loading = true;
  bool _saving = false;
  bool _enviada = false;
  bool _dirty = false;
  bool _applying = false;
  bool _wired = false;
  String? _erro;

  AnamneseRepository get _repo =>
      AnamneseRepository(ref.read(apiClientProvider));

  List<TextEditingController> get _allCtrls => [
    _parqOutraDetalheCtrl,
    _historicoCtrl,
    _cirurgiasCtrl,
    _doresCtrl,
    _lesoesCtrl,
    _medicCtrl,
    _alergiasCtrl,
    _gestacaoCtrl,
    _historicoFamiliarCtrl,
    _sintomasCvCtrl,
    _qualidadeSonoCtrl,
    _estresseCtrl,
    _tabagismoCtrl,
    _alcoolCtrl,
    _obsCtrl,
    _objetivoCtrl,
    _objDetalhadoCtrl,
    _prefTreinoCtrl,
    _restricoesCtrl,
    _historicoAtividadeCtrl,
    _motivoInterrupcoesCtrl,
    _motivacaoCtrl,
    _algoMaisCtrl,
  ];

  void _markDirty() {
    if (_applying || _dirty) return;
    if (mounted) setState(() => _dirty = true);
  }

  void _ensureDirtyWiring() {
    if (_wired) return;
    _wired = true;
    for (final c in _allCtrls) {
      c.addListener(_markDirty);
    }
  }

  Future<void> _cancel() async {
    FxKeyboardDismissScope.dismiss();
    if (_dirty) {
      final ok = await showFxConfirmSheet(
        context,
        title: 'Sair sem salvar?',
        message: 'As respostas desta ficha ainda não foram enviadas.',
        confirmLabel: 'Sair',
        destructive: true,
      );
      if (!ok || !mounted) return;
    }
    safePopOrGo(context, '/dashboard/aluno');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _allCtrls) {
      c
        ..removeListener(_markDirty)
        ..dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _erro = null;
      });
    }
    try {
      final a = await _repo.buscarMinha();
      if (!mounted) return;
      _apply(a);
      setState(() {
        _anamnese = a;
        _enviada = a.isPreenchida || a.isRevisada;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final semFicha = e is DioException && e.response?.statusCode == 404;
      if (semFicha) {
        setState(() {
          _anamnese = Anamnese();
          _loading = false;
        });
        _ensureDirtyWiring();
      } else {
        setState(() {
          _erro = friendlyError(e);
          _loading = false;
        });
      }
    }
  }

  void _apply(Anamnese a) {
    _applying = true;
    for (final q in anamneseParqPerguntas) {
      _parq[q.key] = anamneseParqValue(a, q.key);
    }
    _parqOutraDetalheCtrl.text = a.parqOutraRazaoDetalhe ?? '';
    _historicoCtrl.text = a.historicoMedico ?? '';
    _cirurgiasCtrl.text = a.cirurgias ?? '';
    _doresCtrl.text = a.doresCronicas ?? '';
    _lesoesCtrl.text = a.lesoes ?? '';
    _medicCtrl.text = a.medicamentos ?? '';
    _alergiasCtrl.text = a.alergias ?? '';
    _gestacaoCtrl.text = a.gestacaoPosParto ?? '';
    _historicoFamiliarCtrl.text = a.historicoFamiliarCv ?? '';
    _sintomasCvCtrl.text = a.sintomasCv ?? '';
    _sonoHoras = a.sonoHoras;
    _qualidadeSonoCtrl.text = a.qualidadeSono ?? '';
    _estresseCtrl.text = a.nivelEstresse ?? '';
    _tabagismoCtrl.text = a.tabagismo ?? '';
    _alcoolCtrl.text = a.alcool ?? '';
    _obsCtrl.text = a.observacoes ?? '';
    _objetivoCtrl.text = a.objetivo ?? '';
    _objDetalhadoCtrl.text = a.objetivoDetalhado ?? '';
    _dispSemanal = anamneseDisponibilidadeClamp(a.disponibilidadeSemanal);
    _prefTreinoCtrl.text = a.preferenciasTreino ?? '';
    _restricoesCtrl.text = a.restricoesAlimentares ?? '';
    _historicoAtividadeCtrl.text = a.historicoAtividade ?? '';
    _motivoInterrupcoesCtrl.text = a.motivoInterrupcoes ?? '';
    _motivacaoCtrl.text = a.motivacaoAtual ?? '';
    _algoMaisCtrl.text = a.algoMais ?? '';
    _applying = false;
    _ensureDirtyWiring();
    _dirty = false;
  }

  Future<void> _abrirDisponibilidade() async {
    final picked = await showFxInsetPickerSheet<int>(
      context,
      title: 'Disponibilidade',
      selected: _dispSemanal,
      items: [
        for (var d = 1; d <= 7; d++)
          FxInsetPickerSheetItem(
            value: d,
            label: anamneseDisponibilidadeLabel(d),
          ),
      ],
    );
    if (!mounted || picked == null) return;
    setState(() => _dispSemanal = picked);
    _markDirty();
  }

  Future<void> _abrirSono() async {
    final picked = await showFxInsetPickerSheet<int>(
      context,
      title: 'Horas de sono',
      selected: _sonoHoras?.round(),
      items: [
        for (var h = 4; h <= 12; h++)
          FxInsetPickerSheetItem(value: h, label: anamneseSonoHorasLabel(h)),
      ],
    );
    if (!mounted || picked == null) return;
    setState(() => _sonoHoras = picked.toDouble());
    _markDirty();
  }

  Map<String, dynamic> _payload() => {
    for (final e in _parq.entries)
      if (e.value != null) e.key: e.value,
    'parqOutraRazaoDetalhe': _parqOutraDetalheCtrl.text.trim(),
    'historicoMedico': _historicoCtrl.text.trim(),
    'cirurgias': _cirurgiasCtrl.text.trim(),
    'doresCronicas': _doresCtrl.text.trim(),
    'lesoes': _lesoesCtrl.text.trim(),
    'medicamentos': _medicCtrl.text.trim(),
    'alergias': _alergiasCtrl.text.trim(),
    'gestacaoPosParto': _gestacaoCtrl.text.trim(),
    'historicoFamiliarCv': _historicoFamiliarCtrl.text.trim(),
    'sintomasCv': _sintomasCvCtrl.text.trim(),
    if (_sonoHoras != null) 'sonoHoras': _sonoHoras,
    'qualidadeSono': _qualidadeSonoCtrl.text.trim(),
    'nivelEstresse': _estresseCtrl.text.trim(),
    'tabagismo': _tabagismoCtrl.text.trim(),
    'alcool': _alcoolCtrl.text.trim(),
    'observacoes': _obsCtrl.text.trim(),
    'objetivo': _objetivoCtrl.text.trim(),
    'objetivoDetalhado': _objDetalhadoCtrl.text.trim(),
    'disponibilidadeSemanal': _dispSemanal,
    'preferenciasTreino': _prefTreinoCtrl.text.trim(),
    'restricoesAlimentares': _restricoesCtrl.text.trim(),
    'historicoAtividade': _historicoAtividadeCtrl.text.trim(),
    'motivoInterrupcoes': _motivoInterrupcoesCtrl.text.trim(),
    'motivacaoAtual': _motivacaoCtrl.text.trim(),
    'algoMais': _algoMaisCtrl.text.trim(),
  };

  Future<void> _salvar() async {
    FxKeyboardDismissScope.dismiss();
    final parqPendente = _parq.values.any((v) => v == null);
    if (parqPendente) {
      FeedbackHelper.showError(
        context,
        'Responda todas as perguntas do PAR-Q+ antes de enviar.',
      );
      return;
    }
    if (_objetivoCtrl.text.trim().isEmpty) {
      FeedbackHelper.showError(
        context,
        'Informe seu objetivo antes de enviar.',
      );
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    try {
      final a = await _repo.salvarMinha(_payload());
      if (!mounted) return;
      ref.invalidate(minhaAnamneseProvider);
      setState(() {
        _anamnese = a;
        _enviada = true;
        _dirty = false;
      });
      FeedbackHelper.showSuccess(context, 'Enviada para revisão do personal.');
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = chrome.isDark;

    final a = _anamnese ?? Anamnese();
    final showBanner = !_loading && _erro == null && (a.alunoDevePreencher || _enviada);
    final formReady = !_loading && _erro == null;

    return fxScreenA11yScope(
      label: 'Minha anamnese',
      child: FxFormPopGuard(
        dirty: formReady && _dirty,
        onCancel: _cancel,
        child: FxShellScaffold(
          useMesh: true,
          constrainWidth: false,
          appBar: FxShellAppBar(
            title: 'Anamnese',
            subtitle: 'Ficha de saúde e objetivos',
            onBack: _cancel,
          ),
          bottomNavigationBar:
              formReady
                  ? FxFormStickyBar(
                    child: Semantics(
                      button: true,
                      enabled: !_saving,
                      label: _saving ? 'Salvando anamnese' : 'Salvar anamnese',
                      child: FxLiquidPrimaryButton(
                        label: 'Salvar',
                        loading: _saving,
                        loadingLabel: 'Salvando…',
                        onPressed: _saving ? null : _salvar,
                      ),
                    ),
                  )
                  : null,
          body:
              _loading
                  ? const SkeletonList(count: 6)
                  : _erro != null
                  ? FxErrorState(
                    chromeOnDark: isDark,
                    primary: primary,
                    message: _erro!,
                    onRetry: _load,
                    title: 'Não conseguimos carregar a anamnese',
                  )
                  : SafeArea(
            bottom: false,
            child: FxContentWidthLimiter(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    FxSettingsLayout.pageInset,
                    8,
                    FxSettingsLayout.pageInset,
                    24,
                  ),
                  children: [
                    if (showBanner) ...[
                    AnamneseStatusBanner(
                      title: _enviada && !a.alunoDevePreencher
                          ? 'Enviada para revisão'
                          : anamneseAlunoCtaTitle(a),
                      body: _enviada && !a.alunoDevePreencher
                          ? 'Seu personal vai revisar a ficha.'
                          : anamneseAlunoCtaBody(a),
                      tone: a.isPrecisaAtestado
                          ? AnamneseBannerTone.warn
                          : (_enviada && !a.alunoDevePreencher
                              ? AnamneseBannerTone.success
                              : AnamneseBannerTone.info),
                    ),
                    const SizedBox(height: FxSettingsLayout.groupGap),
                  ],
                  FxSettingsGroup(
                    header: 'PAR-Q+',
                    caption:
                        'Responda com sinceridade. Sim em qualquer item exige atenção do personal.',
                    children: [
                      for (var i = 0; i < anamneseParqPerguntas.length; i++)
                        AlunoChoiceSection(
                          label: anamneseParqPerguntas[i].label,
                          isDark: isDark,
                          showDividerAbove: i > 0,
                          child: AlunoSegmentedChoice(
                            options: const [
                              (value: 'true', label: 'Sim'),
                              (value: 'false', label: 'Não'),
                            ],
                            selected:
                                _parq[anamneseParqPerguntas[i].key] == null
                                    ? null
                                    : (_parq[anamneseParqPerguntas[i].key]!
                                        ? 'true'
                                        : 'false'),
                            isDark: isDark,
                            onSelect: (v) {
                              setState(() {
                                _parq[anamneseParqPerguntas[i].key] =
                                    v == 'true';
                              });
                              _markDirty();
                            },
                          ),
                        ),
                      if (_parq['parqOutraRazao'] == true)
                        Padding(
                          padding: const EdgeInsets.only(top: TokensStrip.s2),
                          child: AlunoInsetFormField(
                            controller: _parqOutraDetalheCtrl,
                            label: 'Detalhe (outra razão)',
                            hint: 'Descreva o motivo',
                            icon: Icons.notes_outlined,
                            maxLines: 3,
                            showDivider: false,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: FxSettingsLayout.groupGap),
                  FxSettingsGroup(
                    header: 'Saúde',
                    caption: 'Histórico que o treino precisa respeitar.',
                    children: [
                      AlunoInsetFormField(
                        controller: _historicoCtrl,
                        label: 'Histórico médico',
                        hint: 'Doenças, diagnósticos, acompanhamentos',
                        icon: Icons.history_outlined,
                        maxLines: 4,
                      ),
                      AlunoInsetFormField(
                        controller: _cirurgiasCtrl,
                        label: 'Cirurgias',
                        hint: 'Ex.: LCA, hérnia, quando ocorreu',
                        icon: Icons.local_hospital_outlined,
                        maxLines: 3,
                      ),
                      AlunoInsetFormField(
                        controller: _doresCtrl,
                        label: 'Dores crônicas',
                        hint: 'Ex.: cervical, ombro direito',
                        icon: Icons.sentiment_dissatisfied_outlined,
                        maxLines: 3,
                      ),
                      AlunoInsetFormField(
                        controller: _lesoesCtrl,
                        label: 'Lesões / limitações',
                        hint: 'Ex.: joelho, lombar, evitar impacto',
                        icon: Icons.healing_outlined,
                        maxLines: 3,
                      ),
                      AlunoInsetFormField(
                        controller: _medicCtrl,
                        label: 'Medicamentos',
                        hint: 'Ex.: anti-hipertensivo, tireoide',
                        icon: Icons.medication_outlined,
                        maxLines: 2,
                      ),
                      AlunoInsetFormField(
                        controller: _alergiasCtrl,
                        label: 'Alergias',
                        hint: 'Medicamentos, alimentos, outras',
                        icon: Icons.warning_amber_outlined,
                        maxLines: 2,
                      ),
                      AlunoInsetFormField(
                        controller: _gestacaoCtrl,
                        label: 'Gestação / pós-parto',
                        hint: 'Se aplicável',
                        icon: Icons.pregnant_woman_outlined,
                        maxLines: 2,
                      ),
                      AlunoInsetFormField(
                        controller: _historicoFamiliarCtrl,
                        label: 'Histórico familiar cardiovascular',
                        hint: 'Pais, irmãos — infarto, AVC, etc.',
                        icon: Icons.family_restroom_outlined,
                        maxLines: 2,
                      ),
                      AlunoInsetFormField(
                        controller: _sintomasCvCtrl,
                        label: 'Sintomas cardiovasculares',
                        hint: 'Palpitação, falta de ar, etc.',
                        icon: Icons.favorite_border,
                        maxLines: 2,
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: FxSettingsLayout.groupGap),
                  FxSettingsGroup(
                    header: 'Hábitos',
                    caption: 'Sono, estresse e rotina.',
                    children: [
                      FxSettingsTile(
                        fxIcon: 'moon',
                        label: 'Horas de sono',
                        value:
                            _sonoHoras == null
                                ? 'Selecionar'
                                : anamneseSonoHorasLabel(_sonoHoras),
                        picker: true,
                        onTap: _abrirSono,
                      ),
                      AlunoInsetFormField(
                        controller: _qualidadeSonoCtrl,
                        label: 'Qualidade do sono',
                        hint: 'Ex.: boa, irregular, acordar cansado',
                        icon: Icons.bedtime_outlined,
                        maxLines: 2,
                      ),
                      AlunoInsetFormField(
                        controller: _estresseCtrl,
                        label: 'Nível de estresse',
                        hint: 'Ex.: baixo, médio, alto',
                        icon: Icons.psychology_outlined,
                        maxLines: 2,
                      ),
                      AlunoInsetFormField(
                        controller: _tabagismoCtrl,
                        label: 'Tabagismo',
                        hint: 'Não fumo / quantos por dia',
                        icon: Icons.smoke_free_outlined,
                        maxLines: 1,
                      ),
                      AlunoInsetFormField(
                        controller: _alcoolCtrl,
                        label: 'Álcool',
                        hint: 'Frequência e quantidade',
                        icon: Icons.local_bar_outlined,
                        maxLines: 1,
                      ),
                      AlunoInsetFormField(
                        controller: _obsCtrl,
                        label: 'Observações',
                        hint: 'Rotina, preferências, o que quiser avisar',
                        icon: Icons.notes_outlined,
                        maxLines: 3,
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: FxSettingsLayout.groupGap),
                  FxSettingsGroup(
                    header: 'Treino e objetivos',
                    caption: 'O que você quer e como pode treinar.',
                    children: [
                      AlunoInsetFormField(
                        controller: _objetivoCtrl,
                        label: 'Objetivo',
                        hint: 'Ex.: hipertrofia, emagrecimento',
                        icon: Icons.flag_outlined,
                        maxLines: 2,
                      ),
                      AlunoInsetFormField(
                        controller: _objDetalhadoCtrl,
                        label: 'Objetivo detalhado',
                        hint: 'Meta em 8–12 semanas, eventos, prioridades',
                        icon: Icons.track_changes_outlined,
                        maxLines: 3,
                      ),
                      FxSettingsTile(
                        fxIcon: 'calendar',
                        label: 'Disponibilidade',
                        value: anamneseDisponibilidadeLabel(_dispSemanal),
                        picker: true,
                        onTap: _abrirDisponibilidade,
                      ),
                      AlunoInsetFormField(
                        controller: _prefTreinoCtrl,
                        label: 'Preferências de treino',
                        hint: 'Ex.: manhã, musculação, evitar corrida',
                        icon: Icons.fitness_center_outlined,
                        maxLines: 3,
                      ),
                      AlunoInsetFormField(
                        controller: _restricoesCtrl,
                        label: 'Restrições alimentares',
                        hint: 'Ex.: lactose, vegetariano',
                        icon: Icons.restaurant_outlined,
                        maxLines: 2,
                      ),
                      AlunoInsetFormField(
                        controller: _historicoAtividadeCtrl,
                        label: 'Histórico de atividade',
                        hint: 'O que já praticou e por quanto tempo',
                        icon: Icons.history_edu_outlined,
                        maxLines: 3,
                      ),
                      AlunoInsetFormField(
                        controller: _motivoInterrupcoesCtrl,
                        label: 'Motivo de interrupções',
                        hint: 'Por que parou de treinar antes',
                        icon: Icons.pause_circle_outline,
                        maxLines: 2,
                      ),
                      AlunoInsetFormField(
                        controller: _motivacaoCtrl,
                        label: 'Motivação atual',
                        hint: 'O que te move agora',
                        icon: Icons.local_fire_department_outlined,
                        maxLines: 2,
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: FxSettingsLayout.groupGap),
                  FxSettingsGroup(
                    header: 'Algo mais',
                    caption: 'Qualquer detalhe que o personal precise saber.',
                    children: [
                      AlunoInsetFormField(
                        controller: _algoMaisCtrl,
                        label: 'Algo mais',
                        hint: 'Livre — o que não coube acima',
                        icon: Icons.chat_bubble_outline,
                        maxLines: 4,
                        showDivider: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
