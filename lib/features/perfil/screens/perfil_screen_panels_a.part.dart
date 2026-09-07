part of 'perfil_screen.dart';

class _PerfilVitrineTiles extends StatelessWidget {
  const _PerfilVitrineTiles({
    required this.slug,
    required this.mute,
    required this.line,
    required this.onOpenEditor,
  });

  final String? slug;
  final Color mute;
  final Color line;
  final VoidCallback onOpenEditor;

  @override
  Widget build(BuildContext context) {
    final normalizedSlug = slug?.trim();
    final hasSlug = normalizedSlug != null && normalizedSlug.isNotEmpty;
    final copyUrl = hasSlug ? Env.landingPageUrl(normalizedSlug) : '';

    return Column(
      children: [
        FxSettingsTile(
          icon: Icons.palette_outlined,
          label: 'Marca',
          value: '',
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
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Wrap(
              spacing: TokensStrip.s2,
              children: [
                TextButton(
                  onPressed: () {
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
                  child: const Text('Copiar link'),
                ),
                TextButton(
                  onPressed: () {
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
                  child: const Text('Compartilhar'),
                ),
              ],
            ),
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
