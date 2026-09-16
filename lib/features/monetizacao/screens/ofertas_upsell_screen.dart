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
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/upsell_repository.dart';
import '../utils/oferta_upsell_display.dart';
import '../widgets/oferta_upsell_editor.dart';

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

  Future<void> _abrirEditor({OfertaUpsell? existing}) async {
    HapticFeedback.selectionClick();
    if (!mounted) return;
    final result = await showOfertaUpsellEditor(context, existing: existing);
    if (!result.submitted) return;
    final draft = result.draft;
    if (draft == null) {
      if (mounted) {
        FeedbackHelper.showError(context, 'Preencha título e valor válido');
      }
      return;
    }
    try {
      final repo = ref.read(upsellRepositoryProvider);
      if (existing == null) {
        await repo.criar(
          titulo: draft.titulo,
          descricao: draft.descricao,
          valor: draft.valor,
          tipoGatilho: draft.tipoGatilho,
        );
        if (mounted) FeedbackHelper.showSuccess(context, 'Oferta criada');
      } else {
        await repo.atualizar(
          id: existing.id,
          titulo: draft.titulo,
          descricao: draft.descricao,
          valor: draft.valor,
          tipoGatilho: draft.tipoGatilho,
          ativo: draft.ativo,
        );
        if (mounted) FeedbackHelper.showSuccess(context, 'Oferta atualizada');
      }
      await _load();
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(
          context,
          friendlyError(
            e,
            fallback:
                existing == null
                    ? 'Erro ao criar oferta'
                    : 'Erro ao salvar oferta',
          ),
        );
      }
    }
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
              onTap: () => _abrirEditor(),
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
    final ativas = _ofertas.where((o) => o.ativo).toList();
    final pausadas = _ofertas.where((o) => !o.ativo).toList();

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
                    title: 'Nenhuma oferta ainda',
                    subtitle:
                        'Crie a primeira oferta. Ela aparece para o aluno no gatilho escolhido (manual, check-in ou trilha).',
                    action: FxEmptyAction(
                      label: 'Nova oferta',
                      onTap: () => _abrirEditor(),
                    ),
                  ),
                ],
              )
              : ListView(
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
                  if (ativas.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: TokensStrip.s3),
                      child: DashboardSectionHeader(
                        title: ofertaSectionTitle(ativo: true),
                      ),
                    ),
                    for (final oferta in ativas) _tile(oferta),
                  ],
                  if (pausadas.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.only(
                        top: ativas.isEmpty ? 0 : TokensStrip.s4,
                        bottom: TokensStrip.s3,
                      ),
                      child: DashboardSectionHeader(
                        title: ofertaSectionTitle(ativo: false),
                      ),
                    ),
                    for (final oferta in pausadas) _tile(oferta),
                  ],
                ],
              ),
    );
  }

  Widget _tile(OfertaUpsell oferta) {
    return FxSatelliteListTile(
      title: oferta.titulo,
      subtitle: Text(
        ofertaSubtitle(
          tipoGatilho: oferta.tipoGatilho,
          descricao: oferta.descricao,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ofertaValorLabel(oferta.valor),
            style: FocuxHubTypography.bodyMuted(
              color: fxScreenMute(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: TokensStrip.s2),
          Icon(
            Icons.chevron_right_rounded,
            color: fxScreenMute(context),
          ),
        ],
      ),
      onTap: () => _abrirEditor(existing: oferta),
    );
  }
}
