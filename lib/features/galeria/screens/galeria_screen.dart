import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/media_upload_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/galeria_repository.dart';
import '../utils/galeria_display.dart';

class GaleriaScreen extends ConsumerStatefulWidget {
  const GaleriaScreen({super.key});
  @override
  ConsumerState<GaleriaScreen> createState() => _GaleriaScreenState();
}

class _GaleriaScreenState extends ConsumerState<GaleriaScreen> {
  List<GalleryItem> _fotos = [];
  var _loading = true;
  var _uploading = false;
  var _loadingMore = false;
  var _hasNext = false;
  var _page = 0;
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
      final pagina = await GaleriaRepository(
        ref.read(apiClientProvider),
      ).listarPagina();
      if (!mounted) return;
      setState(() {
        _fotos = pagina.content;
        _hasNext = pagina.hasNext;
        _page = pagina.page ?? 0;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = friendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _add() async {
    if (_fotos.length >= galeriaMaxFotos) {
      FeedbackHelper.showSuccess(context, galeriaLimitLabel());
      return;
    }
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (file == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final client = ref.read(apiClientProvider);
      final url = await MediaUploadService(client).uploadBytes(
        bytes: await file.readAsBytes(),
        filename: file.name,
        folder: 'galeria',
        resourceType: 'image',
      );
      await GaleriaRepository(client).adicionar(
        fotoUrl: url,
        ordem: _fotos.length,
      );
      await _load();
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _leave() {
    FxKeyboardDismissScope.dismiss();
    safePopOrGo(context, '/dashboard/personal');
  }

  Future<void> _carregarMais() async {
    if (_loadingMore || !_hasNext) return;
    setState(() => _loadingMore = true);
    try {
      final pagina = await GaleriaRepository(
        ref.read(apiClientProvider),
      ).listarPagina(page: _page + 1);
      if (!mounted) return;
      final seen = _fotos.map((f) => f.id).toSet();
      setState(() {
        _fotos = [
          ..._fotos,
          ...pagina.content.where((f) => seen.add(f.id)),
        ];
        _hasNext = pagina.hasNext;
        _page = pagina.page ?? (_page + 1);
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _delete(int id) async {
    final ok = await showFxConfirmSheet(
      context,
      title: 'Remover foto?',
      message: 'Remover esta foto da galeria?',
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (!ok) return;
    try {
      await GaleriaRepository(ref.read(apiClientProvider)).deletar(id);
      await _load();
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final canAdd = !_uploading && _fotos.length < galeriaMaxFotos;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return fxScreenA11yScope(
      label: 'Galeria',
      child: PopScope(
        canPop: !keyboardOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          FxKeyboardDismissScope.dismiss();
        },
        child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Galeria',
          subtitle: FxHubFreshness.joinCount(
            galeriaCountLabel(_fotos.length),
            FxHubFreshness.fromFetchedAt(_fetchedAt),
          ),
          onBack: _leave,
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar a galeria',
              onTap: () => showFxHelpSheet(
                context,
                title: 'Galeria',
                subtitle: 'Fotos do perfil público. No máximo $galeriaMaxFotos.',
                tips: const [
                  FxHelpTip(
                    'Adicionar',
                    'O botão no rodapé envia a foto. Toque no X remove.',
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child:
                  _loading
                      ? const Padding(
                        padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                        child: SkeletonList(count: 4),
                      )
                      : _erro != null
                      ? FxErrorState(
                        chromeOnDark: chrome.isDark,
                        primary: primary,
                        message: _erro!,
                        onRetry: _load,
                        title: 'Não conseguimos carregar a galeria',
                      )
                      : RefreshIndicator(
                        color: primary,
                        onRefresh: _load,
                        child:
                            _fotos.isEmpty
                                ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior
                                          .onDrag,
                                  children: [
                                    FxEmptyState(
                                      icon: 'image',
                                      title: 'Nenhuma foto ainda',
                                      subtitle:
                                          'Adicione até $galeriaMaxFotos fotos para o seu perfil público.',
                                      action: FxEmptyAction(
                                        label: 'Adicionar foto',
                                        onTap: _add,
                                      ),
                                    ),
                                  ],
                                )
                                : GridView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior
                                          .onDrag,
                                  padding: EdgeInsets.fromLTRB(
                                    FxSettingsLayout.pageInset,
                                    TokensStrip.s3,
                                    FxSettingsLayout.pageInset,
                                    TokensStrip.s4 +
                                        MediaQuery.viewInsetsOf(
                                          context,
                                        ).bottom,
                                  ),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: TokensStrip.s2,
                                        mainAxisSpacing: TokensStrip.s2,
                                      ),
                                  itemCount:
                                      _fotos.length + (_hasNext ? 1 : 0),
                                  itemBuilder: (_, i) {
                                    if (i >= _fotos.length) {
                                      return Material(
                                        color: chrome.cardFill,
                                        borderRadius: BorderRadius.circular(
                                          TokensStrip.rCard,
                                        ),
                                        child: InkWell(
                                          onTap: _loadingMore
                                              ? null
                                              : _carregarMais,
                                          borderRadius: BorderRadius.circular(
                                            TokensStrip.rCard,
                                          ),
                                          child: Center(
                                            child: Text(
                                              _loadingMore
                                                  ? 'Carregando…'
                                                  : 'Mais',
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    final f = _fotos[i];
                                    final onSurface =
                                        Theme.of(context).colorScheme.onSurface;
                                    final surface =
                                        Theme.of(context).colorScheme.surface;
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        TokensStrip.rCard,
                                      ),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(
                                            f.fotoUrl,
                                            fit: BoxFit.cover,
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: Material(
                                              color: surface.withValues(
                                                alpha: 0.82,
                                              ),
                                              shape: const CircleBorder(),
                                              child: IconButton(
                                                tooltip: 'Remover foto',
                                                onPressed: () => _delete(f.id),
                                                icon: Icon(
                                                  Icons.close_rounded,
                                                  color: onSurface,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                      ),
            ),
            if (!_loading && _erro == null && canAdd)
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    FxSettingsLayout.pageInset,
                    TokensStrip.s2,
                    FxSettingsLayout.pageInset,
                    TokensStrip.s3 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: FxLiquidPrimaryButton(
                    label: _uploading ? 'Enviando…' : 'Adicionar foto',
                    loading: _uploading,
                    onPressed: _uploading ? null : _add,
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}
