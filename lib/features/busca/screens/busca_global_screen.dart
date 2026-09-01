import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/busca_repository.dart';
import '../models/busca_global_models.dart';
import '../utils/busca_display.dart';
import 'widgets/busca_global_results.dart';

final buscaQueryProvider = StateProvider<String>((ref) => '');
final buscaFilterProvider = StateProvider<BuscaTipo>((ref) => BuscaTipo.todos);

final buscaRepositoryProvider = Provider<BuscaRepository>(
  (ref) => BuscaRepository(ref.read(apiClientProvider)),
);

final buscaResultadoProvider = FutureProvider.autoDispose<BuscaGlobalResult?>((
  ref,
) async {
  final query = ref.watch(buscaQueryProvider);
  if (query.trim().length < buscaMinQueryLength) return null;
  return ref.read(buscaRepositoryProvider).buscar(query);
});

class BuscaGlobalScreen extends ConsumerStatefulWidget {
  const BuscaGlobalScreen({super.key});
  @override
  ConsumerState<BuscaGlobalScreen> createState() => _BuscaGlobalScreenState();
}

class _BuscaGlobalScreenState extends ConsumerState<BuscaGlobalScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ctrl.text = ref.read(buscaQueryProvider);
    _ctrl.addListener(_onQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.removeListener(_onQueryChanged);
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: buscaDebounceMs), () {
      if (!mounted) return;
      ref.read(buscaQueryProvider.notifier).state = _ctrl.text;
    });
  }

  void _clearQuery() {
    HapticFeedback.selectionClick();
    _debounce?.cancel();
    _ctrl.clear();
    ref.read(buscaQueryProvider.notifier).state = '';
  }

  void _showHelp() {
    showFxHelpSheet(
      context,
      title: 'Busca',
      subtitle: 'Encontre aluno, treino ou cobrança sem sair do Personal.',
      tips: const [
        FxHelpTip(
          'Consulta',
          'Digite ao menos 2 caracteres. A busca espera você terminar de escrever.',
          icon: 'search',
        ),
        FxHelpTip(
          'Filtro',
          'Use Alunos, Treinos ou Cobranças para enxugar o que já veio.',
          icon: 'users',
        ),
        FxHelpTip(
          'Destino',
          'Toque no resultado para abrir. Links externos pedem confirmação.',
          icon: 'chevron-right',
        ),
      ],
    );
  }

  Future<void> _abrirItem(BuscaItem item) async {
    final raw = item.url.trim();
    if (raw.isEmpty) {
      _showInfo(buscaDestinationMissing());
      return;
    }

    if (raw.startsWith('/')) {
      final normalized = buscaNormalizePath(raw);
      if (!buscaInternalPathAllowed(normalized)) {
        _showInfo(buscaDestinationForbidden());
        return;
      }
      if (!mounted) return;
      context.push(normalized);
      return;
    }

    Uri? uri;
    try {
      uri = Uri.parse(raw);
    } catch (_) {
      uri = null;
    }
    if (uri == null || !buscaIsHttpUrl(uri)) {
      _showInfo(buscaDestinationUnsupported());
      return;
    }
    if (!mounted) return;
    final ok = await showFxConfirmSheet(
      context,
      title: buscaExternalSheetTitle(),
      message: uri.toString(),
      icon: Icons.open_in_new_rounded,
      confirmLabel: buscaExternalConfirmLabel(),
    );
    if (!ok) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) _showInfo(buscaLaunchFailed());
  }

  void _showInfo(String msg) {
    if (!mounted) return;
    FeedbackHelper.showInfo(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final resultAsync = ref.watch(buscaResultadoProvider);
    final filter = ref.watch(buscaFilterProvider);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final hasQuery = _ctrl.text.isNotEmpty;

    return fxScreenA11yScope(
      label: 'Busca global',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Busca',
          actions: [
            if (hasQuery)
              Padding(
                padding: const EdgeInsets.only(right: TokensStrip.s3),
                child: Center(
                  child: Semantics(
                    button: true,
                    label: 'Limpar busca',
                    child: ShellHeaderIconButton(
                      icon: 'x',
                      tooltip: 'Limpar busca',
                      onTap: _clearQuery,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(buscaResultadoProvider);
            await ref.read(buscaResultadoProvider.future);
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
                  header: 'Consulta',
                  caption: buscaMinQuerySubtitle(),
                  helpTooltip: 'Como buscar',
                  onHelpTap: _showHelp,
                  children: [
                    AlunoInsetFormField(
                      controller: _ctrl,
                      focusNode: _focus,
                      label: 'Campo de busca global',
                      hint: buscaHint(),
                      icon: Icons.search,
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: FxSettingsLayout.groupGap),
                FxSettingsGroup(
                  header: 'Mostrar',
                  children: [
                    for (var i = 0; i < BuscaTipo.values.length; i++)
                      FxSettingsTile(
                        fxIcon: buscaTipoFxIcon(BuscaTipo.values[i]),
                        label: BuscaTipo.values[i].label,
                        value: buscaFilterValue(
                          BuscaTipo.values[i] == filter,
                        ),
                        highlight: BuscaTipo.values[i] == filter,
                        showDivider: i != BuscaTipo.values.length - 1,
                        onTap:
                            () =>
                                ref.read(buscaFilterProvider.notifier).state =
                                    BuscaTipo.values[i],
                      ),
                  ],
                ),
                const SizedBox(height: FxSettingsLayout.groupGap),
                resultAsync.when(
                  loading: () => const SkeletonList(count: 6),
                  error:
                      (e, _) => FxErrorState(
                        chromeOnDark: chrome.isDark,
                        primary: primary,
                        message: friendlyError(e),
                        onRetry: () => ref.invalidate(buscaResultadoProvider),
                      ),
                  data:
                      (result) => BuscaGlobalResults(
                        query: ref.watch(buscaQueryProvider),
                        filter: filter,
                        result: result ?? const BuscaGlobalResult.empty(),
                        onOpen: _abrirItem,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
