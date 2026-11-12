import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../chat/providers/chat_rascunho_provider.dart';
import '../models/trilha.dart';
import '../providers/trilhas_provider.dart';
import '../widgets/trilha_detalhe_sheet.dart';
import '../widgets/trilhas_help_sheet.dart';
import 'trilhas_screen.dart' show TrilhasLista;

/// Trilhas do aluno: o mesmo cartão e o mesmo detalhe do personal, com
/// "Consegui" na etapa atual.
class AlunoTrilhasScreen extends ConsumerStatefulWidget {
  const AlunoTrilhasScreen({super.key});

  @override
  ConsumerState<AlunoTrilhasScreen> createState() => _AlunoTrilhasScreenState();
}

class _AlunoTrilhasScreenState extends ConsumerState<AlunoTrilhasScreen> {
  DateTime? _fetchedAt;
  final _mais = <TrilhaModel>[];
  var _nextPage = 1;
  var _hasMore = false;
  var _loadingMore = false;

  Future<void> _refresh() async {
    _mais.clear();
    _nextPage = 1;
    _hasMore = false;
    ref.invalidate(trilhasMinhasProvider);
    try {
      final lista = await ref.read(trilhasMinhasProvider.future);
      if (mounted) {
        setState(() {
          _fetchedAt = DateTime.now();
          _hasMore = lista.hasMore;
        });
      }
    } catch (_) {}
  }

  Future<void> _carregarMais() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final next = await ref
          .read(trilhasRepositoryProvider)
          .listarMinhas(page: _nextPage);
      if (!mounted) return;
      setState(() {
        _mais.addAll(next.items);
        _nextPage += 1;
        _hasMore = next.hasMore;
        _loadingMore = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMore = false);
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  void _stampFreshness() {
    if (_fetchedAt != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _fetchedAt != null) return;
      setState(() => _fetchedAt = DateTime.now());
    });
  }

  Future<void> _abrir(TrilhaModel trilha) {
    return showTrilhaDetalhe(
      context,
      trilha: trilha,
      doPersonal: false,
      onMudou: (_) => ref.invalidate(trilhasMinhasProvider),
    );
  }

  /// Texto pronto na conversa; nada é enviado sozinho.
  void _pedirTrilha() {
    ref.read(chatAlunoRascunhoProvider.notifier).value =
        'Oi! Queria uma trilha para ';
    context.go('/chat/aluno');
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final async = ref.watch(trilhasMinhasProvider);
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: 'Trilhas',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          safePopOrGo(context, '/dashboard/aluno');
        },
        child: FxShellScaffold(
          useMesh: true,
          constrainWidth: false,
          appBar: FxShellAppBar(
            title: 'Trilhas',
            subtitle: FxHubFreshness.joinCount('Do seu personal', freshness),
            onBack: () => safePopOrGo(context, '/dashboard/aluno'),
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar as trilhas',
                onTap: () => showAlunoTrilhasHelpSheet(context),
              ),
            ],
          ),
          body: async.when(
            loading:
                () => const Padding(
                  padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                  child: SkeletonList(count: 4),
                ),
            error:
                (e, _) => FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: primary,
                  title: 'Não conseguimos carregar as trilhas',
                  message: friendlyError(e),
                  onRetry: _refresh,
                ),
            data: (lista) {
              _stampFreshness();
              final merged = lista.append(
                TrilhaLista(
                  items: _mais,
                  hasMore: _mais.isEmpty ? lista.hasMore : _hasMore,
                ),
              );
              return FxContentWidthLimiter(
                child: TrilhasLista(
                  lista: merged,
                  vazio: FxEmptyState(
                    icon: FxIcons.rota,
                    title: 'Nenhuma trilha ainda',
                    subtitle:
                        'Seu personal monta um caminho em etapas até uma conquista. Quando ele criar, aparece aqui.',
                    action: FxEmptyAction(
                      label: 'Pedir uma trilha ao personal',
                      secondary: true,
                      onTap: _pedirTrilha,
                    ),
                  ),
                  loadingMore: _loadingMore,
                  onRefresh: _refresh,
                  onCarregarMais: _carregarMais,
                  onAbrir: _abrir,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
