part of 'aluno_dashboard_screen.dart';

class _AlunoAppBarProfileMenu extends StatelessWidget {
  final Aluno aluno;
  final bool isDark;
  final VoidCallback onProfile;

  const _AlunoAppBarProfileMenu({
    required this.aluno,
    required this.isDark,
    required this.onProfile,
  });

  String _initials(String nome) {
    final parts = nome.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    if (parts.length == 1 || parts[1].isEmpty) {
      return parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hasFoto = aluno.fotoUrl != null && aluno.fotoUrl!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(right: TokensStrip.s3),
      child: Semantics(
        button: true,
        label: S.of(context).alunoHomePerfilSemantics,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onProfile,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: BrandPalette.soft(primary, dark: isDark),
            backgroundImage:
                hasFoto
                    ? fxCachedNetworkImageProvider(
                      aluno.fotoUrl!.trim(),
                      maxWidth: 72,
                    )
                    : null,
            child:
                hasFoto
                    ? null
                    : Text(
                      _initials(aluno.nome),
                      style: FocuxHubTypography.chip(primary),
                    ),
          ),
        ),
      ),
    );
  }
}

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
            AlunoHomeInsightLine(
              insight: insight,
              onPrimary: mute,
              onAction: (rota) => context.push(rota),
              showAction: insight.acao?.rota != action.route,
            ),
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
class _AlunoHomeAviso extends ConsumerWidget {
  final bool isDark;
  final List<CoachMensagem> coachMensagens;

  const _AlunoHomeAviso({required this.isDark, required this.coachMensagens});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anamnese = ref.watch(minhaAnamneseProvider).value;
    final aviso = resolveAlunoHomeAviso(
      anamnesePendente: anamnese?.alunoDevePreencher ?? false,
      coachMensagens: coachMensagens.length,
    );
    return switch (aviso) {
      AlunoHomeAviso.anamnese => Padding(
        padding: const EdgeInsets.only(bottom: TokensStrip.s3),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
            onTap: () => context.push('/aluno/anamnese'),
            child: AnamneseStatusBanner(
              title: anamneseAlunoCtaTitle(anamnese!),
              body: anamneseAlunoCtaBody(anamnese),
              tone:
                  anamnese.isPrecisaAtestado
                      ? AnamneseBannerTone.warn
                      : AnamneseBannerTone.info,
            ),
          ),
        ),
      ),
      AlunoHomeAviso.coach => CoachProativoCard(
        isDark: isDark,
        mensagens: coachMensagens,
      ),
      AlunoHomeAviso.nenhum => const SizedBox.shrink(),
    };
  }
}
