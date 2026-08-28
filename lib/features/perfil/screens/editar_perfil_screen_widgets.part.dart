part of 'editar_perfil_screen.dart';

class _PerfilFormField extends StatelessWidget {
  const _PerfilFormField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.soft,
    this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.showDivider = true,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color soft;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? maxLength;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final line = chrome.line;
    final fieldHint = hint ?? label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: label,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            validator: validator,
            maxLines: maxLines,
            maxLength: maxLength,
            style: FxSettingsLayout.rowLabel(
              color: fxScreenInk(context),
            ),
            decoration: FxInputDeco.insetGrouped(
              context,
              icon: icon,
              hint: fieldHint,
              iconColor: soft,
            ).copyWith(
              counterStyle: FxSettingsLayout.rowValue(color: fxScreenMute(context)),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: FxSettingsLayout.dividerThickness,
            color: line,
          ),
      ],
    );
  }
}

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
