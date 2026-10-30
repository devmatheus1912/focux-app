import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/app_localizations.dart';
import '../data/perfil_repository.dart';

/// Texto pronto para o aluno: código, link e o que fazer.
String perfilCodigoMensagem(S s, {required String codigo, required String link}) =>
    s.perfilCodigoMensagem(codigo, link);

/// Código do personal: o que o aluno digita para entrar. Vale em todo plano.
Future<void> showPerfilCodigoSheet(
  BuildContext context, {
  required PerfilPersonal perfil,
}) async {
  final s = S.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primary = Theme.of(context).colorScheme.primary;
  await showFxHomeSheet<void>(
    context,
    builder:
        (ctx) => FxHomeSheetScaffold(
          isDark: isDark,
          leading: Icon(Icons.key_outlined, color: primary, size: 22),
          title: s.perfilCodigoTitulo,
          subtitle: s.perfilCodigoSubtitulo,
          child: _PerfilCodigoBody(perfil: perfil, parent: context),
        ),
  );
}

class _PerfilCodigoBody extends StatelessWidget {
  const _PerfilCodigoBody({required this.perfil, required this.parent});

  final PerfilPersonal perfil;
  final BuildContext parent;

  Future<void> _copiar(BuildContext context, String texto, String aviso) async {
    await Clipboard.setData(ClipboardData(text: texto));
    if (!context.mounted) return;
    FeedbackHelper.showSuccess(context, aviso);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final codigo = perfil.slug?.trim() ?? '';
    final link = Env.landingPageUrl(codigo);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: s.perfilCodigoLeitura(codigo),
          excludeSemantics: true,
          child: SelectableText(
            codigo,
            style: FocuxHubTypography.pageTitle(context, color: chrome.ink),
          ),
        ),
        const SizedBox(height: TokensStrip.s3),
        Text(
          s.perfilCodigoPassos,
          style: FocuxHubTypography.bodyMuted(color: chrome.mute),
        ),
        const SizedBox(height: TokensStrip.s4),
        FxLiquidPrimaryButton(
          label: s.perfilCodigoCopiar,
          onPressed: () => _copiar(context, codigo, s.perfilCodigoCopiado),
        ),
        const SizedBox(height: TokensStrip.s2),
        FxTonalButton(
          label: s.perfilCodigoWhatsapp,
          expanded: true,
          onPressed: () async {
            final texto = perfilCodigoMensagem(s, codigo: codigo, link: link);
            final uri = Uri.parse(
              'https://wa.me/?text=${Uri.encodeComponent(texto)}',
            );
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
        ),
        const SizedBox(height: TokensStrip.s2),
        FxTonalButton(
          label: s.perfilCodigoCopiarLink,
          expanded: true,
          onPressed: () => _copiar(context, link, s.perfilCodigoLinkCopiado),
        ),
        const SizedBox(height: TokensStrip.s2),
        FxTonalButton(
          label: s.perfilCodigoConvidar,
          expanded: true,
          onPressed: () {
            Navigator.of(context).pop();
            parent.push('/convites');
          },
        ),
        const SizedBox(height: TokensStrip.s2),
        if (perfil.slugEditable)
          FxTonalButton(
            label: s.perfilCodigoTrocar,
            compact: true,
            onPressed: () {
              Navigator.of(context).pop();
              parent.push('/perfil/link-publico', extra: perfil);
            },
          )
        else
          Text(
            s.perfilCodigoTravado,
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
      ],
    );
  }
}
