part of 'migracao_magica_screen.dart';

class _MigracaoImportacaoResumoBody extends StatelessWidget {
  const _MigracaoImportacaoResumoBody({
    required this.data,
    required this.status,
    required this.onStatus,
  });

  final MigracaoImportacaoResumo data;

  /// alunoId → enviado/copiado nesta tela.
  final Map<int, MigracaoAcessoStatus> status;
  final void Function(int alunoId, MigracaoAcessoStatus status) onStatus;

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
            S.of(context).migracaoAcessoValidade,
            style: FocuxHubTypography.bodyMuted(color: mute),
          ),
          SizedBox(height: TokensStrip.s3),
          for (final item in comAcesso)
            _MigracaoConviteTile(
              item: item,
              status: status[item.alunoId],
              onStatus: (s) => onStatus(item.alunoId!, s),
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

enum MigracaoAcessoStatus { enviado, copiado }

class _MigracaoConviteTile extends StatelessWidget {
  const _MigracaoConviteTile({
    required this.item,
    required this.status,
    required this.onStatus,
    required this.ink,
    required this.mute,
    required this.brand,
  });

  final MigracaoImportacaoDetalhe item;
  final MigracaoAcessoStatus? status;
  final ValueChanged<MigracaoAcessoStatus> onStatus;
  final Color ink;
  final Color mute;
  final Color brand;

  String _convite(S s) =>
      alunoAtivacaoMessage(s, nome: item.nome, link: item.linkAtivacao ?? '');

  /// E-mail gerado na importação não é do aluno: não mostra.
  String? get _emailVisivel {
    final email = item.email?.trim();
    if (email == null || email.isEmpty || email.endsWith('@focux.importado')) {
      return null;
    }
    return email;
  }

  Future<void> _copiar(BuildContext context, {String? aviso}) async {
    final s = S.of(context);
    await copySensitiveToClipboard(_convite(s));
    HapticFeedback.mediumImpact();
    onStatus(MigracaoAcessoStatus.copiado);
    if (context.mounted) {
      FeedbackHelper.showSuccess(context, aviso ?? s.alunoLinkCopiado);
    }
  }

  Future<void> _whatsapp(BuildContext context, Uri uri) async {
    final s = S.of(context);
    HapticFeedback.mediumImpact();
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (ok) {
      onStatus(MigracaoAcessoStatus.enviado);
    } else {
      await _copiar(context, aviso: s.alunoLinkWhatsAppFalhou);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final whatsAppUri = BrPhone.whatsAppUri(item.telefone, text: _convite(s));
    final email = _emailVisivel;
    final feito = status != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s3),
      child: Container(
        padding: const EdgeInsets.all(TokensStrip.s3),
        decoration: fxListCardDecoration(
          context,
          accent: feito ? EagleTokens.good : brand,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.nome,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: ink,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (feito)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: EagleTokens.good,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status == MigracaoAcessoStatus.enviado
                            ? s.migracaoAcessoEnviado
                            : s.migracaoAcessoCopiado,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: EagleTokens.good,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (email != null)
              Text(
                email,
                style: TextStyle(fontSize: 12, color: mute, height: 1.35),
              ),
            const SizedBox(height: TokensStrip.s2),
            if (whatsAppUri != null) ...[
              FxLiquidPrimaryButton(
                label: s.alunoLinkEnviarWhatsApp,
                onPressed: () => _whatsapp(context, whatsAppUri),
              ),
              TextButton(
                onPressed: () => _copiar(context),
                child: Text(s.alunoLinkCopiar),
              ),
            ] else
              FxLiquidPrimaryButton(
                label: s.alunoLinkCopiar,
                onPressed: () => _copiar(context),
              ),
          ],
        ),
      ),
    );
  }
}
