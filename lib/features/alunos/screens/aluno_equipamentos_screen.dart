import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/widgets/fx_quick_chips.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_chrome.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../exercicios/data/enums.dart';
import '../../exercicios/data/exercicio_taxonomy_labels.dart';
import '../providers/aluno_detail_providers.dart';
import '../providers/alunos_provider.dart';
import '../utils/equipamento_aluno_display.dart';
import '../utils/satellite_screen_utils.dart';
import '../../../core/theme/fx_icons.dart';

class AlunoEquipamentosScreen extends ConsumerStatefulWidget {
  const AlunoEquipamentosScreen({super.key, required this.alunoId});

  final int alunoId;

  @override
  ConsumerState<AlunoEquipamentosScreen> createState() =>
      _AlunoEquipamentosScreenState();
}

class _AlunoEquipamentosScreenState
    extends ConsumerState<AlunoEquipamentosScreen> {
  Set<Equipamento>? _baseline;
  Set<Equipamento>? _selected;

  /// "Só o que o aluno tem": a lista aparece. Desligado = qualquer equipamento
  /// (lista vazia no servidor).
  bool _restrito = false;
  bool _saving = false;

  bool get _dirty {
    final selected = _selected;
    final baseline = _baseline;
    if (selected == null || baseline == null) return false;
    return selected.length != baseline.length ||
        !selected.containsAll(baseline);
  }

  bool get _podeSalvar {
    final selected = _selected ?? const <Equipamento>{};
    return _dirty && !_saving && !(_restrito && selected.isEmpty);
  }

  void _hydrate(Set<Equipamento> fromAluno) {
    if (_selected != null) return;
    _baseline = {...fromAluno};
    _selected = {...fromAluno};
    _restrito = fromAluno.isNotEmpty;
  }

  void _toggle(Equipamento equipamento) {
    HapticFeedback.selectionClick();
    final current = {...(_selected ?? <Equipamento>{})};
    if (current.contains(equipamento)) {
      current.remove(equipamento);
    } else {
      current.add(equipamento);
    }
    setState(() => _selected = current);
  }

  void _escolherModo({required bool restrito}) {
    if (restrito == _restrito) return;
    HapticFeedback.selectionClick();
    setState(() {
      _restrito = restrito;
      // Qualquer equipamento é a lista vazia no servidor.
      if (!restrito) _selected = {};
    });
  }

  void _aplicarAtalho(EquipamentosAtalho atalho) {
    HapticFeedback.selectionClick();
    setState(() => _selected = {...atalho.equipamentos});
  }

  void _showHelp() {
    showFxHelpSheet(
      context,
      title: 'Equipamentos',
      subtitle: 'O que o aluno tem disponível no treino.',
      tips: const [
        FxHelpTip(
          'Qualquer ou só o que tem',
          'Com "Só o que o aluno tem", as substituições do copiloto usam só o que estiver marcado.',
          icon: FxIcons.treino,
        ),
        FxHelpTip(
          'Atalhos',
          'Academia, casa ou ao ar livre preenchem a lista num toque. Ajuste depois o que faltar.',
          icon: FxIcons.alvo,
        ),
        FxHelpTip(
          'Salvar',
          'Salvar fica ativo quando você muda algo.',
          icon: FxIcons.salvar,
        ),
      ],
    );
  }

  Future<void> _cancel() async {
    FxKeyboardDismissScope.dismiss();
    if (_dirty) {
      final ok = await showFxConfirmSheet(
        context,
        title: 'Descartar alterações?',
        message: 'O que você alterou não será salvo.',
        confirmLabel: 'Descartar',
        discard: true,
      );
      if (!ok || !mounted) return;
    }
    safePopOrGo(context, '/alunos/${widget.alunoId}');
  }

  Future<void> _save() async {
    final selected = _selected;
    if (selected == null || !_podeSalvar) return;
    final antes = _baseline?.length ?? 0;
    if (selected.isEmpty && antes > 0) {
      final ok = await showFxConfirmSheet(
        context,
        title: antes == 1
            ? 'Tirar a restrição de 1 equipamento?'
            : 'Tirar a restrição de $antes equipamentos?',
        message: 'As substituições passam a usar qualquer equipamento.',
        confirmLabel: 'Tirar restrição',
      );
      if (!ok || !mounted) return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    try {
      await ref
          .read(alunoRepositoryProvider)
          .atualizarEquipamentos(widget.alunoId, selected);
      ref.invalidate(alunoProvider(widget.alunoId));
      await invalidateAluno360Providers(ref, widget.alunoId);
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, equipamentosSaveSuccess());
      safePopOrGo(context, '/alunos/${widget.alunoId}');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alunoAsync = ref.watch(alunoProvider(widget.alunoId));
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Equipamentos',
      child: FxFormPopGuard(
        dirty: _dirty,
        onCancel: _cancel,
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Equipamentos',
            subtitle: satelliteFirstName(alunoAsync.value?.nome),
            onBack: _cancel,
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar equipamentos',
                onTap: _showHelp,
              ),
            ],
          ),
          bottomNavigationBar: FxFormStickyBar(
            child: Semantics(
              button: true,
              enabled: _podeSalvar,
              label: _saving ? 'Salvando equipamentos' : 'Salvar',
              child: FxLiquidPrimaryButton(
                label: 'Salvar',
                loading: _saving,
                loadingLabel: 'Salvando…',
                onPressed: _podeSalvar ? _save : null,
              ),
            ),
          ),
          body: alunoAsync.when(
            loading:
                () => const Padding(
                  padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                  child: SkeletonList(count: 6),
                ),
            error:
                (e, _) => FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: primary,
                  message: friendlyError(e),
                  onRetry: () => ref.invalidate(alunoProvider(widget.alunoId)),
                  title: 'Não conseguimos carregar os equipamentos',
                ),
            data: (aluno) {
              _hydrate(aluno.equipamentosDisponiveis);
              final current = _selected ?? <Equipamento>{};
              final atalho = equipamentosAtalhoDaSelecao(current);
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(alunoProvider(widget.alunoId));
                  final fresh = await ref.read(
                    alunoProvider(widget.alunoId).future,
                  );
                  if (!mounted) return;
                  setState(() {
                    _baseline = {...fresh.equipamentosDisponiveis};
                    _selected = {...fresh.equipamentosDisponiveis};
                    _restrito = fresh.equipamentosDisponiveis.isNotEmpty;
                  });
                },
                child: FxKeyboardDismissScope(
                  child: FxContentWidthLimiter(
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(
                        FxSettingsLayout.pageInset,
                        TokensStrip.s3,
                        FxSettingsLayout.pageInset,
                        TokensStrip.s6,
                      ),
                      children: [
                        FxSettingsGroup(
                          header: 'O que entra nas substituições',
                          children: [
                            _ModoLinha(
                              label: 'Qualquer equipamento',
                              subtitle:
                                  'As substituições podem usar qualquer equipamento.',
                              selecionado: !_restrito,
                              onTap:
                                  _saving
                                      ? null
                                      : () => _escolherModo(restrito: false),
                            ),
                            _ModoLinha(
                              label: 'Só o que o aluno tem',
                              subtitle:
                                  'As substituições usam só o que estiver marcado.',
                              selecionado: _restrito,
                              ultimo: true,
                              onTap:
                                  _saving
                                      ? null
                                      : () => _escolherModo(restrito: true),
                            ),
                          ],
                        ),
                        if (_restrito) ...[
                          const SizedBox(height: FxSettingsLayout.groupGap),
                          Text(
                            'Atalhos',
                            style: FocuxHubTypography.chip(chrome.mute),
                          ),
                          const SizedBox(height: TokensStrip.s1),
                          FxQuickChips<EquipamentosAtalho>(
                            itens: equipamentosAtalhos,
                            selecionado: atalho,
                            rotuloDe: (a) => a.rotulo,
                            onSelecionar: _saving ? (_) {} : _aplicarAtalho,
                          ),
                          const SizedBox(height: FxSettingsLayout.groupGap),
                          FxSettingsGroup(
                            header: equipamentosMarcadosLabel(current.length),
                            caption:
                                current.isEmpty
                                    ? 'Marque ao menos um para salvar.'
                                    : null,
                            children: [
                              for (final (i, equipamento)
                                  in Equipamento.values.indexed)
                                FxSettingsTile(
                                  label:
                                      TaxonomyLabels.equipamento[equipamento] ??
                                      equipamento.backendName,
                                  value: '',
                                  semanticsLabel:
                                      TaxonomyLabels.equipamento[equipamento],
                                  showDivider:
                                      i < Equipamento.values.length - 1,
                                  accessory: Switch.adaptive(
                                    value: current.contains(equipamento),
                                    onChanged:
                                        _saving
                                            ? null
                                            : (_) => _toggle(equipamento),
                                  ),
                                  onTap:
                                      _saving
                                          ? null
                                          : () => _toggle(equipamento),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Uma das duas escolhas do topo: marca de seleção, sem seta (não abre tela).
class _ModoLinha extends StatelessWidget {
  const _ModoLinha({
    required this.label,
    required this.subtitle,
    required this.selecionado,
    required this.onTap,
    this.ultimo = false,
  });

  final String label;
  final String subtitle;
  final bool selecionado;
  final VoidCallback? onTap;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      selected: selecionado,
      inMutuallyExclusiveGroup: true,
      child: FxSettingsTile(
        label: label,
        subtitle: subtitle,
        value: '',
        showDivider: !ultimo,
        accessory: SizedBox.square(
          dimension: FxSettingsLayout.iconSize,
          child:
              selecionado
                  ? Icon(
                    FxIcons.check,
                    size: FxSettingsLayout.iconSize,
                    color: primary,
                  )
                  : null,
        ),
        onTap: onTap,
      ),
    );
  }
}
