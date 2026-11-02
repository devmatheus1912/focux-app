import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_cached_network_image.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/evolucao_repository.dart';
import '../utils/evolucao_display.dart';
import '../utils/evolucao_fotos_display.dart';
import '../widgets/evolucao_foto_tela_cheia.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../l10n/pt.dart';

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
  String? _erro;
  var _comparando = false;
  FotoEvolucao? _selBefore;
  FotoEvolucao? _selAfter;
  double _slider = 0.5;

  EvolucaoRepository get _repo =>
      EvolucaoRepository(ref.read(apiClientProvider));

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
      final pagina = await _repo.listarFotosPagina(widget.alunoId);
      if (!mounted) return;
      setState(() {
        _fotos = pagina.content;
        _hasNext = pagina.hasNext;
        _page = pagina.page ?? 0;
        _loading = false;
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
        _fotos = [..._fotos, ...pagina.content.where((f) => seen.add(f.id))];
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

  Future<void> _addFoto() async {
    if (_uploading) return;
    final src = await showFxGroupedActionSheet<ImageSource>(
      context,
      titulo: ptS.evolucaoFotoAdicionar,
      icone: Icons.add_a_photo_outlined,
      grupos: [
        FxActionGroup<ImageSource>(ptS.evolucaoFotoOrigem, [
          FxActionItem(
            valor: ImageSource.camera,
            rotulo: ptS.evolucaoFotoCamera,
            icone: Icons.camera_alt_outlined,
          ),
          FxActionItem(
            valor: ImageSource.gallery,
            rotulo: ptS.evolucaoFotoGaleria,
            icone: Icons.photo_library_outlined,
          ),
        ]),
      ],
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
        child: _corpo(chrome, primary),
      ),
    );
  }

  Widget _corpo(ShellPalette chrome, Color primary) => Column(
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
                  title: 'Não conseguimos carregar as fotos',
                )
                : RefreshIndicator(
                  color: primary,
                  onRefresh: _load,
                  child:
                      _fotos.isEmpty
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
            padding: const EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              TokensStrip.s2,
              FxSettingsLayout.pageInset,
              TokensStrip.s3,
            ),
            child: FxLiquidPrimaryButton(
              label: _uploading ? 'Enviando…' : 'Adicionar foto',
              loading: _uploading,
              onPressed: _uploading ? null : _addFoto,
            ),
          ),
        ),
    ],
  );

  void _tocar(FotoEvolucao f) {
    HapticFeedback.selectionClick();
    if (!_comparando) {
      abrirFotoEmTelaCheia(
        context,
        url: f.url,
        legenda: [
          evolucaoFotosDateLabel(f.data),
          if (evolucaoAutorLabel(f.registradoPor) case final autor?) autor,
        ].join(' · '),
        onExcluir: () => _excluirFoto(f),
      );
      return;
    }
    setState(() {
      if (_selBefore == null || (_selAfter != null)) {
        _selBefore = f;
        _selAfter = null;
      } else if (_selBefore!.id != f.id) {
        _selAfter = f;
      }
    });
  }

  Widget _miniatura(FotoEvolucao f, ShellPalette chrome) {
    final isB = _selBefore?.id == f.id;
    final isA = _selAfter?.id == f.id;
    return Semantics(
      button: true,
      selected: isB || isA,
      label: evolucaoFotosDateLabel(f.data),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _tocar(f),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FxCachedNetworkImage(
                imageUrl: f.url,
                fit: BoxFit.cover,
                memCacheWidth: 360,
              ),
              if (isB || isA)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isB ? EagleTokens.warn : EagleTokens.good,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(TokensStrip.rCard),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(ShellPalette chrome, Color primary) {
    final grupos = fotosPorMes(_fotos);
    return CustomScrollView(
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
                        ptS.evolucaoFotoAntes,
                        style: FocuxHubTypography.chip(chrome.mute),
                      ),
                      Text(
                        ptS.evolucaoFotoDepois,
                        style: FocuxHubTypography.chip(chrome.mute),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              TokensStrip.s3,
              FxSettingsLayout.pageInset,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _comparando ? ptS.evolucaoFotoEscolhaDuas : ptS.evolucaoFotoDica,
                    style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                  ),
                ),
                if (_fotos.length >= 2)
                  FxTonalButton(
                    label: _comparando ? ptS.evolucaoFotoFechar : ptS.evolucaoFotoComparar,
                    compact: true,
                    onPressed:
                        () => setState(() {
                          _comparando = !_comparando;
                          _selBefore = null;
                          _selAfter = null;
                        }),
                  ),
              ],
            ),
          ),
        ),
        for (final (mes, fotos) in grupos) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                TokensStrip.s3,
                FxSettingsLayout.pageInset,
                TokensStrip.s2,
              ),
              child: Text(mes, style: FocuxHubTypography.chip(chrome.mute)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: FxSettingsLayout.pageInset,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: TokensStrip.s2,
                crossAxisSpacing: TokensStrip.s2,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _miniatura(fotos[i], chrome),
                childCount: fotos.length,
              ),
            ),
          ),
        ],
        if (_hasNext)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(FxSettingsLayout.pageInset),
              child: FxTonalButton(
                label: _loadingMore ? ptS.agendaAlunoCarregando : ptS.escolherCarregarMais,
                expanded: true,
                onPressed: _loadingMore ? null : _carregarMais,
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: SizedBox(height: TokensStrip.s4 + MediaQuery.viewInsetsOf(context).bottom),
        ),
      ],
    );
  }

  Future<void> _excluirFoto(FotoEvolucao foto) async {
    final ok = await showFxConfirmSheet(
      context,
      title: ptS.evolucaoExcluirFotoTitulo,
      message: ptS.evolucaoExcluirFotoMensagem,
      icon: Icons.delete_outline_rounded,
      confirmLabel: ptS.evolucaoExcluir,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await _repo.excluirFoto(widget.alunoId, foto.id);
      await _load();
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Widget _comparison(ShellPalette chrome) {
    final w =
        MediaQuery.sizeOf(context).width - (FxSettingsLayout.pageInset * 2);
    return ClipRRect(
      borderRadius: BorderRadius.circular(TokensStrip.rCard),
      child: SizedBox(
        height: 300,
        width: w,
        child: Stack(
          children: [
            FxCachedNetworkImage(
              imageUrl: _selAfter!.url,
              fit: BoxFit.cover,
              width: w,
              height: 300,
              memCacheWidth: 900,
            ),
            ClipRect(
              clipper: _Clip(_slider, w),
              child: FxCachedNetworkImage(
                imageUrl: _selBefore!.url,
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
              child: ColoredBox(
                color: chrome.cardFill,
                child: const SizedBox(width: 3),
              ),
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
