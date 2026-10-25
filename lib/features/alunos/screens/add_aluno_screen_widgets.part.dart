part of 'add_aluno_screen.dart';

/// Uma linha que diz o que falta: só nome e e-mail são obrigatórios.
class _StatusDoCadastro extends StatelessWidget {
  final String name;
  final bool pronto;
  final bool isDark;

  const _StatusDoCadastro({
    required this.name,
    required this.pronto,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2),
      child: Row(
        children: [
          if (pronto) ...[
            Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: TokensStrip.s2),
          ],
          Expanded(
            child: Text(
              pronto
                  ? addAlunoProntoParaConvidar(name)
                  : addAlunoSoNomeEEmail(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: FxSettingsLayout.subhead(
                color: pronto ? ink : mute,
              ).copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
