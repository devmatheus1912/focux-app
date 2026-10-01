import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/safe_external_launch.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../data/feedback_video_repository.dart';
import '../utils/feedback_video_display.dart';

const _alunoHome = '/dashboard/aluno';

/// Aluno grava a execução, envia e lê a correção do personal.
class AlunoFeedbackVideoScreen extends ConsumerStatefulWidget {
  const AlunoFeedbackVideoScreen({super.key, this.picker});

  final ImagePicker? picker;

  @override
  ConsumerState<AlunoFeedbackVideoScreen> createState() =>
      _AlunoFeedbackVideoScreenState();
}

class _AlunoFeedbackVideoScreenState
    extends ConsumerState<AlunoFeedbackVideoScreen> {
  late final ImagePicker _picker = widget.picker ?? ImagePicker();
  final _feedbacks = <FeedbackVideo>[];
  var _loading = true;
  var _loadingMore = false;
  var _hasNext = false;
  var _page = 0;
  var _enviando = false;
  String? _erro;

  FeedbackVideoRepository get _repo => ref.read(feedbackVideoRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _erro = null;
      });
    } else {
      if (_loadingMore || !_hasNext) return;
      setState(() => _loadingMore = true);
    }
    try {
      final pagina = await _repo.listarMeus(page: reset ? 0 : _page);
      if (!mounted) return;
      setState(() {
        if (reset) _feedbacks.clear();
        _feedbacks.addAll(pagina.content);
        _hasNext = pagina.hasNext;
        _page = (pagina.page ?? 0) + 1;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = friendlyError(e);
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _enviar() async {
    if (_enviando) return;
    HapticFeedback.selectionClick();
    final List<ExercicioOpcao> exercicios;
    try {
      exercicios = await _repo.meusExercicios();
    } catch (e) {
      if (mounted) _mostrarErro(e);
      return;
    }
    if (!mounted) return;
    if (exercicios.isEmpty) {
      FeedbackHelper.showError(
        context,
        'Seu treino ainda não tem exercícios. Fale com seu personal.',
      );
      return;
    }
    final exercicioId = await showFxInsetPickerSheet<int>(
      context,
      title: 'Qual exercício?',
      subtitle: 'Escolha o que você vai gravar.',
      headerIcon: Icons.fitness_center,
      items: [
        for (final e in exercicios)
          FxInsetPickerSheetItem(value: e.id, label: e.nome),
      ],
    );
    if (exercicioId == null || !mounted) return;

    final fonte = await showFxInsetPickerSheet<ImageSource>(
      context,
      title: 'Enviar vídeo',
      subtitle: 'Até 1 minuto. Filme o corpo inteiro de lado.',
      headerIcon: Icons.videocam_outlined,
      items: const [
        FxInsetPickerSheetItem(
          value: ImageSource.camera,
          label: 'Gravar agora',
          icon: Icons.videocam_outlined,
        ),
        FxInsetPickerSheetItem(
          value: ImageSource.gallery,
          label: 'Escolher da galeria',
          icon: Icons.video_library_outlined,
        ),
      ],
    );
    if (fonte == null || !mounted) return;

    XFile? arquivo;
    try {
      arquivo = await _picker.pickVideo(
        source: fonte,
        maxDuration: feedbackVideoMaxDuration,
      );
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(
          context,
          friendlyError(e, fallback: 'Não foi possível abrir o vídeo.'),
        );
      }
      return;
    }
    if (arquivo == null || !mounted) return;
    final tamanhoErro = feedbackVideoTamanhoErro(await arquivo.length());
    if (!mounted) return;
    if (tamanhoErro != null) {
      FeedbackHelper.showError(context, tamanhoErro);
      return;
    }

    final comentarioCtrl = TextEditingController();
    String comentario;
    try {
      final ok = await showFxFormSheet(
        context,
        title: 'Quer avisar algo?',
        subtitle: 'Opcional. Ex.: senti o joelho na descida.',
        icon: Icons.notes_outlined,
        confirmLabel: 'Enviar vídeo',
        child: AlunoInsetFormField(
          controller: comentarioCtrl,
          label: 'Recado para o personal',
          icon: Icons.notes_outlined,
          maxLines: 3,
          showDivider: false,
        ),
      );
      if (!ok || !mounted) return;
      comentario = comentarioCtrl.text.trim();
    } finally {
      comentarioCtrl.dispose();
    }

    setState(() => _enviando = true);
    try {
      final filename = feedbackVideoUploadFilename(
        arquivo.name.isNotEmpty ? arquivo.name : arquivo.path,
      );
      final url = kIsWeb || arquivo.path.isEmpty
          ? await _repo.subirVideo(
              filename: filename,
              bytes: await arquivo.readAsBytes(),
            )
          : await _repo.subirVideo(filename: filename, path: arquivo.path);
      final novo = await _repo.enviarMeu(
        exercicioId: exercicioId,
        videoUrl: url,
        comentario: comentario,
      );
      if (!mounted) return;
      setState(() => _feedbacks.insert(0, novo));
      FeedbackHelper.showSuccess(
        context,
        'Vídeo enviado. Você recebe um aviso quando o personal responder.',
      );
    } catch (e) {
      if (mounted) _mostrarErro(e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _mostrarErro(Object e) {
    FeedbackHelper.showError(
      context,
      isPlanGateError(e)
          ? 'Seu personal ainda não liberou o feedback em vídeo.'
          : friendlyError(e),
    );
  }

  Future<void> _abrirVideo(String url) async {
    final opened = await launchSafeHttpUrl(url);
    if (!opened && mounted) {
      FeedbackHelper.showError(context, 'Não foi possível abrir o vídeo.');
    }
  }

  Future<void> _abrirDetalhe(FeedbackVideo item) {
    return showFxHomeSheet<void>(
      context,
      builder: (ctx) => _FeedbackDetalheSheet(
        item: item,
        onAssistir: () {
          Navigator.of(ctx).pop();
          _abrirVideo(item.videoUrl);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return fxScreenA11yScope(
      label: 'Meus vídeos',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Meus vídeos',
          subtitle: 'Correção do seu personal',
          onBack: () => safePopOrGo(context, _alunoHome),
          actions: [
            FxHelpIconButton(
              tooltip: 'Ajuda — meus vídeos',
              onTap: () => showFxHelpSheet(
                context,
                title: 'Meus vídeos',
                subtitle: feedbackVideoAlunoHelpTip,
              ),
            ),
          ],
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
                      onRetry: () => _load(reset: true),
                      title: 'Não conseguimos carregar seus vídeos',
                    )
                  : FxContentWidthLimiter(child: _buildLista(primary)),
            ),
            if (!_loading && _erro == null)
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
                    key: const ValueKey('aluno-feedback-enviar'),
                    label: 'Enviar vídeo',
                    icon: Icons.videocam_outlined,
                    loading: _enviando,
                    loadingLabel: 'Enviando vídeo…',
                    onPressed: _enviar,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLista(Color primary) {
    if (_feedbacks.isEmpty) {
      return RefreshIndicator(
        color: primary,
        onRefresh: () => _load(reset: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            FxEmptyState(
              key: ValueKey('aluno-feedback-vazio'),
              icon: 'spark',
              title: 'Nenhum vídeo ainda',
              subtitle:
                  'Grave uma série do exercício e seu personal responde com a correção.',
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: primary,
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s3,
          FxSettingsLayout.pageInset,
          TokensStrip.s6,
        ),
        itemCount: _feedbacks.length + (_hasNext ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == _feedbacks.length) {
            return FxSatelliteListTile(
              title: _loadingMore ? 'Carregando…' : 'Carregar mais',
              onTap: _loadingMore ? null : () => _load(reset: false),
            );
          }
          final item = _feedbacks[i];
          return FxSatelliteListTile(
            title: feedbackVideoTitulo(
              exercicioNome: item.exercicioNome,
              comentario: item.comentario,
            ),
            subtitle: Text(
              feedbackVideoAlunoSubtitle(
                criadoEm: item.criadoEm,
                respondido: item.respondido,
              ),
            ),
            trailing: Text(
              feedbackVideoAlunoStatusLabel(respondido: item.respondido),
              style: FocuxHubTypography.bodyMuted(
                color: item.respondido ? primary : fxScreenMute(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            accent: item.respondido ? primary : null,
            onTap: () => _abrirDetalhe(item),
          );
        },
      ),
    );
  }
}

class _FeedbackDetalheSheet extends StatelessWidget {
  const _FeedbackDetalheSheet({required this.item, required this.onAssistir});

  final FeedbackVideo item;
  final VoidCallback onAssistir;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chrome = ShellChrome.forBrightness(context, isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final comentario = item.comentario.trim();
    final resposta = item.respostaPersonal?.trim() ?? '';
    return FxHomeSheetScaffold(
      isDark: isDark,
      leading: Icon(Icons.rate_review_outlined, color: primary, size: 20),
      title: feedbackVideoTitulo(
        exercicioNome: item.exercicioNome,
        comentario: item.comentario,
      ),
      subtitle: feedbackVideoAlunoSubtitle(
        criadoEm: item.criadoEm,
        respondido: item.respondido,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Correção do personal',
            style: FocuxHubTypography.bodyMuted(
              color: chrome.mute,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TokensStrip.s2),
          SelectableText(
            resposta.isEmpty
                ? 'Seu personal ainda não respondeu. Você recebe um aviso quando ele responder.'
                : resposta,
            key: const ValueKey('aluno-feedback-resposta'),
            style: FocuxHubTypography.body(color: chrome.ink),
          ),
          if (comentario.isNotEmpty) ...[
            const SizedBox(height: TokensStrip.s4),
            Text(
              'Seu recado',
              style: FocuxHubTypography.bodyMuted(
                color: chrome.mute,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: TokensStrip.s2),
            Text(comentario, style: FocuxHubTypography.body(color: chrome.ink)),
          ],
          const SizedBox(height: TokensStrip.s5),
          FxLiquidSecondaryButton(
            label: 'Assistir meu vídeo',
            icon: Icons.play_circle_outline_rounded,
            onPressed: onAssistir,
          ),
        ],
      ),
    );
  }
}
