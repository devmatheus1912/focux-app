import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
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
import '../../../features/alunos/widgets/aluno_inset_form_field.dart';
import '../models/trilha.dart';
import '../providers/trilhas_provider.dart';
import '../utils/trilhas_display.dart';

part 'trilhas_screen_cards.part.dart';

class TrilhasScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;

  const TrilhasScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  ConsumerState<TrilhasScreen> createState() => _TrilhasScreenState();
}

class _TrilhasScreenState extends ConsumerState<TrilhasScreen> {
  DateTime? _fetchedAt;

  Future<void> _refresh() async {
    ref.invalidate(trilhasAlunoProvider(widget.alunoId));
    try {
      await ref.read(trilhasAlunoProvider(widget.alunoId).future);
      if (mounted) setState(() => _fetchedAt = DateTime.now());
    } catch (_) {}
  }

  void _stampFreshness() {
    if (_fetchedAt != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _fetchedAt != null) return;
      setState(() => _fetchedAt = DateTime.now());
    });
  }

  Future<void> _criarTrilha() async {
    HapticFeedback.selectionClick();
    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    var metaTipo = 'TREINOS';
    var created = false;

    try {
      if (!mounted) return;
      final ok = await showFxFormSheet(
        context,
        title: 'Nova trilha',
        subtitle: 'Defina o título e o tipo de meta.',
        icon: Icons.flag_outlined,
        confirmLabel: 'Criar trilha',
        child: StatefulBuilder(
          builder:
              (ctx, setSheetState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AlunoInsetFormField(
                    controller: tituloCtrl,
                    label: 'Título da trilha',
                    icon: Icons.title_outlined,
                  ),
                  AlunoInsetFormField(
                    controller: descCtrl,
                    label: 'Descrição (opcional)',
                    icon: Icons.notes_outlined,
                    maxLines: 2,
                  ),
                  FxInsetPickerRow(
                    icon: Icons.flag_outlined,
                    label: 'Tipo de meta',
                    value: trilhaMetaTipoLabel(metaTipo),
                    showDivider: false,
                    onTap: () async {
                      final picked = await showFxInsetPickerSheet<String>(
                        ctx,
                        title: 'Tipo de meta',
                        selected: metaTipo,
                        items: [
                          for (final tipo in trilhaMetaTipos)
                            FxInsetPickerSheetItem(
                              value: tipo,
                              label: trilhaMetaTipoLabel(tipo),
                            ),
                        ],
                      );
                      if (picked == null) return;
                      setSheetState(() => metaTipo = picked);
                    },
                  ),
                ],
              ),
        ),
      );
      if (ok != true) return;
      if (tituloCtrl.text.trim().isEmpty) {
        if (mounted) {
          FeedbackHelper.showWarn(context, 'Título da trilha é obrigatório.');
        }
        return;
      }
      await ref
          .read(trilhasRepositoryProvider)
          .criarTrilha(
            NovaTrilhaRequest(
              alunoId: widget.alunoId,
              titulo: tituloCtrl.text.trim(),
              descricao:
                  descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
              metaTipo: metaTipo,
            ),
          );
      created = true;
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      tituloCtrl.dispose();
      descCtrl.dispose();
    }
    if (created) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final trilhasAsync = ref.watch(trilhasAlunoProvider(widget.alunoId));
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: 'Trilhas de Progresso — ${widget.alunoNome}',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Trilhas de Progresso',
          subtitle: trilhaHubSubtitle(
            alunoNome: widget.alunoNome,
            freshness: freshness,
          ),
          onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
          actions: [
            ShellHeaderIconButton(
              icon: 'plus',
              tooltip: 'Criar nova trilha',
              onTap: _criarTrilha,
            ),
          ],
        ),
        body: trilhasAsync.when(
          loading:
              () => const Padding(
                padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                child: SkeletonList(count: 4),
              ),
          error:
              (e, _) => FxErrorState(
                chromeOnDark: chrome.isDark,
                primary: primary,
                message: friendlyError(e),
                onRetry: _refresh,
                title: 'Não conseguimos carregar as trilhas',
              ),
          data: (trilhas) {
            _stampFreshness();
            return FxContentWidthLimiter(child: _buildBody(trilhas));
          },
        ),
      ),
    );
  }

  Widget _buildBody(List<TrilhaModel> trilhas) {
    if (trilhas.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            FxEmptyState(
              icon: 'route',
              title: 'Nenhuma trilha criada ainda',
              subtitle:
                  'Crie metas com marcos para acompanhar a evolução de ${widget.alunoNome}.',
              action: FxEmptyAction(
                label: 'Criar primeira trilha',
                onTap: _criarTrilha,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          32,
        ),
        itemCount: trilhas.length,
        itemBuilder:
            (ctx, i) => _TrilhaCard(
              trilha: trilhas[i],
              alunoId: widget.alunoId,
              ref: ref,
            ),
      ),
    );
  }
}
