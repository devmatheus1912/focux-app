part of 'perfil_screen.dart';

class _Avatar extends StatelessWidget {
  final String nome;
  final String? logoUrl;
  final Color primaryColor;
  final VoidCallback onTap;
  final bool loading;
  final String semanticsLabel;

  const _Avatar({
    required this.nome,
    required this.logoUrl,
    required this.primaryColor,
    required this.onTap,
    required this.loading,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    const size = FxSettingsLayout.avatarSize;
    final inner = size - 4;
    Widget avatarContent() {
      return Text(
        _initials(nome),
        style: FxSettingsLayout.profileName(color: primaryColor),
      );
    }

    return Semantics(
      button: true,
      label: semanticsLabel,
      enabled: !loading,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: loading ? null : onTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: size,
                height: size,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.92),
                  boxShadow: const [
                    BoxShadow(
                      color: EagleTokens.shadowSoft,
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child:
                      logoUrl != null && logoUrl!.isNotEmpty
                          ? ClipOval(
                            child: Image.network(
                              logoUrl!,
                              width: inner,
                              height: inner,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => avatarContent(),
                            ),
                          )
                          : avatarContent(),
                ),
              ),
            ),
          ),
          Positioned(
            right: 1,
            bottom: 1,
            child: InkWell(
              onTap: loading ? null : onTap,
              borderRadius: BorderRadius.circular(26),
              child: Container(
                width: FxSettingsLayout.editBadge,
                height: FxSettingsLayout.editBadge,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child:
                    loading
                        ? Padding(
                          padding: const EdgeInsets.all(6),
                          child: FxLoading(strokeWidth: 2, color: Colors.white),
                        )
                        : const Icon(Icons.edit, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
