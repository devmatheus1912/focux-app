part of 'aluno_dashboard_screen.dart';

/// Card de foco: a única superfície com `emphasize` na Home.
class _TodayFocusCard extends StatelessWidget {
  final AlunoTodayAction action;
  final AlunoHomeInsight? insight;
  final bool isDark;
  final VoidCallback onAction;

  const _TodayFocusCard({
    required this.action,
    required this.isDark,
    required this.onAction,
    this.insight,
  });

  @override
  Widget build(BuildContext context) {
    final texto = alunoTodayTexto(S.of(context), action);
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

/// No máximo um aviso abaixo do foco: anamnese pendente vence o coach.
/// Tudo vem do BFF da Home — nenhum request a mais no fold.
class _AlunoHomeAviso extends StatelessWidget {
  final AlunoHomeAviso aviso;
  final AlunoAnamnesePendente? anamnese;
  final List<CoachMensagem> coachMensagens;

  const _AlunoHomeAviso({
    required this.aviso,
    required this.anamnese,
    required this.coachMensagens,
  });

  @override
  Widget build(BuildContext context) {
    final pendente = anamnese;
    if (aviso == AlunoHomeAviso.anamnese && pendente != null) {
      return _AnamneseAviso(pendente: pendente);
    }
    if (aviso == AlunoHomeAviso.coach) {
      return CoachProativoCard(mensagens: coachMensagens);
    }
    return const SizedBox.shrink();
  }
}

class _AnamneseAviso extends StatelessWidget {
  final AlunoAnamnesePendente pendente;

  const _AnamneseAviso({required this.pendente});

  @override
  Widget build(BuildContext context) {
    final texto = alunoAnamneseAvisoTexto(S.of(context), pendente);
    return Semantics(
      button: true,
      label: '${texto.titulo}. ${texto.detalhe}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
          onTap: () => context.push('/aluno/anamnese'),
          child: AnamneseStatusBanner(
            title: texto.titulo,
            body: texto.detalhe,
            tone:
                pendente == AlunoAnamnesePendente.precisaAtestado
                    ? AnamneseBannerTone.warn
                    : AnamneseBannerTone.info,
          ),
        ),
      ),
    );
  }
}
