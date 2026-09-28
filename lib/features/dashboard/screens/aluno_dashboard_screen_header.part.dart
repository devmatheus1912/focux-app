part of 'aluno_dashboard_screen.dart';

/// No máximo um aviso abaixo do foco: atestado, mensalidade atrasada,
/// anamnese, coach. Tudo vem do BFF da Home — nenhum request a mais.
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
      AlunoHomeAviso.atestado ||
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
