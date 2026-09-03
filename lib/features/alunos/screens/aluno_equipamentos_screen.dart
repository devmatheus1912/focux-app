import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
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
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              TokensStrip.s2,
              FxSettingsLayout.pageInset,
              TokensStrip.s3,
            ),
            child: Semantics(
              button: true,
              enabled: !_saving,
              label: _saving ? 'Salvando equipamentos' : 'Salvar',
              child: FxLiquidPrimaryButton(
                label: 'Salvar',
                loading: _saving,
                loadingLabel: 'Salvando…',
                onPressed: _saving ? null : _save,
              ),
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
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    FxSettingsLayout.pageInset,
                    TokensStrip.s3,
                    FxSettingsLayout.pageInset,
                    88,
                  ),
                  itemCount: Equipamento.values.length + 2,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: TokensStrip.s3),
                        child: DashboardSectionHeader(title: 'Disponíveis'),
                      );
                    }
                    if (i == Equipamento.values.length + 1) {
                      return FxSatelliteListTile(
                        title: 'Sem restrição',
                        subtitle: const Text(
                          'Não filtrar substituições por equipamento.',
                        ),
                        onTap: _saving
                            ? null
                            : () => setState(() => _selected = {}),
                      );
                    }
                    final equipamento = Equipamento.values[i - 1];
                    final selected = current.contains(equipamento);
                    final primary =
                        Theme.of(context).colorScheme.primary;
                    return FxSatelliteListTile(
                      title:
                          TaxonomyLabels.equipamento[equipamento] ??
                          equipamento.backendName,
                      trailing: Text(
                        equipamentoChoiceValue(selected),
                        style: FocuxHubTypography.bodyMuted(
                          color: selected
                              ? primary
                              : fxScreenMute(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      accent: selected ? primary : null,
                      onTap: _saving
                          ? null
                          : () => _toggle(equipamento),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
