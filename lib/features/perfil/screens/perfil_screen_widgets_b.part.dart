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
    final inner = size - TokensStrip.s1;
    final chrome = ShellChrome.of(context);
    final ring = chrome.cardFill;
    Widget avatarContent() {
      return Text(
        _initials(nome),
        style: FxSettingsLayout.avatarInitials(context, color: primaryColor),
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
                padding: const EdgeInsets.all(TokensStrip.s1 / 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ring,
                  boxShadow: const [
                    BoxShadow(
                      color: EagleTokens.shadowSoft,
                      blurRadius: TokensStrip.blurLight,
                      offset: Offset(0, TokensStrip.s2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: ring,
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
              borderRadius: BorderRadius.circular(FxSettingsLayout.editBadge),
              child: Container(
                width: FxSettingsLayout.editBadge,
                height: FxSettingsLayout.editBadge,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: ring, width: TokensStrip.s1 / 2),
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
