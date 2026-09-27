part of 'aluno_dashboard_screen.dart';

/// Card de foco: a única superfície com `emphasize` na Home.
class _TodayFocusCard extends StatelessWidget {
  final AlunoTodayAction action;
  final AlunoHomeInsight? insight;
  final bool prontidaoBaixa;
  final bool isDark;
  final VoidCallback onAction;

  const _TodayFocusCard({
    required this.action,
    required this.isDark,
    required this.onAction,
    this.insight,
    this.prontidaoBaixa = false,
  });

  @override
  Widget build(BuildContext context) {
    final texto = alunoTodayTexto(
      S.of(context),
      action,
      prontidaoBaixa: prontidaoBaixa,
    );
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.of(context);
    final mute = chrome.mute;

    return FxStripCard(
      emphasize: true,
      glowStrength: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texto.eyebrow,
            style: FocuxHubTypography.eyebrow(context, color: mute),
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            texto.titulo,
            style: FocuxHubTypography.pageTitle(context, color: chrome.ink),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            texto.descricao,
            style: FocuxHubTypography.bodyMuted(color: mute),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (insight case final insight?) ...[
            const SizedBox(height: TokensStrip.s3),
            AlunoHomeInsightLine(insight: insight, onPrimary: mute),
          ],
          const SizedBox(height: TokensStrip.s3),
          FxActionChip(
            label: texto.cta,
            accent: primary,
            isDark: isDark,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}

/// No máximo um aviso abaixo do foco: mensalidade atrasada, depois anamnese
/// pendente, depois o coach. Tudo vem do BFF da Home — nenhum request a mais.
class _AlunoHomeAviso extends StatelessWidget {
  final AlunoHomeAviso aviso;
  final AlunoAnamnesePendente? anamnese;
  final List<CoachMensagem> coachMensagens;
  final VoidCallback onFinanceiro;

  const _AlunoHomeAviso({
    required this.aviso,
    required this.anamnese,
    required this.coachMensagens,
    required this.onFinanceiro,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final pendente = anamnese;
    return switch (aviso) {
      AlunoHomeAviso.financeiro => _AvisoBanner(
        titulo: s.alunoAvisoFinanceiroTitulo,
        detalhe: s.alunoAvisoFinanceiroDetalhe,
        tone: FxBannerTone.warn,
        onTap: onFinanceiro,
      ),
      AlunoHomeAviso.anamnese when pendente != null => _anamnese(
        context,
        pendente,
      ),
      AlunoHomeAviso.coach => CoachProativoCard(mensagens: coachMensagens),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _anamnese(BuildContext context, AlunoAnamnesePendente pendente) {
    final texto = alunoAnamneseAvisoTexto(S.of(context), pendente);
    return _AvisoBanner(
      titulo: texto.titulo,
      detalhe: texto.detalhe,
      tone:
          pendente == AlunoAnamnesePendente.precisaAtestado
              ? FxBannerTone.warn
              : FxBannerTone.info,
      onTap: () => context.push('/aluno/anamnese'),
    );
  }
}

class _AvisoBanner extends StatelessWidget {
  final String titulo;
  final String detalhe;
  final FxBannerTone tone;
  final VoidCallback onTap;

  const _AvisoBanner({
    required this.titulo,
    required this.detalhe,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$titulo. $detalhe',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
          onTap: onTap,
          child: FxStatusBanner(title: titulo, body: detalhe, tone: tone),
        ),
      ),
    );
  }
}
