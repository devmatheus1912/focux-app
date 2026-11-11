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
        Text(
          migracaoImportadosLinha(data.importados),
          style: FocuxHubTypography.sectionTitle(context, color: ink),
        ),
        if (data.duplicados > 0)
          _MigracaoLinhaDeQuais(
            texto: migracaoDuplicadosLinha(data.duplicados),
            itens: [
              for (final d in data.detalhes)
                if (d.status == 'DUPLICADO') d,
            ],
          ),
        if (data.erros > 0)
          _MigracaoLinhaDeQuais(
            texto: migracaoErrosLinha(data.erros),
            itens: [
              for (final d in data.detalhes)
                if (d.status != 'DUPLICADO' && d.status != 'IMPORTADO') d,
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
              icon: FxIcons.emailLido,
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
              icon: FxIcons.email,
              color: EagleTokens.warn,
              titulo: migracaoGrupoProgresso(
                'E-mail não saiu',
                feitos: data.emailNaoSaiu.where((d) => status.containsKey(d.alunoId)).length,
                total: data.emailNaoSaiu.length,
              ),
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
              icon: FxIcons.enviar,
              color: EagleTokens.whatsapp,
              titulo: migracaoGrupoProgresso(
                'Só telefone',
                feitos: data.soTelefone.where((d) => status.containsKey(d.alunoId)).length,
                total: data.soTelefone.length,
              ),
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
              icon: FxIcons.link,
              color: mute,
              titulo: migracaoGrupoProgresso(
                'Sem contato',
                feitos: data.semContato.where((d) => status.containsKey(d.alunoId)).length,
                total: data.semContato.length,
              ),
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
                            fontSize: TokensStrip.fontBodySm,
                          ),
                        ),
                        if (item.motivo.isNotEmpty)
                          Text(
                            item.motivo,
                            style: TextStyle(
                              fontSize: TokensStrip.fontMinimo,
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

    final contato = [
      if (item.telefone?.trim().isNotEmpty ?? false) item.telefone!.trim(),
      if (email != null) email,
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: TokensStrip.s2),
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s3,
        TokensStrip.s2,
        TokensStrip.s1,
        TokensStrip.s2,
      ),
      decoration: fxListCardDecoration(context),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nome,
                  style: FocuxHubTypography.cardTitle(color: ink),
                ),
                if (contato.isNotEmpty)
                  Text(
                    contato,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.bodyMuted(color: mute),
                  ),
              ],
            ),
          ),
          if (feito)
            Padding(
              padding: const EdgeInsets.only(right: TokensStrip.s2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FxIcons.concluido, size: 16, color: EagleTokens.good),
                  const SizedBox(width: 4),
                  Text(
                    status == MigracaoAcessoStatus.enviado
                        ? s.migracaoAcessoEnviado
                        : s.migracaoAcessoCopiado,
                    style: FocuxHubTypography.chip(EagleTokens.good),
                  ),
                ],
              ),
            )
          else ...[
            if (whatsAppUri != null)
              IconButton(
                tooltip: s.alunoLinkEnviarWhatsApp,
                onPressed: () => _whatsapp(context, whatsAppUri),
                icon: const Icon(FxIcons.chat, color: EagleTokens.whatsapp),
              ),
            IconButton(
              tooltip: 'Mais opções de ${item.nome}',
              icon: Icon(FxIcons.mais, color: mute),
              onPressed: () async {
                final escolha = await showFxGroupedActionSheet<String>(
                  context,
                  titulo: item.nome,
                  grupos: [
                    FxActionGroup<String>(null, [
                      FxActionItem(
                        valor: 'copiar',
                        rotulo: 'Copiar convite',
                        icone: FxIcons.copiar,
                      ),
                    ]),
                  ],
                );
                if (escolha == 'copiar' && context.mounted) {
                  await _copiar(context);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// "2 já estavam na sua lista": toque mostra quais (nome e motivo).
class _MigracaoLinhaDeQuais extends StatelessWidget {
  const _MigracaoLinhaDeQuais({required this.texto, required this.itens});

  final String texto;
  final List<MigracaoImportacaoDetalhe> itens;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return InkWell(
      onTap:
          itens.isEmpty
              ? null
              : () => showFxHomeSheet<void>(
                context,
                builder:
                    (_) => FxSheetFrame(
                      title: texto,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final d in itens)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: TokensStrip.s2,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.nome,
                                    style: FocuxHubTypography.cardTitle(
                                      color: chrome.ink,
                                    ),
                                  ),
                                  if (d.motivo.isNotEmpty)
                                    Text(
                                      d.motivo,
                                      style: FocuxHubTypography.bodyMuted(
                                        color: chrome.mute,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
              ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          children: [
            Expanded(
              child: Text(
                texto,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
            ),
            if (itens.isNotEmpty)
              Icon(FxIcons.chevronDireita, size: 16, color: chrome.mute),
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
                          fontSize: TokensStrip.fontBodySm,
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
                          fontSize: TokensStrip.fontMinimo,
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
                  style: TextStyle(fontSize: TokensStrip.fontRotulo, color: mute, height: 1.35),
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
            Icon(FxIcons.concluido,
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
                      fontSize: TokensStrip.fontBodySm,
                    ),
                  ),
                  if (item.email != null && item.email!.isNotEmpty)
                    Text(
                      item.email!,
                      style:
                          TextStyle(fontSize: TokensStrip.fontMinimo, color: mute, height: 1.3),
                    ),
                ],
              ),
            ),
            Text(
              'E-mail enviado',
              style: TextStyle(
                  fontSize: TokensStrip.fontMinimo,
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
      icon: const Icon(FxIcons.enviarPequeno, size: 16),
      label: Text(migracaoCopiarConvitesLabel(data.length)),
      onPressed: () => _copiarEAbrir(context),
    );
  }
}
