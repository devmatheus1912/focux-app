import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_cached_network_image.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/evolucao_repository.dart';
import '../utils/evolucao_fotos_display.dart';

class EvolucaoFotosScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;
  const EvolucaoFotosScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });
  @override
  ConsumerState<EvolucaoFotosScreen> createState() => _State();
}

class _State extends ConsumerState<EvolucaoFotosScreen> {
  final _picker = ImagePicker();
  List<FotoEvolucao> _fotos = [];
  var _loading = true;
  var _uploading = false;
  var _loadingMore = false;
  var _hasNext = false;
  var _page = 0;
  var _total = 0;
  String? _erro;
  DateTime? _fetchedAt;
  int? _selBefore;
  int? _selAfter;
  double _slider = 0.5;

  EvolucaoRepository get _repo =>
      EvolucaoRepository(ref.read(apiClientProvider));

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _leave() {
    FxKeyboardDismissScope.dismiss();
    safePopOrGo(context, '/alunos/${widget.alunoId}/evolucao');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final pagina = await _repo.listarFotosPagina(widget.alunoId);
      if (!mounted) return;
      setState(() {
        _fotos = pagina.content;
        _hasNext = pagina.hasNext;
        _page = pagina.page ?? 0;
        _total = pagina.totalElements ?? pagina.content.length;
        _loading = false;
        _fetchedAt = DateTime.now();
        _selBefore = null;
        _selAfter = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = friendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _carregarMais() async {
    if (_loadingMore || !_hasNext) return;
    setState(() => _loadingMore = true);
    try {
      final pagina = await _repo.listarFotosPagina(
        widget.alunoId,
        page: _page + 1,
      );
      if (!mounted) return;
      final seen = _fotos.map((f) => f.id).toSet();
      setState(() {
        _fotos = [
          ..._fotos,
          ...pagina.content.where((f) => seen.add(f.id)),
        ];
        _hasNext = pagina.hasNext;
        _page = pagina.page ?? (_page + 1);
        _total = pagina.totalElements ?? _fotos.length;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _addFoto() async {
    if (_uploading) return;
    final src = await showFxHomeSheet<ImageSource>(
      context,
      builder: (ctx) {
        final chrome = ShellChrome.of(ctx);
        final primary = Theme.of(ctx).colorScheme.primary;
        return FxHomeSheetSurface(
          isDark: chrome.isDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FxHomeSheetHandle(isDark: chrome.isDark),
              SizedBox(height: TokensStrip.s4),
              FxHomeSheetHeader(
                isDark: chrome.isDark,
                title: 'Adicionar foto',
                subtitle: 'Escolha de onde vem a foto de evolução.',
                leading: Icon(
                  Icons.add_a_photo_outlined,
                  color: primary,
                  size: 18,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.camera_alt_outlined, color: primary),
                title: const Text('Câmera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.photo_library_outlined, color: primary),
                title: const Text('Galeria'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (src == null) return;
    final file = await _picker.pickImage(
      source: src,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      await _repo.adicionarFoto(
        widget.alunoId,
        bytes: await file.readAsBytes(),
        filename: file.name,
      );
      HapticFeedback.mediumImpact();
      await _load();
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return fxScreenA11yScope(
      label: 'Fotos de evolução',
      child: PopScope(
        canPop: !keyboardOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          FxKeyboardDismissScope.dismiss();
        },
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Fotos',
            subtitle: FxHubFreshness.joinCount(
              evolucaoFotosCountLabel(_loading ? 0 : _total),
              _loading ? null : FxHubFreshness.fromFetchedAt(_fetchedAt),
            ),
            onBack: _leave,
          ),
          body: Column(
            children: [
              Expanded(
                child: _loading
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
                        title: 'Não conseguimos carregar as fotos',
                      )
                    : RefreshIndicator(
                        color: primary,
                        onRefresh: _load,
                        child: _fotos.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                children: [
                                  FxEmptyState(
                                    icon: 'spark',
                                    title: 'Nenhuma foto de evolução',
                                    subtitle:
                                        'Tire a primeira foto para acompanhar ${satelliteFirstName(widget.alunoNome)}.',
                                    action: FxEmptyAction(
                                      label: 'Adicionar foto',
                                      onTap: _addFoto,
                                    ),
                                  ),
                                ],
                              )
                            : _content(chrome, primary),
                      ),
              ),
              if (!_loading && _erro == null && _fotos.isNotEmpty)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      TokensStrip.s2,
                      FxSettingsLayout.pageInset,
                      TokensStrip.s3 +
                          MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: FxLiquidPrimaryButton(
                      label: _uploading ? 'Enviando…' : 'Adicionar foto',
                      loading: _uploading,
                      onPressed: _uploading ? null : _addFoto,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(ShellPalette chrome, Color primary) => CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    slivers: [
      if (_selBefore != null && _selAfter != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              TokensStrip.s3,
              FxSettingsLayout.pageInset,
              TokensStrip.s2,
            ),
            child: Column(
              children: [
                _comparison(chrome),
                Slider(
                  value: _slider,
                  onChanged: (v) => setState(() => _slider = v),
                  activeColor: primary,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Antes',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: chrome.mute,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _selBefore = null;
                        _selAfter = null;
                      }),
                      child: const Text('Limpar'),
                    ),
                    Text(
                      'Depois',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: chrome.mute,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s3,
          FxSettingsLayout.pageInset,
          TokensStrip.s4 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: TokensStrip.s2,
            crossAxisSpacing: TokensStrip.s2,
          ),
          delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              if (i >= _fotos.length) {
                return Material(
                  color: chrome.cardFill,
                  borderRadius: BorderRadius.circular(TokensStrip.rCard),
                  child: InkWell(
                    onTap: _loadingMore ? null : _carregarMais,
                    borderRadius: BorderRadius.circular(TokensStrip.rCard),
                    child: Center(
                      child: Text(
                        _loadingMore ? 'Carregando…' : 'Mais',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }
              final f = _fotos[i];
              final isB = _selBefore == i;
              final isA = _selAfter == i;
              final surface = Theme.of(ctx).colorScheme.surface;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (_selBefore == null) {
                    setState(() => _selBefore = i);
                  } else if (_selAfter == null && _selBefore != i) {
                    setState(() => _selAfter = i);
                  } else {
                    setState(() {
                      _selBefore = i;
                      _selAfter = null;
                    });
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(TokensStrip.rCard),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FxCachedNetworkImage(
                        imageUrl: f.url,
                        fit: BoxFit.cover,
                        memCacheWidth: 480,
                      ),
                      if (isB || isA)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isB ? EagleTokens.warn : EagleTokens.good,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(
                              TokensStrip.rCard,
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: surface.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Text(
                              evolucaoFotosDateLabel(f.data),
                              style: TextStyle(
                                color: Theme.of(ctx).colorScheme.onSurface,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: _fotos.length + (_hasNext ? 1 : 0),
          ),
        ),
      ),
    ],
  );

  Widget _comparison(ShellPalette chrome) {
    final w = MediaQuery.sizeOf(context).width - (FxSettingsLayout.pageInset * 2);
    return ClipRRect(
      borderRadius: BorderRadius.circular(TokensStrip.rCard),
      child: SizedBox(
        height: 300,
        width: w,
        child: Stack(
          children: [
            FxCachedNetworkImage(
              imageUrl: _fotos[_selAfter!].url,
              fit: BoxFit.cover,
              width: w,
              height: 300,
              memCacheWidth: 900,
            ),
            ClipRect(
              clipper: _Clip(_slider, w),
              child: FxCachedNetworkImage(
                imageUrl: _fotos[_selBefore!].url,
                fit: BoxFit.cover,
                width: w,
                height: 300,
                memCacheWidth: 900,
              ),
            ),
            Positioned(
              left: w * _slider - 1,
              top: 0,
              bottom: 0,
              child: ColoredBox(color: chrome.cardFill, child: const SizedBox(width: 3)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Clip extends CustomClipper<Rect> {
  final double f;
  final double w;
  _Clip(this.f, this.w);
  @override
  Rect getClip(Size s) => Rect.fromLTWH(0, 0, w * f, s.height);
  @override
  bool shouldReclip(_Clip o) => o.f != f;
}
