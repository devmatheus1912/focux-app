import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';

import '../../../core/api/media_upload_service.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/feed_repository.dart';
import '../widgets/feed_comments_sheet.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:focux_app/core/widgets/fx_empty_state.dart';
import 'package:focux_app/core/widgets/fx_error_state.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/skeleton_loader.dart';

part 'feed_screen_widgets.part.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final Map<int, int> _curtidasLocais = {};
  final Map<int, int> _comentariosLocais = {};
  List<FeedPost> _posts = [];
  bool _loading = true;
  String? _erro;

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
      final posts =
          await FeedRepository(ref.read(apiClientProvider)).listarPersonal();
      if (!mounted) return;
      setState(() {
        _posts = posts;
        for (final p in posts) {
          _curtidasLocais[p.id] = p.totalCurtidas;
          _comentariosLocais[p.id] = p.totalComentarios;
        }
        _loading = false;
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

  Future<void> _deletar(int id) async {
    try {
      await FeedRepository(ref.read(apiClientProvider)).deletar(id);
      await _load();
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _toggleFixar(int id) async {
    try {
      await FeedRepository(ref.read(apiClientProvider)).toggleFixar(id);
      await _load();
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _curtir(int postId) async {
    try {
      final novoTotal = await FeedRepository(
        ref.read(apiClientProvider),
      ).toggleCurtida(postId);
      if (mounted) {
        setState(() => _curtidasLocais[postId] = novoTotal);
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  void _abrirComentarios(int postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder:
          (ctx) => FeedCommentsSheet(
            postId: postId,
            repo: FeedRepository(ref.read(apiClientProvider)),
            onComentou:
                (novoTotal) =>
                    setState(() => _comentariosLocais[postId] = novoTotal),
          ),
    );
  }

  void _abrirFormulario() {
    final formKey = GlobalKey<FormState>();
    final tituloCtrl = TextEditingController();
    final conteudoCtrl = TextEditingController();
    String tipoSelecionado = 'TEXTO';
    XFile? midiaSelecionada;
    bool salvando = false;
    bool escolhendoMidia = false;

    Future<void> escolherMidia(StateSetter setModalState, String tipo) async {
      if (escolhendoMidia) return;
      setModalState(() => escolhendoMidia = true);
      try {
        final picker = ImagePicker();
        final file =
            tipo == 'VIDEO'
                ? await picker.pickVideo(source: ImageSource.gallery)
                : await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 86,
                  maxWidth: 1600,
                );
        if (file != null) {
          setModalState(() => midiaSelecionada = file);
        }
      } finally {
        setModalState(() => escolhendoMidia = false);
      }
    }

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setModalState) => Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 20,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                  ),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Nova Publicação',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Fechar',
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.of(ctx).pop(),
                                ),
                              ],
                            ),
                            const SizedBox(height: TokensStrip.s4),
                            DropdownButtonFormField<String>(
                              initialValue: tipoSelecionado,
                              decoration: InputDecoration(
                                labelText: 'Tipo de post',
                                border: FxInputDeco.outlineBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                prefixIcon: Icon(Icons.category),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'TEXTO',
                                  child: Text('Texto'),
                                ),
                                DropdownMenuItem(
                                  value: 'IMAGEM',
                                  child: Text('Imagem'),
                                ),
                                DropdownMenuItem(
                                  value: 'VIDEO',
                                  child: Text('Vídeo'),
                                ),
                                DropdownMenuItem(
                                  value: 'ENQUETE',
                                  child: Text('Enquete'),
                                ),
                                DropdownMenuItem(
                                  value: 'DICA',
                                  child: Text('Dica rápida'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setModalState(() {
                                    tipoSelecionado = v;
                                    if (v != 'IMAGEM' && v != 'VIDEO') {
                                      midiaSelecionada = null;
                                    }
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: tituloCtrl,
                              decoration: InputDecoration(
                                labelText: 'Título',
                                border: FxInputDeco.outlineBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                prefixIcon: Icon(Icons.title),
                              ),
                              validator:
                                  (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Informe o título'
                                          : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: conteudoCtrl,
                              decoration: InputDecoration(
                                labelText: 'Conteúdo',
                                border: FxInputDeco.outlineBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                prefixIcon: Icon(Icons.text_fields),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 4,
                              validator:
                                  (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Informe o conteúdo'
                                          : null,
                            ),
                            if (tipoSelecionado == 'IMAGEM' ||
                                tipoSelecionado == 'VIDEO') ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed:
                                    salvando || escolhendoMidia
                                        ? null
                                        : () => escolherMidia(
                                          setModalState,
                                          tipoSelecionado,
                                        ),
                                icon:
                                    escolhendoMidia
                                        ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: FxLoading(strokeWidth: 2),
                                        )
                                        : Icon(
                                          tipoSelecionado == 'VIDEO'
                                              ? Icons.video_library_outlined
                                              : Icons.photo_library_outlined,
                                        ),
                                label: Text(
                                  midiaSelecionada == null
                                      ? (tipoSelecionado == 'VIDEO'
                                          ? 'Escolher vídeo'
                                          : 'Escolher imagem')
                                      : 'Trocar arquivo',
                                ),
                              ),
                              if (midiaSelecionada != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(ctx).colorScheme.primary
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(
                                      TokensStrip.rCard,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        tipoSelecionado == 'VIDEO'
                                            ? Icons.movie_outlined
                                            : Icons.image_outlined,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          midiaSelecionada!.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Remover arquivo',
                                        visualDensity: VisualDensity.compact,
                                        onPressed:
                                            salvando
                                                ? null
                                                : () => setModalState(
                                                  () => midiaSelecionada = null,
                                                ),
                                        icon: const Icon(Icons.close, size: 18),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                            const SizedBox(height: TokensStrip.s5),
                            FxLiquidPrimaryButton(
                              label: salvando ? 'Publicando...' : 'Publicar',
                              icon: Icons.send,
                              loading: salvando,
                              onPressed:
                                  salvando
                                      ? null
                                      : () async {
                                        if (!formKey.currentState!.validate()) {
                                          return;
                                        }
                                        setModalState(() => salvando = true);
                                        try {
                                          String? midiaUrl;
                                          if (midiaSelecionada != null &&
                                              (tipoSelecionado == 'IMAGEM' ||
                                                  tipoSelecionado == 'VIDEO')) {
                                            midiaUrl = await MediaUploadService(
                                              ref.read(apiClientProvider),
                                            ).uploadBytes(
                                              bytes:
                                                  await midiaSelecionada!
                                                      .readAsBytes(),
                                              filename: midiaSelecionada!.name,
                                              folder:
                                                  tipoSelecionado == 'VIDEO'
                                                      ? 'feed/videos'
                                                      : 'feed/images',
                                              resourceType:
                                                  tipoSelecionado == 'VIDEO'
                                                      ? 'video'
                                                      : 'image',
                                            );
                                          }
                                          await FeedRepository(
                                            ref.read(apiClientProvider),
                                          ).criar(
                                            tituloCtrl.text.trim(),
                                            conteudoCtrl.text.trim(),
                                            tipoPost: tipoSelecionado,
                                            midiaUrl: midiaUrl,
                                          );
                                          if (ctx.mounted) {
                                            Navigator.of(ctx).pop(true);
                                          }
                                        } catch (e) {
                                          if (ctx.mounted) {
                                            setModalState(
                                              () => salvando = false,
                                            );
                                            FeedbackHelper.showError(
                                              ctx,
                                              friendlyError(e),
                                            );
                                          }
                                        }
                                      },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ),
    ).then((created) async {
      if (created != true || !mounted) return;
      await _load();
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Publicação criada com sucesso!');
    });
  }

  IconData _getIconForTipo(String? tipo) {
    switch (tipo?.toUpperCase()) {
      case 'IMAGEM':
        return Icons.image;
      case 'VIDEO':
        return Icons.play_circle_fill;
      case 'ENQUETE':
        return Icons.poll;
      case 'DICA':
        return Icons.lightbulb;
      default:
        return Icons.article;
    }
  }

  Color _feedBadgeColor(String? tipo, Color primary) {
    switch (tipo?.toUpperCase()) {
      case 'DICA':
        return EagleTokens.warn;
      case 'IMAGEM':
        return EagleTokens.good;
      case 'ENQUETE':
        return EagleTokens.purple;
      default:
        return primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final primaryDeep = BrandPalette.deep(primary);
    return fxScreenA11yScope(
      label: 'Feed',
      child: FxShellScaffold(
        useMesh: true,
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primary, primaryDeep]),
            borderRadius: BorderRadius.circular(44),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _abrirFormulario,
            tooltip: 'Nova Publicação',
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, color: EagleTokens.darkInk),
          ),
        ),
        body: SafeArea(
          child:
              _loading
                  ? const Padding(
                    padding: EdgeInsets.all(TokensStrip.s4),
                    child: SkeletonList(count: 4),
                  )
                  : _erro != null
                  ? FxErrorState(
                    chromeOnDark: isDark,
                    primary: primary,
                    message: _erro!,
                    onRetry: _load,
                  )
                  : _posts.isEmpty
                  ? FxEmptyState(
                    icon: 'rss',
                    title: 'Nenhuma publicacao ainda',
                    subtitle:
                        'Compartilhe novidades, videos e conquistas com seus alunos.',
                    action: FxEmptyAction(
                      label: 'Criar publicacao',
                      onTap: _abrirFormulario,
                    ),
                  )
                  : RefreshIndicator(
                    color: primary,
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        TokensStrip.s4,
                        10,
                        16,
                        110,
                      ),
                      itemCount: _posts.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(4, 0, 4, 18),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Feed',
                                    style: TextStyle(
                                      color: chrome.ink,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: _abrirFormulario,
                                  borderRadius: BorderRadius.circular(44),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [primary, primaryDeep],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: primary.withValues(
                                            alpha: 0.38,
                                          ),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.add_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        final p = _posts[i - 1];
                        final mUrl = p.midiaUrl ?? p.imagemUrl;
                        final badgeColor = _feedBadgeColor(p.tipoPost, primary);
                        final curtidas =
                            _curtidasLocais[p.id] ?? p.totalCurtidas;
                        final comentarios =
                            _comentariosLocais[p.id] ?? p.totalComentarios;

                        return FxStaggerItem(
                          index: i,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: fxListCardDecoration(
                              context,
                              accent: p.fixado ? primary : null,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                TokensStrip.s4,
                                14,
                                16,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _PostAuthorHeader(post: p, primary: primary),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      if (p.fixado) ...[
                                        Icon(
                                          Icons.push_pin,
                                          color: primary,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Icon(
                                        _getIconForTipo(p.tipoPost),
                                        size: 20,
                                        color: badgeColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          p.titulo,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        tooltip: 'Ações',
                                        onSelected: (val) {
                                          if (val == 'fixar') {
                                            _toggleFixar(p.id);
                                          }
                                          if (val == 'excluir') {
                                            _confirmarExclusao(p.id);
                                          }
                                        },
                                        itemBuilder:
                                            (ctx) => [
                                              PopupMenuItem(
                                                value: 'fixar',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      p.fixado
                                                          ? Icons
                                                              .push_pin_outlined
                                                          : Icons.push_pin,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      p.fixado
                                                          ? 'Desafixar'
                                                          : 'Fixar no topo',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'excluir',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.delete_outline,
                                                      color: EagleTokens.bad,
                                                      size: 20,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Excluir',
                                                      style: TextStyle(
                                                        color: EagleTokens.bad,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  _TypeBadge(
                                    tipo: p.tipoPost,
                                    color: badgeColor,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    p.conteudo,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  if (mUrl != null && mUrl.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    p.tipoPost == 'VIDEO'
                                        ? _VideoAttachmentTile(primary: primary)
                                        : ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            mUrl,
                                            fit: BoxFit.cover,
                                            height: 130,
                                            width: double.infinity,
                                            errorBuilder:
                                                (_, __, ___) =>
                                                    _ImagePlaceholder(
                                                      primary: primary,
                                                    ),
                                          ),
                                        ),
                                  ] else if (p.tipoPost == 'IMAGEM') ...[
                                    const SizedBox(height: 12),
                                    _ImagePlaceholder(primary: primary),
                                  ],
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _curtir(p.id),
                                        icon: const Icon(
                                          Icons.thumb_up_alt_outlined,
                                          size: 18,
                                        ),
                                        label: Text('$curtidas Curtir'),
                                      ),
                                      TextButton.icon(
                                        onPressed:
                                            () => _abrirComentarios(p.id),
                                        icon: const Icon(
                                          Icons.comment_outlined,
                                          size: 18,
                                        ),
                                        label: Text('$comentarios Comentar'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
        ),
      ),
    );
  }

  void _confirmarExclusao(int id) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Excluir publicação?'),
            content: const Text('Esta ação não pode ser desfeita.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _deletar(id);
                },
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: EagleTokens.bad),
                ),
              ),
            ],
          ),
    );
  }
}
