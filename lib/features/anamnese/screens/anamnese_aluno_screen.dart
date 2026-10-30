import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/focux_hub_typography.dart';
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
import '../../../core/widgets/fx_status_banner.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../alunos/widgets/aluno_form_choices.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../data/anamnese_rascunho_store.dart';
import '../data/anamnese_repository.dart';
import '../providers/anamnese_provider.dart';
import '../utils/anamnese_display.dart';
import '../utils/anamnese_etapas.dart';
import '../widgets/anamnese_aluno_campos.dart';

part 'anamnese_aluno_etapas.part.dart';
part 'anamnese_aluno_resumo.part.dart';

/// Aluno preenche a ficha em quatro etapas; ficha enviada abre em resumo.
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
  bool? _historicoFamiliarCv;
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
  int? _dispSemanal;
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

  var _etapa = AnamneseEtapa.saudeGeral;
  var _mostrarPendencias = false;

  /// Ficha já enviada, aberta em uma etapa pelo "Editar".
  var _editando = false;

  /// "Não tenho" / "Tenho" da etapa de histórico, por campo.
  final _tenho = <TextEditingController, bool?>{};
  final _scroll = ScrollController();
  final _parqKeys = {
    for (final q in anamneseParqPerguntas) q.key: GlobalKey(),
  };
  Timer? _rascunhoTimer;

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
    if (_applying) return;
    _rascunhoTimer?.cancel();
    _rascunhoTimer = Timer(const Duration(milliseconds: 600), _guardarRascunho);
    if (_dirty) return;
    if (mounted) setState(() => _dirty = true);
  }

  void _guardarRascunho() =>
      unawaited(AnamneseRascunhoStore.salvar({..._payload(), 'etapa': _etapa.index}));

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
      final s = S.of(context);
      final ok = await showFxConfirmSheet(
        context,
        title: s.anamneseAlunoSairTitulo,
        message: s.anamneseAlunoSairTexto,
        confirmLabel: s.anamneseAlunoSair,
      );
      if (!ok || !mounted) return;
      _rascunhoTimer?.cancel();
      _guardarRascunho();
    }
    safePopOrGo(context, '/aluno/perfil');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _rascunhoTimer?.cancel();
    _scroll.dispose();
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
      await _oferecerRascunho();
    } catch (e) {
      if (!mounted) return;
      final semFicha = e is DioException && e.response?.statusCode == 404;
      if (semFicha) {
        setState(() {
          _anamnese = Anamnese();
          _loading = false;
        });
        _ensureDirtyWiring();
        await _oferecerRascunho();
      } else {
        setState(() {
          _erro = friendlyError(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _oferecerRascunho() async {
    final dados = await AnamneseRascunhoStore.ler();
    if (dados == null || !mounted) return;
    final s = S.of(context);
    final ok = await showFxConfirmSheet(
      context,
      title: s.anamneseAlunoRascunhoTitulo,
      message: s.anamneseAlunoRascunhoTexto,
      confirmLabel: s.anamneseAlunoRascunhoContinuar,
      cancelLabel: s.anamneseAlunoRascunhoDescartar,
    );
    if (!mounted) return;
    if (!ok) {
      await AnamneseRascunhoStore.limpar();
      return;
    }
    final etapa = dados['etapa'];
    setState(() {
      _apply(Anamnese.fromJson({...dados, 'status': _anamnese?.status}));
      _dirty = true;
      _editando = _enviada;
      if (etapa is int && etapa >= 0 && etapa < AnamneseEtapa.values.length) {
        _etapa = AnamneseEtapa.values[etapa];
      }
    });
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
    _historicoFamiliarCv = a.historicoFamiliarCv;
    _sintomasCvCtrl.text = a.sintomasCv ?? '';
    _sonoHoras = a.sonoHoras;
    _qualidadeSonoCtrl.text = a.qualidadeSono ?? '';
    _estresseCtrl.text = a.nivelEstresse ?? '';
    _tabagismoCtrl.text = a.tabagismo ?? '';
    _alcoolCtrl.text = a.alcool ?? '';
    _obsCtrl.text = a.observacoes ?? '';
    _objetivoCtrl.text = a.objetivo ?? '';
    _objDetalhadoCtrl.text = a.objetivoDetalhado ?? '';
    _dispSemanal =
        a.disponibilidadeSemanal == null
            ? null
            : anamneseDisponibilidadeClamp(a.disponibilidadeSemanal);
    _prefTreinoCtrl.text = a.preferenciasTreino ?? '';
    _restricoesCtrl.text = a.restricoesAlimentares ?? '';
    _historicoAtividadeCtrl.text = a.historicoAtividade ?? '';
    _motivoInterrupcoesCtrl.text = a.motivoInterrupcoes ?? '';
    _motivacaoCtrl.text = a.motivacaoAtual ?? '';
    _algoMaisCtrl.text = a.algoMais ?? '';
    for (final c in _camposTenho) {
      _tenho[c] = c.text.trim().isEmpty ? null : true;
    }
    _applying = false;
    _ensureDirtyWiring();
    _dirty = false;
  }

  List<TextEditingController> get _camposTenho => [
    _historicoCtrl,
    _cirurgiasCtrl,
    _doresCtrl,
    _lesoesCtrl,
    _medicCtrl,
    _alergiasCtrl,
    _gestacaoCtrl,
    _sintomasCvCtrl,
  ];

  void _responderTenho(TextEditingController c, bool tem) {
    setState(() {
      _tenho[c] = tem;
      if (!tem) c.clear();
    });
    _markDirty();
  }

  void _irPara(AnamneseEtapa etapa) {
    setState(() {
      _etapa = etapa;
      _mostrarPendencias = false;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _guardarRascunho();
  }

  void _voltarEtapa() {
    if (_etapa.index == 0) {
      if (_editando) {
        setState(() => _editando = false);
      } else {
        _cancel();
      }
      return;
    }
    _irPara(AnamneseEtapa.values[_etapa.index - 1]);
  }

  /// Avança ou mostra o que falta, no lugar da pendência.
  Future<void> _continuar() async {
    FxKeyboardDismissScope.dismiss();
    final completa = anamneseEtapaCompleta(
      _etapa,
      parq: _parq,
      objetivo: _objetivoCtrl.text,
      dias: _dispSemanal,
    );
    if (!completa) {
      setState(() => _mostrarPendencias = true);
      if (_etapa == AnamneseEtapa.saudeGeral) {
        final primeira = anamneseParqPendentes(_parq).first;
        final alvo = _parqKeys[primeira]?.currentContext;
        if (alvo != null) {
          await Scrollable.ensureVisible(
            alvo,
            duration: const Duration(milliseconds: 240),
            alignment: 0.2,
          );
        }
      }
      return;
    }
    if (_etapa == AnamneseEtapa.objetivos) {
      await _salvar();
      return;
    }
    _irPara(AnamneseEtapa.values[_etapa.index + 1]);
  }

  Future<void> _abrirDisponibilidade() async {
    final picked = await showFxInsetPickerSheet<int>(
      context,
      title: S.of(context).anamneseAlunoDias,
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
      title: S.of(context).anamneseAlunoHorasSono,
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
    'parqOutraRazaoDetalhe': anamneseClipField(
      _parqOutraDetalheCtrl.text,
      AnamneseFieldLimits.parqOutraRazaoDetalhe,
    ),
    'historicoMedico': anamneseClipField(
      _historicoCtrl.text,
      AnamneseFieldLimits.historicoMedico,
    ),
    'cirurgias': anamneseClipField(
      _cirurgiasCtrl.text,
      AnamneseFieldLimits.cirurgias,
    ),
    'doresCronicas': anamneseClipField(
      _doresCtrl.text,
      AnamneseFieldLimits.doresCronicas,
    ),
    'lesoes': anamneseClipField(_lesoesCtrl.text, AnamneseFieldLimits.lesoes),
    'medicamentos': anamneseClipField(
      _medicCtrl.text,
      AnamneseFieldLimits.medicamentos,
    ),
    'alergias': anamneseClipField(
      _alergiasCtrl.text,
      AnamneseFieldLimits.alergias,
    ),
    'gestacaoPosParto': anamneseClipField(
      _gestacaoCtrl.text,
      AnamneseFieldLimits.gestacaoPosParto,
    ),
    if (_historicoFamiliarCv != null)
      'historicoFamiliarCv': _historicoFamiliarCv,
    'sintomasCv': anamneseClipField(
      _sintomasCvCtrl.text,
      AnamneseFieldLimits.sintomasCv,
    ),
    if (_sonoHoras != null) 'sonoHoras': _sonoHoras,
    'qualidadeSono': anamneseClipField(
      _qualidadeSonoCtrl.text,
      AnamneseFieldLimits.qualidadeSono,
    ),
    'nivelEstresse': anamneseClipField(
      _estresseCtrl.text,
      AnamneseFieldLimits.nivelEstresse,
    ),
    'tabagismo': anamneseClipField(
      _tabagismoCtrl.text,
      AnamneseFieldLimits.tabagismo,
    ),
    'alcool': anamneseClipField(_alcoolCtrl.text, AnamneseFieldLimits.alcool),
    'observacoes': anamneseClipField(
      _obsCtrl.text,
      AnamneseFieldLimits.observacoes,
    ),
    'objetivo': anamneseClipField(
      _objetivoCtrl.text,
      AnamneseFieldLimits.objetivo,
    ),
    'objetivoDetalhado': anamneseClipField(
      _objDetalhadoCtrl.text,
      AnamneseFieldLimits.objetivoDetalhado,
    ),
    if (_dispSemanal != null) 'disponibilidadeSemanal': _dispSemanal,
    'preferenciasTreino': anamneseClipField(
      _prefTreinoCtrl.text,
      AnamneseFieldLimits.preferenciasTreino,
    ),
    'restricoesAlimentares': anamneseClipField(
      _restricoesCtrl.text,
      AnamneseFieldLimits.restricoesAlimentares,
    ),
    'historicoAtividade': anamneseClipField(
      _historicoAtividadeCtrl.text,
      AnamneseFieldLimits.historicoAtividade,
    ),
    'motivoInterrupcoes': anamneseClipField(
      _motivoInterrupcoesCtrl.text,
      AnamneseFieldLimits.motivoInterrupcoes,
    ),
    'motivacaoAtual': anamneseClipField(
      _motivacaoCtrl.text,
      AnamneseFieldLimits.motivacaoAtual,
    ),
    'algoMais': anamneseClipField(
      _algoMaisCtrl.text,
      AnamneseFieldLimits.algoMais,
    ),
  };

  Future<void> _salvar() async {
    FxKeyboardDismissScope.dismiss();
    HapticFeedback.mediumImpact();
    final s = S.of(context);
    setState(() => _saving = true);
    try {
      final a = await _repo.salvarMinha(_payload());
      if (!mounted) return;
      _rascunhoTimer?.cancel();
      await AnamneseRascunhoStore.limpar();
      if (!mounted) return;
      ref.invalidate(minhaAnamneseProvider);
      invalidateAlunoDashboardHome(ref);
      setState(() {
        _anamnese = a;
        _enviada = true;
        _editando = false;
        _dirty = false;
        _etapa = AnamneseEtapa.saudeGeral;
      });
      FeedbackHelper.showSuccess(context, s.anamneseAlunoEnviada);
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = chrome.isDark;
    final a = _anamnese ?? Anamnese();
    final formReady = !_loading && _erro == null;
    final resumo = formReady && _enviada && !a.alunoDevePreencher && !_editando;

    return fxScreenA11yScope(
      label: s.anamneseAlunoTitulo,
      child: FxFormPopGuard(
        dirty: formReady && _dirty,
        onCancel: _cancel,
        child: FxShellScaffold(
          useMesh: true,
          constrainWidth: false,
          appBar: FxShellAppBar(
            title: s.anamneseAlunoTitulo,
            subtitle: resumo || !formReady
                ? s.anamneseAlunoSubtitulo
                : s.anamneseAlunoEtapa(_etapa.index + 1, AnamneseEtapa.values.length),
            onBack: _cancel,
          ),
          bottomNavigationBar: formReady && !resumo ? _rodape(s) : null,
          body:
              _loading
                  ? const SkeletonList(count: 6)
                  : _erro != null
                  ? FxErrorState(
                    chromeOnDark: isDark,
                    primary: primary,
                    message: _erro!,
                    onRetry: _load,
                    title: s.anamneseAlunoErro,
                  )
                  : SafeArea(
                    bottom: false,
                    child: FxKeyboardDismissScope(
                      child: FxContentWidthLimiter(
                        child: resumo
                            ? _corpoResumo(s, a)
                            : _corpoEtapa(s, a, isDark),
                      ),
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _rodape(S s) {
    final ultima = _etapa == AnamneseEtapa.objetivos;
    return FxFormStickyBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ultima && _enviada) ...[
            Text(
              s.anamneseAlunoRevisaDeNovo,
              textAlign: TextAlign.center,
              style: FocuxHubTypography.bodyMuted(
                color: ShellChrome.of(context).mute,
              ),
            ),
            const SizedBox(height: TokensStrip.s2),
          ],
          Row(
            children: [
              if (_etapa.index > 0 || _editando) ...[
                FxTonalButton(
                  label: s.anamneseAlunoVoltar,
                  onPressed: _saving ? null : _voltarEtapa,
                ),
                const SizedBox(width: TokensStrip.s2),
              ],
              Expanded(
                child: FxLiquidPrimaryButton(
                  label: ultima ? s.anamneseAlunoEnviar : s.anamneseAlunoContinuar,
                  loading: _saving,
                  loadingLabel: s.anamneseAlunoEnviando,
                  onPressed: _saving ? null : _continuar,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
