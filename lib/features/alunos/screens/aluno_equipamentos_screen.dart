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
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_icon.dart';
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
  bool _saving = false;

  bool get _dirty {
    final selected = _selected;
    final baseline = _baseline;
    if (selected == null || baseline == null) return false;
    return selected.length != baseline.length ||
        !selected.containsAll(baseline);
  }

  void _hydrate(Set<Equipamento> fromAluno) {
    if (_selected != null) return;
    _baseline = {...fromAluno};
    _selected = {...fromAluno};
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

  void _clearRestriction() {
    HapticFeedback.selectionClick();
    setState(() => _selected = {});
  }

  void _showHelp() {
    showFxHelpSheet(
      context,
      title: 'Equipamentos',
      subtitle: 'O que o aluno tem disponível no treino.',
      tips: const [
        FxHelpTip(
          'Restrição',
          'Marque só o que dá para usar. Substituições do copiloto respeitam essa lista.',
          icon: 'dumbbell',
        ),
        FxHelpTip(
          'Sem restrição',
          'Lista vazia = sem filtro. Qualquer equipamento pode entrar nas sugestões.',
          icon: 'spark',
        ),
        FxHelpTip(
          'Salvar',
          'O botão Salvar só aparece depois que você muda alguma opção.',
          icon: 'target',
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
      );
      if (!ok || !mounted) return;
    }
    safePopOrGo(context, '/alunos/${widget.alunoId}');
  }

  Future<void> _save() async {
    final selected = _selected;
    if (selected == null || _saving || !_dirty) return;
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
            subtitle: satelliteFirstName(alunoAsync.valueOrNull?.nome),
            leadingWidth: 92,
            leading: TextButton(
              onPressed: _cancel,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Cancelar'),
            ),
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar equipamentos',
                onTap: _showHelp,
              ),
            ],
          ),
          bottomNavigationBar:
              _dirty
                  ? FxFormStickyBar(
                    child: Semantics(
                      button: true,
                      enabled: !_saving,
                      label:
                          _saving ? 'Salvando equipamentos' : 'Salvar',
                      child: FxLiquidPrimaryButton(
                        label: 'Salvar',
                        loading: _saving,
                        loadingLabel: 'Salvando…',
                        onPressed: _saving ? null : _save,
                      ),
                    ),
                  )
                  : null,
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
              final current = _selected ?? {};
              final noneSelected = current.isEmpty;
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
                  });
                },
                child: FxKeyboardDismissScope(
                  child: FxContentWidthLimiter(
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(
                        FxSettingsLayout.pageInset,
                        TokensStrip.s3,
                        FxSettingsLayout.pageInset,
                        24,
                      ),
                      itemCount: Equipamento.values.length + 2,
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: TokensStrip.s3,
                            ),
                            child: FxHubHeader(
                              title: 'Disponíveis',
                              subtitle: equipamentosCountLabel(current.length),
                            ),
                          );
                        }
                        if (i == Equipamento.values.length + 1) {
                          return Semantics(
                            selected: noneSelected,
                            button: true,
                            label: 'Sem restrição',
                            child: FxSatelliteListTile(
                              title: 'Sem restrição',
                              subtitle: const Text(
                                'Não filtrar substituições por equipamento.',
                              ),
                              leading: FxIcon(
                                name: 'spark',
                                size: FxSettingsLayout.iconSize,
                                color:
                                    noneSelected
                                        ? primary
                                        : fxScreenMute(context),
                              ),
                              trailing:
                                  noneSelected
                                      ? Icon(
                                        Icons.check_rounded,
                                        color: primary,
                                        size: FxSettingsLayout.iconSize,
                                      )
                                      : null,
                              accent: noneSelected ? primary : null,
                              onTap: _saving ? null : _clearRestriction,
                            ),
                          );
                        }
                        final equipamento = Equipamento.values[i - 1];
                        final selected = current.contains(equipamento);
                        final label =
                            TaxonomyLabels.equipamento[equipamento] ??
                            equipamento.backendName;
                        return Semantics(
                          selected: selected,
                          button: true,
                          label: label,
                          child: FxSatelliteListTile(
                            title: label,
                            leading: FxIcon(
                              name: equipamentoFxIcon(equipamento),
                              size: FxSettingsLayout.iconSize,
                              color:
                                  selected
                                      ? primary
                                      : fxScreenMute(context),
                            ),
                            trailing:
                                selected
                                    ? Icon(
                                      Icons.check_rounded,
                                      color: primary,
                                      size: FxSettingsLayout.iconSize,
                                    )
                                    : null,
                            accent: selected ? primary : null,
                            onTap:
                                _saving ? null : () => _toggle(equipamento),
                          ),
                        );
                      },
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
