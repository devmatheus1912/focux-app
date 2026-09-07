import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../data/feedback_video_repository.dart';

class FeedbackAlunoFormResult {
  final int exercicioId;
  final String videoUrl;
  final String? comentario;

  const FeedbackAlunoFormResult({
    required this.exercicioId,
    required this.videoUrl,
    this.comentario,
  });
}

class FeedbackAlunoEnviarSheet extends StatefulWidget {
  const FeedbackAlunoEnviarSheet({super.key, required this.exercicios});

  final List<ExercicioOpcao> exercicios;

  @override
  State<FeedbackAlunoEnviarSheet> createState() =>
      _FeedbackAlunoEnviarSheetState();
}

class _FeedbackAlunoEnviarSheetState extends State<FeedbackAlunoEnviarSheet> {
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
      FeedbackAlunoFormResult(
        exercicioId: _exercicioId!,
        videoUrl: url,
        comentario:
            _comentario.text.trim().isEmpty ? null : _comentario.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight:
          MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            FxHomeSheetHandle(isDark: isDark),
            SizedBox(height: TokensStrip.s4),
            FxHomeSheetHeader(
              isDark: isDark,
              title: 'Enviar vídeo para análise',
              subtitle:
                  'A IA da Focux retorna pontos positivos, correções e score em segundos.',
              leading: Icon(Icons.videocam_outlined, color: primary, size: 18),
            ),
            SizedBox(height: TokensStrip.s3),
            DropdownButtonFormField<int>(
              initialValue: _exercicioId,
              isExpanded: true,
              decoration: FxInputDeco.build(context, 'Exercício *'),
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
              decoration: FxInputDeco.build(
                context,
                'URL do vídeo *',
                hint: 'https://youtube.com/...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comentario,
              maxLines: 2,
              decoration: FxInputDeco.build(
                context,
                'O que você quer que a IA observe? (opcional)',
                hint: 'Ex: amplitude do agachamento, joelho passando do pé',
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
