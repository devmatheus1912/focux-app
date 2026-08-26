part of 'editar_perfil_screen.dart';

class _PerfilPhotoEditor extends StatelessWidget {
  final String? logoUrl;
  final String nome;
  final bool uploading;
  final bool isDark;
  final Color primary;
  final VoidCallback? onTap;

  const _PerfilPhotoEditor({
    required this.logoUrl,
    required this.nome,
    required this.uploading,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        nome.trim().isNotEmpty ? nome.trim()[0].toUpperCase() : '?';
    final radius = FxSettingsLayout.avatarSize / 2;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final surface = isDark ? EagleTokens.darkBg : TokensStrip.pageBg;

    return Semantics(
      button: true,
      enabled: !uploading && onTap != null,
      label:
          uploading
              ? 'Enviando foto do perfil'
              : 'Foto do perfil. Toque para trocar a foto',
      child: Center(
        child: SizedBox(
          width: FxSettingsLayout.avatarSize + 12,
          height: FxSettingsLayout.avatarSize + 12,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Center(
                child: CircleAvatar(
                  radius: radius,
                  backgroundColor: primary.withValues(alpha: 0.12),
                  backgroundImage:
                      logoUrl != null && logoUrl!.isNotEmpty
                          ? NetworkImage(logoUrl!)
                          : null,
                  child:
                      logoUrl == null || logoUrl!.isEmpty
                          ? Text(
                            initial,
                            style: FxSettingsLayout.avatarInitials(
                              color: primary,
                            ).copyWith(fontSize: 28),
                          )
                          : null,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: uploading ? null : onTap,
                  customBorder: const CircleBorder(),
                  child: Ink(
                    width: FxSettingsLayout.editBadge,
                    height: FxSettingsLayout.editBadge,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: surface, width: 2),
                    ),
                    child:
                        uploading
                            ? Padding(
                              padding: const EdgeInsets.all(6),
                              child: FxLoading(
                                strokeWidth: 2,
                                color: onPrimary,
                              ),
                            )
                            : Icon(
                              Icons.camera_alt_rounded,
                              size: 14,
                              color: onPrimary,
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
