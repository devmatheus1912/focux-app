import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../exercicios/data/enums.dart';
import '../../exercicios/data/exercicio_taxonomy_labels.dart';
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
  Set<Equipamento>? _selected;
  bool _saving = false;

  void _hydrate(Set<Equipamento> fromAluno) {
    if (_selected != null) return;
    _selected = {...fromAluno};
  }

  void _toggle(Equipamento equipamento) {
    final current = {...(_selected ?? <Equipamento>{})};
    if (current.contains(equipamento)) {
      current.remove(equipamento);
    } else {
      current.add(equipamento);
    }
    setState(() => _selected = current);
  }

  Future<void> _save() async {
    final selected = _selected;
    if (selected == null || _saving) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    try {
      await ref
          .read(alunoRepositoryProvider)
          .atualizarEquipamentos(widget.alunoId, selected);
      ref.invalidate(alunoProvider(widget.alunoId));
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, equipamentosSaveSuccess());
      Navigator.pop(context, true);
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
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Equipamentos',
          subtitle: satelliteFirstName(alunoAsync.valueOrNull?.nome),
          onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: TokensStrip.s3),
              child: Center(
                child: Semantics(
                  button: true,
                  label: 'Salvar',
                  child: ShellHeaderIconButton(
                    icon: 'circle-check',
                    tooltip: 'Salvar',
                    onTap: _saving ? () {} : _save,
                  ),
                ),
              ),
            ),
          ],
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
            final current = _selected ?? {};
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(alunoProvider(widget.alunoId));
                final fresh = await ref.read(
                  alunoProvider(widget.alunoId).future,
                );
                if (!mounted) return;
                setState(
                  () => _selected = {...fresh.equipamentosDisponiveis},
                );
              },
              child: FxContentWidthLimiter(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    FxSettingsLayout.pageInset,
                    TokensStrip.s3,
                    FxSettingsLayout.pageInset,
                    TokensStrip.s6,
                  ),
                  children: [
                    FxSettingsGroup(
                      header: 'Disponíveis',
                      caption:
                          'Filtra substituições inteligentes para não prescrever o que o aluno não consegue executar.',
                      children: [
                        for (var i = 0; i < Equipamento.values.length; i++)
                          FxSettingsTile(
                            fxIcon: equipamentoFxIcon(Equipamento.values[i]),
                            label:
                                TaxonomyLabels.equipamento[Equipamento
                                    .values[i]] ??
                                Equipamento.values[i].backendName,
                            value: equipamentoChoiceValue(
                              current.contains(Equipamento.values[i]),
                            ),
                            highlight: current.contains(Equipamento.values[i]),
                            showDivider: i != Equipamento.values.length - 1,
                            onTap:
                                _saving
                                    ? () {}
                                    : () => _toggle(Equipamento.values[i]),
                          ),
                      ],
                    ),
                    const SizedBox(height: FxSettingsLayout.groupGap),
                    FxSettingsGroup(
                      children: [
                        FxSettingsTile(
                          fxIcon: 'x',
                          label: 'Sem restrição',
                          subtitle:
                              'Não filtrar substituições por equipamento.',
                          value: '',
                          showDivider: false,
                          onTap:
                              _saving
                                  ? () {}
                                  : () => setState(() => _selected = {}),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
