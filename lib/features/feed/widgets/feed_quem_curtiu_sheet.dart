import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_cached_network_image.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../data/feed_repository.dart';
import '../utils/feed_display.dart';

/// "Quem curtiu": o retorno do post para o personal, aluno por aluno.
Future<void> showFeedQuemCurtiuSheet(
  BuildContext context, {
  required int postId,
  required FeedRepository repo,
}) {
  return showFxHomeSheet<void>(
    context,
    builder: (_) => _QuemCurtiuSheet(postId: postId, repo: repo),
  );
}

class _QuemCurtiuSheet extends StatefulWidget {
  const _QuemCurtiuSheet({required this.postId, required this.repo});

  final int postId;
  final FeedRepository repo;

  @override
  State<_QuemCurtiuSheet> createState() => _QuemCurtiuSheetState();
}

class _QuemCurtiuSheetState extends State<_QuemCurtiuSheet> {
  late final Future<FeedQuemCurtiu> _futuro = widget.repo.quemCurtiu(
    widget.postId,
  );

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return FxHomeSheetSurface(
      isDark: chrome.isDark,
      maxHeight:
          MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor,
      child: FutureBuilder<FeedQuemCurtiu>(
        future: _futuro,
        builder: (context, snap) {
          final dados = snap.data;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxHomeSheetHandle(isDark: chrome.isDark),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s3,
                  FxSettingsLayout.pageInset,
                  TokensStrip.s2,
                ),
                child: FxHomeSheetHeader(
                  isDark: chrome.isDark,
                  title: 'Quem curtiu',
                  subtitle:
                      dados == null ? null : feedCurtidasLabel(dados.total),
                  leading: Icon(FxIcons.favorito, color: primary, size: 18),
                ),
              ),
              if (snap.hasError)
                Padding(
                  padding: const EdgeInsets.all(FxSettingsLayout.pageInset),
                  child: Text(
                    friendlyError(snap.error!),
                    style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                  ),
                )
              else if (dados == null)
                const Padding(
                  padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                  child: SkeletonList(count: 3),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      0,
                      FxSettingsLayout.pageInset,
                      TokensStrip.s5,
                    ),
                    children: [
                      for (final a in dados.alunos)
                        _Linha(aluno: a, primary: primary),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.aluno, required this.primary});

  final FeedCurtidor aluno;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final foto = aluno.fotoUrl?.trim();
    final temFoto = foto != null && foto.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TokensStrip.s2),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: primary.withValues(alpha: 0.14),
            backgroundImage:
                temFoto
                    ? fxCachedNetworkImageProvider(foto, maxWidth: 72)
                    : null,
            child:
                temFoto
                    ? null
                    : Text(
                      fxInitials(aluno.nome),
                      style: FocuxHubTypography.rotulo(color: primary),
                    ),
          ),
          const SizedBox(width: TokensStrip.s3),
          Expanded(
            child: Text(
              aluno.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FocuxHubTypography.body(color: chrome.ink),
            ),
          ),
        ],
      ),
    );
  }
}
