import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_barra_progresso.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
import '../data/exercicio_repository.dart';
import '../providers/exercicios_provider.dart';
import '../utils/exercise_video_upload_spec.dart';
import 'exercise_video_picker.dart';

/// Escolhe e sobe o vídeo de um exercício que já existe (detalhe e lista).
/// Uma folha acompanha tudo: "Preparando vídeo…" enquanto o sistema entrega
/// o arquivo, "Enviando vídeo 42%" e "Processando vídeo…". Devolve o
/// exercício atualizado, ou nulo se desistiu ou o vídeo foi recusado. Erro de
/// envio sobe para quem chamou.
Future<Exercicio?> escolherEEnviarVideoDoExercicio(
  BuildContext context,
  WidgetRef ref,
  int exercicioId,
) async {
  final envio = _EnvioVideo();
  var aberta = false;
  void abrirFolha() {
    if (aberta || !context.mounted) return;
    aberta = true;
    showFxHomeSheet<void>(
      context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _EnvioVideoFolha(envio: envio),
    );
  }

  final escolher = ref.read(escolherVideoDoExercicioProvider);
  final repo = ref.read(exercicioRepositoryProvider);
  try {
    final video = await escolher(context, aoPreparar: abrirFolha);
    if (video == null) return null;
    abrirFolha();
    envio.progresso.value = 0;
    return await repo.uploadVideoExercicio(
      exercicioId,
      video.path,
      onProgresso: (p) => envio.progresso.value = p,
    );
  } finally {
    envio.fechar.value = true;
  }
}

class _EnvioVideo {
  /// Nulo enquanto prepara; 0 a 1 enquanto sobe; 1 = servidor convertendo.
  final progresso = ValueNotifier<double?>(null);
  final fechar = ValueNotifier<bool>(false);
}

class _EnvioVideoFolha extends StatefulWidget {
  const _EnvioVideoFolha({required this.envio});

  final _EnvioVideo envio;

  @override
  State<_EnvioVideoFolha> createState() => _EnvioVideoFolhaState();
}

class _EnvioVideoFolhaState extends State<_EnvioVideoFolha> {
  @override
  void initState() {
    super.initState();
    widget.envio.fechar.addListener(_talvezFechar);
    WidgetsBinding.instance.addPostFrameCallback((_) => _talvezFechar());
  }

  @override
  void dispose() {
    widget.envio.fechar.removeListener(_talvezFechar);
    super.dispose();
  }

  void _talvezFechar() {
    if (!widget.envio.fechar.value || !mounted) return;
    widget.envio.fechar.removeListener(_talvezFechar);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return PopScope(
      canPop: false,
      child: FxSheetFrame(
        title: exerciseVideoSourceSheetTitle(),
        leading: Icon(FxIcons.video, size: 20, color: primary),
        child: ValueListenableBuilder<double?>(
          valueListenable: widget.envio.progresso,
          builder: (context, p, _) {
            final preparando = p == null;
            final subindo = p != null && p < 1;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (!subindo) ...[
                      FxLoading(size: 18, strokeWidth: 2, color: primary),
                      const SizedBox(width: TokensStrip.s3),
                    ],
                    Expanded(
                      child: Text(
                        preparando
                            ? exerciseVideoPreparando()
                            : exerciseVideoEnvioRotulo(p),
                        style: FocuxHubTypography.body(color: chrome.ink),
                      ),
                    ),
                  ],
                ),
                if (subindo) ...[
                  const SizedBox(height: TokensStrip.s3),
                  FxBarraProgresso(fracao: p, cor: primary),
                ],
                if (preparando) ...[
                  const SizedBox(height: TokensStrip.s2),
                  Text(
                    exerciseVideoPreparandoApoio(),
                    style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                  ),
                ],
                const SizedBox(height: TokensStrip.s4),
              ],
            );
          },
        ),
      ),
    );
  }
}
