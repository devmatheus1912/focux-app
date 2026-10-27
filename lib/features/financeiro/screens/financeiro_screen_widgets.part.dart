part of 'financeiro_screen.dart';

/// Faixa "Recebido · A receber · Atrasado" do mês e, quando falta a chave PIX,
/// o convite para cadastrá-la.
class _NumerosDoMes extends ConsumerWidget {
  const _NumerosDoMes({required this.onAbrir});

  final ValueChanged<MensalidadeFiltro> onAbrir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumo = ref.watch(financeiroHomeProvider).value?.resumoMesAtual;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        TokensStrip.s3,
        FxSettingsLayout.pageInset,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (resumo != null)
            FinanceiroNumerosMes(resumo: resumo, onAbrir: onAbrir),
          const FinanceiroChavePixLinha(soSeFaltar: true),
        ],
      ),
    );
  }
}

class _FinanceiroAlunoContextBanner extends ConsumerWidget {
  const _FinanceiroAlunoContextBanner({required this.alunoId});

  final int alunoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alunoAsync = ref.watch(alunoProvider(alunoId));
    final nome = alunoAsync.value?.nome;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        TokensStrip.s2,
        FxSettingsLayout.pageInset,
        0,
      ),
      child: Text(
        financeiroAlunoContextLabel(nome),
        style: FxSettingsLayout.sectionHeader(
          color: ShellChrome.of(context).mute,
        ),
      ),
    );
  }
}
