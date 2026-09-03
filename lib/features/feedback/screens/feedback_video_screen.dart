import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../features/alunos/widgets/aluno_inset_form_field.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import '../data/feedback_video_repository.dart';
import '../utils/feedback_video_display.dart';

enum _FeedbackVideoAcao { abrir, deletar }

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
      final repo = FeedbackVideoRepository(ref.read(apiClientProvider));
      final r =
          widget.alunoId != null
              ? await repo.listarPorAluno(widget.alunoId!)
              : await repo.listar();
      if (mounted) {
        setState(() {
          _feedbacks = r;
          _loading = false;
          _fetchedAt = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = friendlyError(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _abrirVideo(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (mounted) {
        FeedbackHelper.showError(context, 'Não foi possível abrir a URL');
      }
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      FeedbackHelper.showError(context, 'Não foi possível abrir a URL');
    }
  }

  Future<void> _deletar(FeedbackVideo item) async {
    final ok = await showFxConfirmSheet(
      context,
      title: 'Remover feedback?',
      subtitle: feedbackVideoLabel(item.comentario),
      message: 'O vídeo some desta lista. Dá para registrar de novo depois.',
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await FeedbackVideoRepository(ref.read(apiClientProvider)).deletar(item.id);
      if (!mounted) return;
      setState(() => _feedbacks.removeWhere((f) => f.id == item.id));
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _abrirAcoes(FeedbackVideo item) async {
    final picked = await showFxInsetPickerSheet<_FeedbackVideoAcao>(
      context,
      title: feedbackVideoLabel(item.comentario),
      items: const [
        FxInsetPickerSheetItem(
          value: _FeedbackVideoAcao.abrir,
          label: 'Assistir vídeo',
        ),
        FxInsetPickerSheetItem(
          value: _FeedbackVideoAcao.deletar,
          label: 'Remover',
        ),
      ],
    );
    if (picked == null || !mounted) return;
    switch (picked) {
      case _FeedbackVideoAcao.abrir:
        await _abrirVideo(item.videoUrl);
      case _FeedbackVideoAcao.deletar:
        await _deletar(item);
    }
  }

  Future<void> _novoFeedback() async {
    HapticFeedback.selectionClick();
    final alunoIdCtrl = TextEditingController(
      text: widget.alunoId?.toString() ?? '',
    );
    final exercicioIdCtrl = TextEditingController();
    final videoUrlCtrl = TextEditingController();
    final comentarioCtrl = TextEditingController();
    var created = false;

    try {
      if (!mounted) return;
      final ok = await showFxFormSheet(
        context,
        title: 'Novo feedback de vídeo',
        subtitle:
            widget.alunoNome != null && widget.alunoNome!.trim().isNotEmpty
                ? 'Para ${satelliteFirstName(widget.alunoNome)}'
                : 'URL, exercício e comentário técnico.',
        icon: Icons.videocam_outlined,
        confirmLabel: 'Salvar',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.alunoId == null)
              AlunoInsetFormField(
                controller: alunoIdCtrl,
                label: 'Aluno (ID interno)',
                icon: Icons.person_outline,
                hint: 'Somente se não veio do perfil',
                keyboardType: TextInputType.number,
              ),
            AlunoInsetFormField(
              controller: exercicioIdCtrl,
              label: 'Exercício',
              icon: Icons.fitness_center_outlined,
              hint: 'ID do exercício no app',
              keyboardType: TextInputType.number,
            ),
            AlunoInsetFormField(
              controller: videoUrlCtrl,
              label: 'URL do vídeo',
              icon: Icons.link_outlined,
              hint: 'Cloudinary, YouTube…',
            ),
            AlunoInsetFormField(
              controller: comentarioCtrl,
              label: 'Comentário técnico',
              icon: Icons.notes_outlined,
              maxLines: 3,
              showDivider: false,
            ),
          ],
        ),
      );
      if (ok != true) return;
      final alunoId = widget.alunoId ?? int.tryParse(alunoIdCtrl.text);
      final exercicioId = int.tryParse(exercicioIdCtrl.text);
      final video = videoUrlCtrl.text.trim();
      final com = comentarioCtrl.text.trim();
      if (alunoId == null ||
          exercicioId == null ||
          video.isEmpty ||
          com.isEmpty) {
        if (mounted) {
          FeedbackHelper.showError(context, 'Preencha todos os campos');
        }
        return;
      }
      await FeedbackVideoRepository(ref.read(apiClientProvider)).registrar(
        alunoId: alunoId,
        exercicioId: exercicioId,
        videoUrl: video,
        comentario: com,
      );
      created = true;
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      alunoIdCtrl.dispose();
      exercicioIdCtrl.dispose();
      videoUrlCtrl.dispose();
      comentarioCtrl.dispose();
    }
    if (created) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    return fxScreenA11yScope(
      label: 'Feedback de vídeo',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title:
              widget.alunoNome != null
                  ? 'Feedbacks — ${widget.alunoNome}'
                  : 'Feedbacks de vídeo',
          subtitle: feedbackVideoHubSubtitle(
            alunoNome: widget.alunoNome,
            freshness: freshnessLabel,
          ),
          actions: [
            ShellHeaderIconButton(
              icon: 'plus',
              tooltip: 'Novo feedback',
              onTap: _novoFeedback,
            ),
          ],
        ),
        body:
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
                  title: 'Não conseguimos carregar os feedbacks',
                )
                : FxContentWidthLimiter(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _load,
      child: _feedbacks.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                8,
                FxSettingsLayout.pageInset,
                32,
              ),
              children: [
                FxEmptyState(
                  key: const ValueKey('feedback_video_empty'),
                  icon: 'spark',
                  title: 'Nenhum feedback de vídeo',
                  subtitle:
                      widget.alunoNome != null
                          ? 'Peça a ${satelliteFirstName(widget.alunoNome)} um vídeo de execução ou registre o primeiro feedback técnico.'
                          : 'Registre o primeiro feedback técnico com URL do vídeo e comentário.',
                  action: FxEmptyAction(
                    label: 'Novo feedback',
                    onTap: _novoFeedback,
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                TokensStrip.s3,
                FxSettingsLayout.pageInset,
                TokensStrip.s6,
              ),
              itemCount: _feedbacks.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: TokensStrip.s3),
                    child: DashboardSectionHeader(title: 'Feedbacks'),
                  );
                }
                final item = _feedbacks[i - 1];
                return FxSatelliteListTile(
                  title: feedbackVideoLabel(item.comentario),
                  subtitle: Text(
                    feedbackVideoSubtitle(
                      criadoEm: item.criadoEm,
                      aiScore: item.aiScore,
                      statusAnalise: item.statusAnalise,
                    ),
                  ),
                  trailing: Text(
                    feedbackVideoValue(item.aiScore),
                    style: FocuxHubTypography.bodyMuted(
                      color: feedbackVideoDanger(item.aiScore)
                          ? EagleTokens.bad
                          : fxScreenMute(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  accent: feedbackVideoDanger(item.aiScore)
                      ? EagleTokens.bad
                      : null,
                  onTap: () => _abrirAcoes(item),
                );
              },
            ),
    );
  }
}
