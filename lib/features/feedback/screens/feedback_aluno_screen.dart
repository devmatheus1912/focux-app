import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/brand/focux_microcopy.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/feedback_video_repository.dart';

class FeedbackAlunoScreen extends ConsumerStatefulWidget {
  const FeedbackAlunoScreen({super.key});

  @override
  ConsumerState<FeedbackAlunoScreen> createState() =>
      _FeedbackAlunoScreenState();
}

class _FeedbackAlunoScreenState extends ConsumerState<FeedbackAlunoScreen> {
  List<FeedbackVideo> _items = [];
  List<ExercicioOpcao> _exercicios = [];
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
      final repo = FeedbackVideoRepository(ref.read(apiClientProvider));
      final items = await repo.meus();
      List<ExercicioOpcao> exs = [];
      try {
        exs = await repo.exerciciosDisponiveis();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _items = items;
          _exercicios = exs;
          _loading = false;
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

  Future<void> _enviar() async {
    if (_exercicios.isEmpty) {
      FeedbackHelper.showError(
        context,
        'Você precisa de um treino atribuído pelo personal antes de enviar form-check.',
      );
      return;
    }

    final result = await showModalBottomSheet<_FormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EnviarFormSheet(exercicios: _exercicios),
    );
    if (result == null) return;

    try {
      await FeedbackVideoRepository(ref.read(apiClientProvider)).enviarMeu(
        videoUrl: result.videoUrl,
        exercicioId: result.exercicioId,
        comentario: result.comentario,
      );
      if (mounted) {
        FeedbackHelper.showSuccess(
          context,
          'Vídeo enviado! Análise IA em andamento — atualize em alguns segundos.',
        );
        _load();
      }
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Color _scoreColor(int? score) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return EagleTokens.scoreColor(score, isDark: isDark);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.forDark(isDark);

    return fxScreenA11yScope(
      label: 'Form check',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Form check',
          subtitle: 'Análise IA da sua execução',
          onBack: () => context.pop(),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _enviar,
          icon: const Icon(Icons.videocam_outlined),
          label: const Text('Enviar vídeo'),
        ),
        body:
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
                  title: FocuxMicrocopy.naoFoiPossivelCarregar,
                )
                : RefreshIndicator(
                  onRefresh: _load,
                  child:
                      _items.isEmpty
                          ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 48),
                              FxEmptyState(
                                icon: 'spark',
                                title: 'Nenhum vídeo enviado ainda',
                                subtitle:
                                    'Toque em Enviar vídeo para receber análise IA da sua execução.',
                              ),
                            ],
                          )
                          : ListView.separated(
                            padding: const EdgeInsets.all(TokensStrip.s4),
                            itemCount: _items.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final f = _items[i];
                              final exNome =
                                  _exercicios
                                      .where((e) => e.id == f.exercicioId)
                                      .map((e) => e.nome)
                                      .firstOrNull ??
                                  'Exercício #${f.exercicioId}';
                              return Container(
                                decoration: chrome.listCard(primary: primary),
                                child: ExpansionTile(
                                  title: Text(
                                    exNome,
                                    style: TextStyle(
                                      color: chrome.ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${f.statusAnalise ?? 'PENDENTE'} · ${f.criadoEm.toLocal().toString().substring(0, 16)}',
                                    style: TextStyle(color: chrome.mute),
                                  ),
                                  leading:
                                      f.aiScore != null
                                          ? CircleAvatar(
                                            backgroundColor: _scoreColor(
                                              f.aiScore,
                                            ),
                                            foregroundColor: Colors.white,
                                            child: Text('${f.aiScore}'),
                                          )
                                          : CircleAvatar(
                                            backgroundColor: BrandPalette.soft(
                                              primary,
                                              dark: isDark,
                                            ),
                                            child: Icon(
                                              Icons.hourglass_empty,
                                              color: primary,
                                            ),
                                          ),
                                  children: [
                                    if (f.aiAnalise != null &&
                                        f.aiAnalise!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          f.aiAnalise!,
                                          style: TextStyle(
                                            height: 1.4,
                                            color: chrome.ink,
                                          ),
                                        ),
                                      ),
                                    if (f.comentario.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          0,
                                          16,
                                          16,
                                        ),
                                        child: Text(
                                          'Sua nota: ${f.comentario}',
                                          style: TextStyle(color: chrome.mute),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                ),
      ),
    );
  }
}

class _FormResult {
  final int exercicioId;
  final String videoUrl;
  final String? comentario;
  _FormResult({
    required this.exercicioId,
    required this.videoUrl,
    this.comentario,
  });
}

class _EnviarFormSheet extends StatefulWidget {
  final List<ExercicioOpcao> exercicios;
  const _EnviarFormSheet({required this.exercicios});

  @override
  State<_EnviarFormSheet> createState() => _EnviarFormSheetState();
}

class _EnviarFormSheetState extends State<_EnviarFormSheet> {
  int? _exercicioId;
  final _videoUrl = TextEditingController();
  final _comentario = TextEditingController();

  @override
  void initState() {
    super.initState();
    _exercicioId = widget.exercicios.first.id;
  }

  @override
  void dispose() {
    _videoUrl.dispose();
    _comentario.dispose();
    super.dispose();
  }

  void _salvar() {
    final url = _videoUrl.text.trim();
    if (_exercicioId == null) return;
    if (url.isEmpty ||
        !(url.startsWith('http://') || url.startsWith('https://'))) {
      FeedbackHelper.showError(
        context,
        'Cole uma URL válida (https://) do vídeo no YouTube ou Drive.',
      );
      return;
    }
    Navigator.pop(
      context,
      _FormResult(
        exercicioId: _exercicioId!,
        videoUrl: url,
        comentario:
            _comentario.text.trim().isEmpty ? null : _comentario.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Enviar vídeo para análise',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'A IA da Focux retorna pontos positivos, correções e score em segundos.',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              initialValue: _exercicioId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Exercício *'),
              items:
                  widget.exercicios
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e.id, child: Text(e.nome)),
                      )
                      .toList(),
              onChanged: (v) => setState(() => _exercicioId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _videoUrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL do vídeo *',
                hintText: 'https://youtube.com/...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comentario,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'O que você quer que a IA observe? (opcional)',
                hintText: 'Ex: amplitude do agachamento, joelho passando do pé',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.send),
              label: const Text('Enviar para análise'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
