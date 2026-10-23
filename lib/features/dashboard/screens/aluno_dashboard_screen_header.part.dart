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
    final frase = switch (aviso) {
      AlunoHomeAviso.financeiro =>
        '${s.alunoAvisoFinanceiroTitulo} ${s.alunoAvisoFinanceiroDetalhe}',
      AlunoHomeAviso.atestado ||
      AlunoHomeAviso.anamnese when pendente != null =>
        () {
          final texto = alunoAnamneseAvisoTexto(s, pendente);
          return '${texto.titulo} ${texto.detalhe}';
        }(),
      AlunoHomeAviso.coach when coachMensagens.isNotEmpty =>
        coachMensagens.first.mensagem,
      _ => null,
    };
    if (frase == null) return const SizedBox.shrink();
    final onTap = switch (aviso) {
      AlunoHomeAviso.financeiro => onFinanceiro,
      AlunoHomeAviso.atestado || AlunoHomeAviso.anamnese =>
        () => context.push('/aluno/anamnese'),
      _ => null,
    };
    final chrome = ShellChrome.of(context);
    final text = Text(
      frase,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
    );
    if (onTap == null) return text;
    return InkWell(onTap: onTap, child: text);
  }
}
