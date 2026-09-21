part of 'migracao_magica_screen.dart';

class _MigracaoImportacaoResumoBody extends StatelessWidget {
  const _MigracaoImportacaoResumoBody({
    required this.data,
    this.personalSlug,
  });

  final MigracaoImportacaoResumo data;
  final String? personalSlug;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final brand = Theme.of(context).colorScheme.primary;
    final comAcesso = data.importadosComAcesso;

    Widget stat(String label, int value, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(TokensStrip.rSm),
          ),
          child: Column(
            children: [
              Text('$value', style: FocuxTypography.headline(color: color)),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: FocuxHubTypography.bodyMuted(color: mute, height: 1.3),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            stat('Importados', data.importados, brand),
            const SizedBox(width: 8),
            stat('Duplicados', data.duplicados, EagleTokens.warn),
            const SizedBox(width: 8),
            stat('Erros', data.erros, EagleTokens.bad),
          ],
        ),
        if (comAcesso.isNotEmpty) ...[
          SizedBox(height: TokensStrip.s4),
          Text(
            'Envie o acesso',
            style: FocuxHubTypography.sectionTitle(context, color: ink),
          ),
          const SizedBox(height: 4),
          Text(
            'Um aluno por vez. Eles trocam a senha no primeiro login.',
            style: FocuxHubTypography.bodyMuted(color: mute),
          ),
          SizedBox(height: TokensStrip.s3),
          for (final item in comAcesso)
            _MigracaoConviteTile(
              item: item,
              personalSlug: personalSlug,
              isDark: isDark,
              ink: ink,
              mute: mute,
              brand: brand,
            ),
        ] else if (data.detalhes.isNotEmpty) ...[
          SizedBox(height: TokensStrip.s4),
          for (final item in data.detalhes)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: switch (item.status) {
                        'IMPORTADO' => brand,
                        'DUPLICADO' => EagleTokens.warn,
                        _ => EagleTokens.bad,
                      },
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nome,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: ink,
                            fontSize: 13,
                          ),
                        ),
                        if (item.motivo.isNotEmpty)
                          Text(
                            item.motivo,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: mute,
                              height: 1.35,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _MigracaoConviteTile extends StatelessWidget {
  const _MigracaoConviteTile({
    required this.item,
    required this.personalSlug,
    required this.isDark,
    required this.ink,
    required this.mute,
    required this.brand,
  });

  final MigracaoImportacaoDetalhe item;
  final String? personalSlug;
  final bool isDark;
  final Color ink;
  final Color mute;
  final Color brand;

  String get _convite => alunoInviteMessage(
    nome: item.nome,
    email: item.email ?? '',
    senhaProvisoria: item.senhaProvisoria ?? '',
    personalSlug: personalSlug,
  );

  Future<void> _copiar(BuildContext context) async {
    await copySensitiveToClipboard(_convite);
    HapticFeedback.mediumImpact();
    if (context.mounted) {
      FeedbackHelper.showSuccess(context, 'Convite copiado');
    }
  }

  Future<void> _whatsapp(BuildContext context) async {
    final digits = (item.telefone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      await _copiar(context);
      return;
    }
    final uri = Uri.parse(
      'https://wa.me/$digits?text=${Uri.encodeComponent(_convite)}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      FeedbackHelper.showError(context, 'Não foi possível abrir o WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasWhatsapp =
        (item.telefone ?? '').replaceAll(RegExp(r'\D'), '').isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s3),
      child: Container(
        padding: const EdgeInsets.all(TokensStrip.s3),
        decoration: fxListCardDecoration(context, accent: brand),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              item.nome,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: ink,
                fontSize: 14,
              ),
            ),
            if ((item.email ?? '').isNotEmpty)
              Text(
                item.email!,
                style: TextStyle(fontSize: 12, color: mute, height: 1.35),
              ),
            const SizedBox(height: TokensStrip.s2),
            Row(
              children: [
                Expanded(
                  child: FxLiquidSecondaryButton(
                    label: migracaoCopiarConviteLabel(),
                    onPressed: () => _copiar(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FxLiquidPrimaryButton(
                    label:
                        hasWhatsapp
                            ? migracaoWhatsAppLabel()
                            : migracaoCopiarConviteLabel(),
                    onPressed: () => _whatsapp(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
