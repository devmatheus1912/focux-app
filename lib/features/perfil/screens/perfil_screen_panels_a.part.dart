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
    final linkValue =
        hasSlug
            ? (normalizedSlug.length > 22
                ? '${normalizedSlug.substring(0, 20)}…'
                : normalizedSlug)
            : '';

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
          FxSettingsTile(
            icon: Icons.link_outlined,
            label: 'Link público',
            value: linkValue,
            mute: mute,
            line: line,
            onTap: onOpenEditor,
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
