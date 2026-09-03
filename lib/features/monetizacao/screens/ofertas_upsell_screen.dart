import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../features/alunos/widgets/aluno_inset_form_field.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/upsell_repository.dart';
import '../utils/oferta_upsell_display.dart';

final upsellRepositoryProvider = Provider(
  (ref) => UpsellRepository(ref.read(apiClientProvider)),
);

class OfertasUpsellScreen extends ConsumerStatefulWidget {
  const OfertasUpsellScreen({super.key});

  @override
  ConsumerState<OfertasUpsellScreen> createState() =>
      _OfertasUpsellScreenState();
}

class _OfertasUpsellScreenState extends ConsumerState<OfertasUpsellScreen> {
  List<OfertaUpsell> _ofertas = [];
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
      final list = await ref.read(upsellRepositoryProvider).listarOfertas();
      if (mounted) {
        setState(() {
          _ofertas = list;
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
    final tituloCtrl = TextEditingController();
    final descricaoCtrl = TextEditingController();
    final valorCtrl = TextEditingController();
    var tipoGatilho = 'MANUAL';
    var created = false;

    try {
      if (!mounted) return;
      final ok = await showFxFormSheet(
        context,
        title: 'Nova oferta',
        subtitle: 'Dispara no gatilho que você escolher.',
        icon: Icons.local_offer_outlined,
        confirmLabel: 'Criar oferta',
        child: StatefulBuilder(
          builder:
              (ctx, setDialogState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AlunoInsetFormField(
                    controller: tituloCtrl,
                    label: 'Título',
                    icon: Icons.title_outlined,
                  ),
                  AlunoInsetFormField(
                    controller: descricaoCtrl,
                    label: 'Descrição',
                    icon: Icons.notes_outlined,
                    maxLines: 2,
                  ),
                  AlunoInsetFormField(
                    controller: valorCtrl,
                    label: 'Valor (R\$)',
                    icon: Icons.payments_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  FxInsetPickerRow(
                    icon: Icons.bolt_outlined,
                    label: 'Gatilho',
                    value: ofertaGatilhoLabel(tipoGatilho),
                    showDivider: false,
                    onTap: () async {
                      final picked = await showFxInsetPickerSheet<String>(
                        ctx,
                        title: 'Gatilho',
                        selected: tipoGatilho,
                        items: [
                          for (final value in ofertaGatilhoValues)
                            FxInsetPickerSheetItem(
                              value: value,
                              label: ofertaGatilhoLabel(value),
                            ),
                        ],
                      );
                      if (picked == null) return;
                      setDialogState(() => tipoGatilho = picked);
                    },
                  ),
                ],
              ),
        ),
      );
      if (ok != true) return;
      final valor = double.tryParse(valorCtrl.text.replaceAll(',', '.'));
      if (tituloCtrl.text.trim().isEmpty || valor == null || valor <= 0) {
        if (mounted) {
          FeedbackHelper.showError(context, 'Preencha título e valor válido');
        }
        return;
      }
      await ref
          .read(upsellRepositoryProvider)
          .criar(
            titulo: tituloCtrl.text.trim(),
            descricao: descricaoCtrl.text.trim(),
            valor: valor,
            tipoGatilho: tipoGatilho,
          );
      created = true;
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Oferta criada');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(
          context,
          friendlyError(e, fallback: 'Erro ao criar oferta'),
        );
      }
    } finally {
      tituloCtrl.dispose();
      descricaoCtrl.dispose();
      valorCtrl.dispose();
    }
    if (created) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: 'Ofertas para alunos',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Ofertas para alunos',
          subtitle: ofertaHubSubtitle(freshnessLabel),
          fallbackLocation: '/assinatura',
          actions: [
            ShellHeaderIconButton(
              icon: 'plus',
              tooltip: 'Nova oferta',
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
                  title: 'Não carregamos as ofertas',
                )
                : FxContentWidthLimiter(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _load,
      child:
          _ofertas.isEmpty
              ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  8,
                  FxSettingsLayout.pageInset,
                  32,
                ),
                children: [
                  FxEmptyState(
                    icon: 'spark',
                    title: 'Nenhuma oferta ativa',
                    subtitle:
                        'Crie a primeira oferta. Ela aparece para o aluno no gatilho escolhido (manual, check-in ou trilha).',
                    action: FxEmptyAction(label: 'Nova oferta', onTap: _criar),
                  ),
                ],
              )
              : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s3,
                  FxSettingsLayout.pageInset,
                  TokensStrip.s6,
                ),
                itemCount: _ofertas.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: TokensStrip.s3),
                      child: DashboardSectionHeader(title: 'Ativas'),
                    );
                  }
                  final oferta = _ofertas[i - 1];
                  return FxSatelliteListTile(
                    title: oferta.titulo,
                    subtitle: Text(
                      ofertaSubtitle(
                        tipoGatilho: oferta.tipoGatilho,
                        descricao: oferta.descricao,
                      ),
                    ),
                    trailing: Text(
                      ofertaValorLabel(oferta.valor),
                      style: FocuxHubTypography.bodyMuted(
                        color: fxScreenMute(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
