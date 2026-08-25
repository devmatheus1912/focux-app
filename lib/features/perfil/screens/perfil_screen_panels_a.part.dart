part of 'perfil_screen.dart';

class _PerfilVitrineTiles extends StatelessWidget {
  const _PerfilVitrineTiles({
    required this.slug,
    required this.score,
    required this.mute,
    required this.line,
    required this.onOpenEditor,
  });

  final String? slug;
  final int score;
  final Color mute;
  final Color line;
  final VoidCallback onOpenEditor;

  @override
  Widget build(BuildContext context) {
    final normalizedSlug = slug?.trim();
    final hasSlug = normalizedSlug != null && normalizedSlug.isNotEmpty;
    final displayLabel =
        hasSlug ? Env.landingPageDisplayLabel(normalizedSlug) : '';
    final copyUrl = hasSlug ? Env.landingPageUrl(normalizedSlug) : '';

    return Column(
      children: [
        FxSettingsTile(
          icon: Icons.palette_outlined,
          label: 'Marca',
          value: '$score%',
          mute: mute,
          line: line,
          onTap: () => context.push('/identidade-visual'),
        ),
        if (!hasSlug)
          FxSettingsTile(
            icon: Icons.add_link_outlined,
            label: 'Criar link público',
            value: '',
            mute: mute,
            line: line,
            showDivider: false,
            onTap: onOpenEditor,
          )
        else ...[
          FxSettingsTile(
            icon: Icons.copy_rounded,
            label: 'Copiar link',
            value: displayLabel,
            mute: mute,
            line: line,
            onTap: () {
              unawaited(
                copyLandingLink(
                  context,
                  url: copyUrl,
                  successMessage:
                      'Link copiado. Cole no Instagram ou WhatsApp.',
                  reserveBottom: 96,
                ),
              );
            },
          ),
          FxSettingsTile(
            icon: Icons.ios_share_outlined,
            label: 'Compartilhar',
            value: '',
            mute: mute,
            line: line,
            onTap: () {
              unawaited(
                AnalyticsService.instance.track(
                  ProductEvents.perfilShareTapped,
                ),
              );
              unawaited(
                copyLandingLink(
                  context,
                  url: copyUrl,
                  successMessage:
                      'Link pronto para compartilhar no Instagram ou WhatsApp.',
                  reserveBottom: 96,
                ),
              );
            },
          ),
          FxSettingsTile(
            icon: Icons.open_in_new_outlined,
            label: 'Ver ao vivo',
            value: '',
            mute: mute,
            line: line,
            onTap: () {
              unawaited(openLandingLink(context, url: copyUrl));
            },
          ),
          FxSettingsTile(
            icon: Icons.tune_outlined,
            label: 'Personalizar',
            value: '',
            mute: mute,
            line: line,
            showDivider: false,
            onTap: onOpenEditor,
          ),
        ],
      ],
    );
  }
}
