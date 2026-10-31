part of 'perfil_screen.dart';

class _Avatar extends StatelessWidget {
  final String nome;
  final String? logoUrl;
  final Color primaryColor;
  final int profileScore;
  final VoidCallback onTap;
  final bool loading;
  final String semanticsLabel;

  const _Avatar({
    required this.nome,
    required this.logoUrl,
    required this.primaryColor,
    required this.profileScore,
    required this.onTap,
    required this.loading,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final sobre = fxPaletaSobreMarca(context, accent: primaryColor);
    return Semantics(
      button: true,
      label: '$semanticsLabel. Perfil $profileScore por cento completo.',
      enabled: !loading,
      child: InkWell(
        onTap: loading ? null : onTap,
        customBorder: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: sobre.ink, width: 2),
              ),
              child: AlunoAvatar(
                name: nome,
                photoUrl: logoUrl,
                variant: AlunoAvatarVariant.profile,
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: FxSettingsLayout.editBadge,
                height: FxSettingsLayout.editBadge,
                decoration: BoxDecoration(
                  color: sobre.ink,
                  shape: BoxShape.circle,
                ),
                child:
                    loading
                        ? Padding(
                          padding: const EdgeInsets.all(6),
                          child: FxLoading(
                            strokeWidth: 2,
                            color: primaryColor,
                          ),
                        )
                        : Icon(Icons.edit, size: 14, color: primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
