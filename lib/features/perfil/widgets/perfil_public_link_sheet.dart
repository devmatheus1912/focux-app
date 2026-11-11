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
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../data/perfil_repository.dart';
import '../../../core/theme/fx_icons.dart';

/// Texto pronto para o aluno: código, link e o que fazer.
String perfilCodigoMensagem(S s, {required String codigo, required String link}) =>
    s.perfilCodigoMensagem(codigo, link);

/// Código do personal: o que o aluno digita para entrar. Vale em todo plano.
///
/// [origemConvites]: aberta de Convidar aluno; esconde "Convidar aluno novo"
/// (seria abrir a mesma tela por cima).
Future<void> showPerfilCodigoSheet(
  BuildContext context, {
  required PerfilPersonal perfil,
  bool origemConvites = false,
}) async {
  final s = S.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primary = Theme.of(context).colorScheme.primary;
  await showFxHomeSheet<void>(
    context,
    builder:
        (ctx) => FxHomeSheetScaffold(
          isDark: isDark,
          leading: Icon(FxIcons.chave, color: primary, size: 22),
          title: s.perfilCodigoTitulo,
          subtitle: s.perfilCodigoSubtitulo,
          child: _PerfilCodigoBody(
            perfil: perfil,
            parent: context,
            origemConvites: origemConvites,
          ),
        ),
  );
}

class _PerfilCodigoBody extends StatelessWidget {
  const _PerfilCodigoBody({
    required this.perfil,
    required this.parent,
    this.origemConvites = false,
  });

  final PerfilPersonal perfil;
  final BuildContext parent;
  final bool origemConvites;

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
        const SizedBox(height: TokensStrip.s3),
        // Ações menores em linhas, embaixo dos dois botões principais.
        FxSettingsGroup(
          children: [
            FxSettingsTile(
              icon: FxIcons.link,
              label: s.perfilCodigoCopiarLink,
              value: '',
              showDivider: !origemConvites,
              onTap: () => _copiar(context, link, s.perfilCodigoLinkCopiado),
            ),
            if (!origemConvites)
              FxSettingsTile(
                icon: FxIcons.adicionarPessoa,
                label: s.perfilCodigoConvidar,
                value: '',
                showDivider: false,
                onTap: () {
                  Navigator.of(context).pop();
                  parent.push('/convites');
                },
              ),
          ],
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
