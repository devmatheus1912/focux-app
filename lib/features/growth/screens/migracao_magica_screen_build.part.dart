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

  /// "Copiar os N convites" só aparece com 2 ou mais: com 1 seria o mesmo botão do card.
  List<Widget> _grupoDeConvites(List<MigracaoImportacaoDetalhe> itens, Color brand) {
    return [
      if (itens.length >= 2) ...[
        _MigracaoEnviarTodosButton(data: itens),
        const SizedBox(height: TokensStrip.s2),
      ],
      for (final item in itens)
        Builder(
          builder: (context) {
            final dark = Theme.of(context).brightness == Brightness.dark;
            return _MigracaoConviteTile(
              item: item,
              status: status[item.alunoId],
              onStatus: (s) => onStatus(item.alunoId!, s),
              ink: dark ? EagleTokens.darkInk : TokensStrip.textPrimary,
              mute: dark ? EagleTokens.darkInkMute : TokensStrip.textSecondary,
              brand: brand,
            );
          },
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final brand = Theme.of(context).colorScheme.primary;
    final comAcesso = data.importadosComAcesso;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FxMetricStrip(
          metricas: [
            FxMetric(valor: data.importados, rotulo: 'Importados'),
            FxMetric(valor: data.duplicados, rotulo: 'Duplicados'),
            FxMetric(valor: data.erros, rotulo: 'Erros'),
          ],
        ),
        if (comAcesso.isNotEmpty) ...[
          SizedBox(height: TokensStrip.s4),
          Text(
            S.of(context).migracaoAcessoValidade,
            style: FocuxHubTypography.bodyMuted(color: mute),
          ),
          SizedBox(height: TokensStrip.s3),
          // ── E-mail enviado ───────────────────────────────────────────────
          if (data.emailEnviadoAutomaticamente.isNotEmpty) ...[
            _MigracaoGrupoHeader(
              icon: Icons.mark_email_read_rounded,
              color: EagleTokens.good,
              titulo: 'E-mail enviado',
              subtitulo:
                  'Esses alunos já receberam o convite no e-mail. Nenhuma ação necessária.',
              count: data.emailEnviadoAutomaticamente.length,
              ink: ink,
              mute: mute,
            ),
            for (final item in data.emailEnviadoAutomaticamente)
              _MigracaoEmailEnviadoTile(item: item, ink: ink, mute: mute),
            SizedBox(height: TokensStrip.s3),
          ],
          // ── E-mail não saiu: tem e-mail, mas o envio falhou ──────────────
          if (data.emailNaoSaiu.isNotEmpty) ...[
            _MigracaoGrupoHeader(
              icon: Icons.mail_outline_rounded,
              color: EagleTokens.warn,
              titulo: 'E-mail não saiu',
              subtitulo:
                  'Esses alunos têm e-mail, mas o envio falhou. Mande o convite pelo WhatsApp ou copie o link.',
              count: data.emailNaoSaiu.length,
              ink: ink,
              mute: mute,
            ),
            ..._grupoDeConvites(data.emailNaoSaiu, brand),
            SizedBox(height: TokensStrip.s3),
          ],
          // ── Só telefone ──────────────────────────────────────────────────
          if (data.soTelefone.isNotEmpty) ...[
            _MigracaoGrupoHeader(
              icon: Icons.send_rounded,
              color: EagleTokens.whatsapp,
              titulo: 'Só telefone',
              subtitulo: 'Sem e-mail. Envie o convite pelo WhatsApp.',
              count: data.soTelefone.length,
              ink: ink,
              mute: mute,
            ),
            ..._grupoDeConvites(data.soTelefone, brand),
            SizedBox(height: TokensStrip.s3),
          ],
          // ── Sem contato ──────────────────────────────────────────────────
          if (data.semContato.isNotEmpty) ...[
            _MigracaoGrupoHeader(
              icon: Icons.link_rounded,
              color: mute,
              titulo: 'Sem contato',
              subtitulo:
                  'Sem telefone nem e-mail. Copie o link e envie pelo canal que preferir.',
              count: data.semContato.length,
              ink: ink,
              mute: mute,
            ),
            ..._grupoDeConvites(data.semContato, brand),
          ],
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
              OutlinedButton(
                onPressed: () => _whatsapp(context, whatsAppUri),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: const StadiumBorder(),
                ),
                child: Text(s.alunoLinkEnviarWhatsApp),
              ),
              FxTonalButton(label: s.alunoLinkCopiar, onPressed: () => _copiar(context), expanded: true),
            ] else
              OutlinedButton(
                onPressed: () => _copiar(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: const StadiumBorder(),
                ),
                child: Text(s.alunoLinkCopiar),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grupos do Step 3
// ---------------------------------------------------------------------------

class _MigracaoGrupoHeader extends StatelessWidget {
  const _MigracaoGrupoHeader({
    required this.icon,
    required this.color,
    required this.titulo,
    required this.subtitulo,
    required this.count,
    required this.ink,
    required this.mute,
  });

  final IconData icon;
  final Color color;
  final String titulo;
  final String subtitulo;
  final int count;
  final Color ink;
  final Color mute;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ink,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: TextStyle(fontSize: 12, color: mute, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile somente-leitura para alunos que já receberam e-mail — sem botão de ação.
class _MigracaoEmailEnviadoTile extends StatelessWidget {
  const _MigracaoEmailEnviadoTile({
    required this.item,
    required this.ink,
    required this.mute,
  });

  final MigracaoImportacaoDetalhe item;
  final Color ink;
  final Color mute;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: TokensStrip.s3, vertical: 10),
        decoration: fxListCardDecoration(context, accent: EagleTokens.good),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded,
                size: 16, color: EagleTokens.good),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nome,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: ink,
                      fontSize: 13,
                    ),
                  ),
                  if (item.email != null && item.email!.isNotEmpty)
                    Text(
                      item.email!,
                      style:
                          TextStyle(fontSize: 11.5, color: mute, height: 1.3),
                    ),
                ],
              ),
            ),
            Text(
              'E-mail enviado',
              style: TextStyle(
                  fontSize: 11,
                  color: EagleTokens.good,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _MigracaoEnviarTodosButton extends StatelessWidget {
  const _MigracaoEnviarTodosButton({required this.data});

  final List<MigracaoImportacaoDetalhe> data;

  String _blocoConvites(S s) => data
      .map((d) => alunoAtivacaoMessage(s, nome: d.nome, link: d.linkAtivacao ?? ''))
      .join('\n\n');

  Future<void> _copiarEAbrir(BuildContext context) async {
    final s = S.of(context);
    final bloco = _blocoConvites(s);
    await copySensitiveToClipboard(bloco);
    HapticFeedback.mediumImpact();
    if (!context.mounted) return;
    await showFxHomeSheet<void>(
      context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return FxHomeSheetSurface(
          isDark: isDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxHomeSheetHandle(isDark: isDark),
              SizedBox(height: TokensStrip.s4),
              FxHomeSheetHeader(
                isDark: isDark,
                title: migracaoWhatsappFolha(),
              ),
              SizedBox(height: TokensStrip.s4),
              FxLiquidPrimaryButton(
                label: migracaoWhatsappAbrirLabel(),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await launchUrl(
                    Uri.parse('whatsapp://'),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.send_rounded, size: 16),
      label: Text(migracaoCopiarConvitesLabel(data.length)),
      onPressed: () => _copiarEAbrir(context),
    );
  }
}
