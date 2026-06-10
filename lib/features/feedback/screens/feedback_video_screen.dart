import 'package:flutter/material.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/fx_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/feedback_video_repository.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import '../../alunos/widgets/aluno360_action_empty_panel.dart';

class FeedbackVideoScreen extends ConsumerStatefulWidget {
  final int? alunoId;
  final String? alunoNome;

  const FeedbackVideoScreen({super.key, this.alunoId, this.alunoNome});

  @override
  ConsumerState<FeedbackVideoScreen> createState() =>
      _FeedbackVideoScreenState();
}

class _FeedbackVideoScreenState extends ConsumerState<FeedbackVideoScreen> {
  List<FeedbackVideo> _feedbacks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = FeedbackVideoRepository(ref.read(apiClientProvider));
      final r =
          widget.alunoId != null
              ? await repo.listarPorAluno(widget.alunoId!)
              : await repo.listar();
      if (mounted) {
        setState(() {
          _feedbacks = r;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _abrirVideo(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        FeedbackHelper.showSnackBar(
          context,
          const SnackBar(content: Text('Não foi possível abrir a URL')),
        );
      }
    }
  }

  Future<void> _deletar(int id) async {
    try {
      await FeedbackVideoRepository(ref.read(apiClientProvider)).deletar(id);
      _feedbacks.removeWhere((f) => f.id == id);
      setState(() {});
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showSnackBar(
          context,
          SnackBar(content: Text(friendlyError(e))),
        );
      }
    }
  }

  Future<void> _novoFeedback() async {
    await showDialog(
      context: context,
      builder:
          (ctx) => _NovoFeedbackDialog(
            alunoIdPreenchido: widget.alunoId,
            alunoNome: widget.alunoNome,
            onSalvo: () {
              Navigator.pop(ctx);
              _load();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryDeep = BrandPalette.deep(primary);
    return FxShellScaffold(
      useMesh: true,
      extendBody: true,
      appBar: FxShellAppBar(
        title:
            widget.alunoNome != null
                ? 'Feedbacks — ${widget.alunoNome}'
                : 'Feedbacks de Vídeo',
        subtitle: 'Análises técnicas de execução',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar feedbacks',
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [primary, primaryDeep]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _novoFeedback,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body:
          _loading
              ? Center(child: FxLoading(color: primary))
              : _feedbacks.isEmpty
              ? satelliteEmptyBody(
                child: Aluno360ActionEmptyPanel(
                  key: const ValueKey('feedback_video_empty'),
                  icon: Icons.video_camera_back_outlined,
                  title: 'Nenhum feedback de vídeo',
                  subtitle:
                      widget.alunoNome != null
                          ? 'Peça a ${satelliteFirstName(widget.alunoNome)} um vídeo de execução ou registre o primeiro feedback técnico.'
                          : 'Registre o primeiro feedback técnico com URL do vídeo e comentário.',
                  primaryLabel: 'Novo feedback',
                  primaryIcon: Icons.add_rounded,
                  onPrimary: _novoFeedback,
                  secondaryActions:
                      widget.alunoId != null
                          ? [
                            Aluno360SecondaryAction(
                              label: 'Voltar ao Aluno 360',
                              icon: Icons.arrow_back_rounded,
                              onTap:
                                  () => Navigator.maybePop(context),
                            ),
                          ]
                          : const [],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(TokensStrip.s4),
                itemCount: _feedbacks.length,
                itemBuilder: (_, i) {
                  final f = _feedbacks[i];
                  return FxSatelliteListTile(
                    margin: const EdgeInsets.only(bottom: 12),
                    accent: primary,
                    titleCase: false,
                    title: 'Exercício #${f.exercicioId}',
                    leading: Icon(
                      Icons.video_library_rounded,
                      size: 32,
                      color: primary,
                    ),
                    isThreeLine: true,
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Comentário: ${f.comentario}'),
                        if (f.aiScore != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Score IA: ${f.aiScore}/100 · ${f.statusAnalise ?? ''}',
                          ),
                        ],
                        if (f.aiAnalise != null && f.aiAnalise!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            f.aiAnalise!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text('Data: ${fxDateShort(f.criadoEm)}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.open_in_new_rounded),
                          tooltip: 'Assistir vídeo',
                          onPressed: () => _abrirVideo(f.videoUrl),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: EagleTokens.bad,
                          ),
                          onPressed: () => _deletar(f.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}

class _NovoFeedbackDialog extends ConsumerStatefulWidget {
  final int? alunoIdPreenchido;
  final String? alunoNome;
  final VoidCallback onSalvo;

  const _NovoFeedbackDialog({
    this.alunoIdPreenchido,
    this.alunoNome,
    required this.onSalvo,
  });

  @override
  ConsumerState<_NovoFeedbackDialog> createState() =>
      _NovoFeedbackDialogState();
}

class _NovoFeedbackDialogState extends ConsumerState<_NovoFeedbackDialog> {
  late TextEditingController _alunoIdCtrl;
  final _exercicioIdCtrl = TextEditingController();
  final _videoUrlCtrl = TextEditingController();
  final _comentarioCtrl = TextEditingController();
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _alunoIdCtrl = TextEditingController(
      text: widget.alunoIdPreenchido?.toString() ?? '',
    );
  }

  Future<void> _salvar() async {
    final alunoId =
        widget.alunoIdPreenchido ?? int.tryParse(_alunoIdCtrl.text);
    final exercicioId = int.tryParse(_exercicioIdCtrl.text);
    final video = _videoUrlCtrl.text.trim();
    final com = _comentarioCtrl.text.trim();

    if (alunoId == null ||
        exercicioId == null ||
        video.isEmpty ||
        com.isEmpty) {
      FeedbackHelper.showSnackBar(
        context,
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      await FeedbackVideoRepository(ref.read(apiClientProvider)).registrar(
        alunoId: alunoId,
        exercicioId: exercicioId,
        videoUrl: video,
        comentario: com,
      );
      widget.onSalvo();
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
    if (mounted) setState(() => _salvando = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Feedback de Vídeo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.alunoIdPreenchido != null &&
                (widget.alunoNome ?? '').trim().isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text(
                    'Para ${satelliteFirstName(widget.alunoNome)}',
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ] else ...[
              TextField(
                controller: _alunoIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Aluno (ID interno)',
                  hintText: 'Somente se não veio do perfil',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _exercicioIdCtrl,
              decoration: const InputDecoration(
                labelText: 'Exercício',
                hintText: 'ID do exercício no app',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _videoUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL do Vídeo (Cloudinary, YouTube, etc)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _comentarioCtrl,
              decoration: const InputDecoration(
                labelText: 'Comentário Técnico',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FxLiquidPrimaryButton(
          label: 'Salvar',
          expand: false,
          loading: _salvando,
          onPressed: _salvando ? null : _salvar,
        ),
      ],
    );
  }
}
