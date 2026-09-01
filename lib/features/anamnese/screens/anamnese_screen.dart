import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../data/anamnese_repository.dart';
import '../utils/anamnese_display.dart';
import '../utils/anamnese_pdf.dart';

class AnamneseScreen extends ConsumerStatefulWidget {
  final int alunoId;
  const AnamneseScreen({super.key, required this.alunoId});
  @override
  ConsumerState<AnamneseScreen> createState() => _AnamneseScreenState();
}

class _AnamneseScreenState extends ConsumerState<AnamneseScreen> {
  final _objetivoCtrl = TextEditingController();
  String? _nivelAtividade;
  final _lesoesCtrl = TextEditingController();
  final _medicCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  final _historicoCtrl = TextEditingController();
  final _cirurgiasCtrl = TextEditingController();
  final _doresCtrl = TextEditingController();
  final _objDetalhadoCtrl = TextEditingController();
  int _dispSemanal = 3;
  final _prefTreinoCtrl = TextEditingController();
  final _restricoesCtrl = TextEditingController();

  bool _loading = true, _saving = false;
  String? _erro;
  bool _semFicha = false;
  bool _preenchendo = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _objetivoCtrl.dispose();
    _lesoesCtrl.dispose();
    _medicCtrl.dispose();
    _obsCtrl.dispose();
    _historicoCtrl.dispose();
    _cirurgiasCtrl.dispose();
    _doresCtrl.dispose();
    _objDetalhadoCtrl.dispose();
    _prefTreinoCtrl.dispose();
    _restricoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _erro = null;
        _semFicha = false;
      });
    }
    try {
      final a = await AnamneseRepository(
        ref.read(apiClientProvider),
      ).buscar(widget.alunoId);
      _objetivoCtrl.text = a.objetivo ?? '';
      _nivelAtividade = anamneseNivelOuNulo(a.nivelAtividade);
      _lesoesCtrl.text = a.lesoes ?? '';
      _medicCtrl.text = a.medicamentos ?? '';
      _obsCtrl.text = a.observacoes ?? '';
      _historicoCtrl.text = a.historicoMedico ?? '';
      _cirurgiasCtrl.text = a.cirurgias ?? '';
      _doresCtrl.text = a.doresCronicas ?? '';
      _objDetalhadoCtrl.text = a.objetivoDetalhado ?? '';
      _dispSemanal = anamneseDisponibilidadeClamp(a.disponibilidadeSemanal);
      _prefTreinoCtrl.text = a.preferenciasTreino ?? '';
      _restricoesCtrl.text = a.restricoesAlimentares ?? '';
      if (mounted) setState(() => _semFicha = false);
    } catch (e) {
      final semFicha = e is DioException && e.response?.statusCode == 404;
      if (mounted) {
        if (semFicha) {
          setState(() => _semFicha = true);
        } else {
          setState(() => _erro = friendlyError(e));
        }
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _abrirNivel() async {
    final picked = await showFxInsetPickerSheet<String>(
      context,
      title: 'Nível de atividade',
      selected: _nivelAtividade,
      items: [
        for (final n in anamneseNiveis)
          FxInsetPickerSheetItem(value: n, label: anamneseNivelLabel(n)),
      ],
    );
    if (!mounted || picked == null) return;
    setState(() => _nivelAtividade = picked);
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
  }

  Future<void> _exportarPdf() async {
    await exportAnamnesePdf(
      AnamnesePdfSnapshot(
        objetivo: _objetivoCtrl.text,
        nivelAtividade: _nivelAtividade,
        lesoes: _lesoesCtrl.text,
        medicamentos: _medicCtrl.text,
        observacoes: _obsCtrl.text,
        historicoMedico: _historicoCtrl.text,
        cirurgias: _cirurgiasCtrl.text,
        doresCronicas: _doresCtrl.text,
        objetivoDetalhado: _objDetalhadoCtrl.text,
        disponibilidadeSemanal: _dispSemanal,
        preferenciasTreino: _prefTreinoCtrl.text,
        restricoesAlimentares: _restricoesCtrl.text,
      ),
    );
  }

  Future<void> _salvar() async {
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    try {
      await AnamneseRepository(ref.read(apiClientProvider)).salvar(
        widget.alunoId,
        {
          'objetivo': _objetivoCtrl.text,
          if (_nivelAtividade != null) 'nivelAtividade': _nivelAtividade,
          'lesoes': _lesoesCtrl.text,
          'medicamentos': _medicCtrl.text,
          'observacoes': _obsCtrl.text,
          'historicoMedico': _historicoCtrl.text,
          'cirurgias': _cirurgiasCtrl.text,
          'doresCronicas': _doresCtrl.text,
          'objetivoDetalhado': _objDetalhadoCtrl.text,
          'disponibilidadeSemanal': _dispSemanal,
          'preferenciasTreino': _prefTreinoCtrl.text,
          'restricoesAlimentares': _restricoesCtrl.text,
        },
      );
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Anamnese salva!');
        setState(() {
          _semFicha = false;
          _preenchendo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    if (_loading) {
      return fxScreenA11yScope(
        label: 'Anamnese',
        child: const FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Anamnese',
            subtitle: 'Ficha de saúde e objetivos do aluno',
          ),
          body: SkeletonList(count: 5),
        ),
      );
    }
    if (_erro != null) {
      return fxScreenA11yScope(
        label: 'Anamnese',
        child: FxShellScaffold(
          useMesh: true,
          appBar: const FxShellAppBar(
            title: 'Anamnese',
            subtitle: 'Ficha de saúde e objetivos do aluno',
          ),
          body: FxErrorState(
            chromeOnDark: chrome.isDark,
            primary: primary,
            message: _erro!,
            onRetry: _load,
            title: 'Não conseguimos carregar a anamnese',
          ),
        ),
      );
    }
    if (_semFicha && !_preenchendo) {
      return fxScreenA11yScope(
        label: 'Anamnese',
        child: FxShellScaffold(
          useMesh: true,
          appBar: const FxShellAppBar(
            title: 'Anamnese',
            subtitle: 'Ficha de saúde e objetivos do aluno',
          ),
          body: FxEmptyState(
            icon: 'article',
            title: 'Nenhuma ficha ainda',
            subtitle:
                'Preencha a anamnese para registrar saúde, objetivos e preferências do aluno.',
            action: FxEmptyAction(
              label: 'Preencher ficha',
              onTap: () => setState(() => _preenchendo = true),
            ),
          ),
        ),
      );
    }
    return fxScreenA11yScope(
      label: 'Anamnese',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Anamnese',
          subtitle: 'Ficha de saúde e objetivos do aluno',
          actions: [
            ShellHeaderIconButton(
              icon: 'article',
              tooltip: 'Exportar PDF',
              onTap: _exportarPdf,
            ),
            Semantics(
              button: true,
              label: _saving ? 'Salvando anamnese' : 'Salvar anamnese',
              child: TextButton(
                onPressed: _saving ? null : _salvar,
                child:
                    _saving
                        ? const FxLoading(size: 18, strokeWidth: 2)
                        : const Text('Salvar'),
              ),
            ),
          ],
        ),
        body: FxContentWidthLimiter(
          child: RefreshIndicator(
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
                  header: 'Básico',
                  caption: 'Objetivo, atividade e limitações.',
                  children: [
                    AlunoInsetFormField(
                      controller: _objetivoCtrl,
                      label: 'Objetivo',
                      hint: 'Ex.: hipertrofia, emagrecimento, condicionamento',
                      icon: Icons.flag_outlined,
                      maxLines: 2,
                    ),
                    FxSettingsTile(
                      fxIcon: 'flame',
                      label: 'Nível de atividade',
                      value: anamneseNivelLabel(_nivelAtividade),
                      picker: true,
                      onTap: _abrirNivel,
                    ),
                    AlunoInsetFormField(
                      controller: _lesoesCtrl,
                      label: 'Lesões / Limitações',
                      hint: 'Ex.: joelho, lombar, evitar impacto',
                      icon: Icons.healing_outlined,
                      maxLines: 3,
                    ),
                    AlunoInsetFormField(
                      controller: _medicCtrl,
                      label: 'Medicamentos em uso',
                      hint: 'Ex.: anti-hipertensivo, tireoide',
                      icon: Icons.medication_outlined,
                      maxLines: 2,
                    ),
                    AlunoInsetFormField(
                      controller: _obsCtrl,
                      label: 'Observações gerais',
                      hint: 'Rotina, sono, estresse, preferências',
                      icon: Icons.notes_outlined,
                      maxLines: 3,
                      showDivider: false,
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
                      label: 'Cirurgias realizadas',
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
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: FxSettingsLayout.groupGap),
                FxSettingsGroup(
                  header: 'Treino & nutrição',
                  caption: 'Rotina semanal e restrições.',
                  children: [
                    AlunoInsetFormField(
                      controller: _objDetalhadoCtrl,
                      label: 'Objetivo detalhado',
                      hint: 'Meta em 8–12 semanas, eventos, prioridades',
                      icon: Icons.flag_outlined,
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
                      hint: 'Ex.: lactose, vegetariano, alergias',
                      icon: Icons.restaurant_outlined,
                      maxLines: 3,
                      showDivider: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
