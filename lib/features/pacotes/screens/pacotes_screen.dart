import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../data/pacote_repository.dart';
import '../providers/pacotes_provider.dart';
import '../widgets/pacotes_storefront_widgets.dart';

class PacotesScreen extends ConsumerStatefulWidget {
  const PacotesScreen({super.key});

  @override
  ConsumerState<PacotesScreen> createState() => _PacotesScreenState();
}

class _PacotesScreenState extends ConsumerState<PacotesScreen> {
  List<Pacote> _pacotes = [];
  bool _loading = true;
  String? _erro;
  String? _slug;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar({bool force = false}) async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      if (force) invalidatePacotesCaches(ref);
      final home = await ref.read(pacotesHomeProvider.future);
      if (!mounted) return;
      setState(() {
        _pacotes = home.pacotes;
        _slug = home.perfil?.slug;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = friendlyError(e);
        });
      }
    }
  }

  Future<void> _novoPacote() async {
    HapticFeedback.selectionClick();
    final created = await showNovoPacoteSheet(
      context,
      repo: ref.read(pacoteRepositoryProvider),
    );
    if (!mounted || !created) return;
    FeedbackHelper.showSuccess(context, 'Plano criado!');
    await _carregar(force: true);
  }

  Future<void> _desativar(Pacote pacote) async {
    final ok = await confirmDesativarPacote(context, pacote.titulo);
    if (!ok || !mounted) return;
    try {
      await ref.read(pacoteRepositoryProvider).desativar(pacote.id);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      FeedbackHelper.showSuccess(context, 'Plano desativado.');
      await _carregar(force: true);
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  void _copiarLink() => copyStorefrontLink(context, _slug);

  void _verVitrine() => openStorefrontPreview(context, _slug);

  @override
  Widget build(BuildContext context) {
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: 'Planos & link de vendas',
      child: FxShellScaffold(
        appBar: FxShellAppBar(
          title: 'Planos & link de vendas',
          subtitle:
              freshnessLabel ?? 'Planos com preço e link para WhatsApp',
          actions: [
            IconButton(
              icon: const Icon(Icons.link_rounded),
              tooltip: 'Copiar link da página de vendas',
              onPressed: _copiarLink,
            ),
          ],
        ),
        floatingActionButton:
            _loading || _erro != null || _pacotes.isEmpty
                ? null
                : FloatingActionButton.extended(
                  onPressed: _novoPacote,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Novo plano'),
                ),
        body:
            _loading
                ? const PacotesStorefrontSkeleton()
                : _erro != null
                ? PacotesLoadErrorState(
                  message: _erro,
                  onRetry: () => _carregar(force: true),
                )
                : RefreshIndicator(
                  onRefresh: () => _carregar(force: true),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      TokensStrip.s2,
                      TokensStrip.s4,
                      96,
                    ),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const PacotesComoFuncionaCard(),
                      if (_slug != null && _slug!.isNotEmpty) ...[
                        StorefrontLinkCard(
                          slug: _slug!,
                          onCopy: _copiarLink,
                          onPreview: _verVitrine,
                        ),
                        const SizedBox(height: TokensStrip.s3),
                      ],
                      if (_pacotes.isNotEmpty) ...[
                        PacotesOverviewStrip(pacotes: _pacotes),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 2,
                            bottom: TokensStrip.s2,
                          ),
                          child: Text(
                            'Seus planos (aparecem no link acima)',
                            style: TextStyle(
                              color: fxScreenMute(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      if (_pacotes.isEmpty)
                        PacotesEmptyState(onCreate: _novoPacote)
                      else ...[
                        for (var i = 0; i < _pacotes.length; i++)
                          PacoteStorefrontCard(
                            pacote: _pacotes[i],
                            entranceIndex: i,
                            onDelete: () => _desativar(_pacotes[i]),
                          ),
                      ],
                    ],
                  ),
                ),
      ),
    );
  }
}
