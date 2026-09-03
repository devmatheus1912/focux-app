import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/clipboard_sensitive.dart';
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
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/recorrencia_repository.dart';
import '../utils/recorrencia_display.dart';

class RecorrenciaScreen extends ConsumerStatefulWidget {
  const RecorrenciaScreen({super.key});

  @override
  ConsumerState<RecorrenciaScreen> createState() => _RecorrenciaScreenState();
}

class _RecorrenciaScreenState extends ConsumerState<RecorrenciaScreen> {
  List<RecorrenciaAssinatura> _items = [];
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
      final items =
          await RecorrenciaRepository(ref.read(apiClientProvider)).listar();
      if (mounted) {
        setState(() {
          _items = items;
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

  Future<void> _criar() async {
    HapticFeedback.selectionClick();
    final alunos = await AlunoRepository(ref.read(apiClientProvider)).listar();
    if (alunos.isEmpty) {
      if (!mounted) return;
      FeedbackHelper.showWarn(context, 'Cadastre um aluno primeiro.');
      return;
    }
    var alunoId = alunos.first.id;
    var alunoNome = alunos.first.nome;
    final valorCtrl = TextEditingController(text: '199');
    var created = false;

    try {
      if (!mounted) return;
      final ok = await showFxFormSheet(
        context,
        title: 'Nova recorrência',
        icon: Icons.repeat_rounded,
        confirmLabel: 'Criar',
        child: StatefulBuilder(
          builder:
              (ctx, setDialogState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FxInsetPickerRow(
                    icon: Icons.person_outline,
                    label: 'Aluno',
                    value: recorrenciaAlunoLabel(alunoNome),
                    onTap: () async {
                      final picked = await showFxInsetPickerSheet<int>(
                        ctx,
                        title: 'Aluno',
                        selected: alunoId,
                        items: [
                          for (final a in alunos)
                            FxInsetPickerSheetItem(
                              value: a.id,
                              label: recorrenciaAlunoLabel(a.nome),
                            ),
                        ],
                      );
                      if (picked == null) return;
                      Aluno? match;
                      for (final a in alunos) {
                        if (a.id == picked) {
                          match = a;
                          break;
                        }
                      }
                      final aluno = match;
                      if (aluno == null) return;
                      setDialogState(() {
                        alunoId = aluno.id;
                        alunoNome = aluno.nome;
                      });
                    },
                  ),
                  AlunoInsetFormField(
                    controller: valorCtrl,
                    label: 'Valor mensal (R\$)',
                    icon: Icons.payments_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    showDivider: false,
                  ),
                ],
              ),
        ),
      );
      if (ok != true) return;

      final r = await RecorrenciaRepository(ref.read(apiClientProvider)).criar(
        alunoId: alunoId,
        valor: double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 199,
      );
      final link = r.initPoint?.trim();
      if (link != null && link.isNotEmpty) {
        await copySensitiveToClipboard(link);
        if (!mounted) return;
        FeedbackHelper.showSuccess(
          context,
          'Link de assinatura copiado — envie ao aluno.',
        );
      }
      created = true;
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      valorCtrl.dispose();
    }
    if (created) await _load();
  }

  Future<void> _abrirCheckout(String initPoint) async {
    final uri = Uri.tryParse(initPoint);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    return fxScreenA11yScope(
      label: 'Recorrência MP',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Recorrência MP',
          subtitle: recorrenciaHubSubtitle(freshnessLabel),
          onBack: () => context.pop(),
          actions: [
            ShellHeaderIconButton(
              icon: 'plus',
              tooltip: 'Nova recorrência',
              onTap: _criar,
            ),
          ],
        ),
        body:
            _loading
                ? const Padding(
                  padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                  child: SkeletonList(count: 5),
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
    final primary = Theme.of(context).colorScheme.primary;
    return RefreshIndicator(
      onRefresh: _load,
      child: _items.isEmpty
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
                  icon: 'coin',
                  title: 'Nenhuma assinatura ainda',
                  subtitle:
                      'Crie a primeira recorrência para cobrar seus alunos via Mercado Pago.',
                  action: FxEmptyAction(label: 'Nova recorrência', onTap: _criar),
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
              itemCount: _items.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: TokensStrip.s3),
                    child: DashboardSectionHeader(title: 'Assinaturas'),
                  );
                }
                final item = _items[i - 1];
                final danger = recorrenciaDanger(item.status);
                return FxSatelliteListTile(
                  title: recorrenciaAlunoLabel(item.alunoNome),
                  subtitle: Text(
                    recorrenciaSubtitle(
                      status: item.status,
                      proximaCobranca: item.proximaCobranca,
                    ),
                  ),
                  trailing: Text(
                    recorrenciaValorLabel(item.valor),
                    style: FocuxHubTypography.bodyMuted(
                      color: danger
                          ? EagleTokens.bad
                          : fxScreenMute(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  accent: danger
                      ? EagleTokens.bad
                      : recorrenciaPendente(item.status)
                          ? primary
                          : null,
                  onTap: recorrenciaTemLinkCheckout(
                    item.status,
                    item.initPoint,
                  )
                      ? () => _abrirCheckout(item.initPoint!)
                      : null,
                );
              },
            ),
    );
  }
}
