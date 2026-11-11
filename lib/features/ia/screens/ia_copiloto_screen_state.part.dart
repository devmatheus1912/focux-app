part of 'ia_copiloto_screen.dart';

/// Uma análise só; progressão de carga fica no "⋯" do resultado.
const _mode = 'Treino';

class _IaCopilotoScreenState extends ConsumerState<IaCopilotoScreen>
    with SingleTickerProviderStateMixin {
  bool _gerando = false;
  bool _gerado = false;

  /// Análise aberta (gerada agora ou reaberta de "Análises recentes").
  CopilotoAnalise? _analise;
  Object? _erro;
  int? _selectedAlunoId;
  String? _selectedAlunoNome;
  int _geracaoMs = 0;
  IaCopilotProximaAcao? _proximaAcao;
  bool _aplicando = false;
  final DateTime _openedAt = DateTime.now();
  bool _viewTracked = false;
  bool _ttvTracked = false;

  IaCopilotoApplySpec? _acaoDoInsight(IaCopilotInsight insight) =>
      iaCopilotoApplySpec(
        tipoAcao: insight.tipoAcao,
        mensagemSugerida: insight.mensagemSugerida,
        alunoId: _selectedAlunoId,
      );

  /// Próxima recomendação pendente e a ação dela (para o rodapé).
  (CopilotoRecomendacao, IaCopilotoApplySpec)? get _proximaComAcao {
    for (final r in _analise?.recomendacoes ?? const <CopilotoRecomendacao>[]) {
      if (!r.pendente) continue;
      final acao = _acaoDoInsight(r.insight);
      if (acao != null) return (r, acao);
    }
    return null;
  }

  void _voltarAoInicio() {
    ref.invalidate(copilotoAnalisesRecentesProvider);
    setState(() {
      _gerado = false;
      _analise = null;
      _selectedAlunoId = null;
      _selectedAlunoNome = null;
      _proximaAcao = null;
      _aplicando = false;
      _erro = null;
    });
  }

  @override
  Widget build(BuildContext context) => buildIaCopilotoBody(context);

  /// Sem cota não há botão de analisar: o cartão já diz quando volta.
  Widget _cotaEsgotadaCard(PlanoFeatures plano) {
    final chrome = ShellChrome.of(context);
    final offer = IaQuotaUpgrade.offerFor(features: plano);
    return Container(
      padding: const EdgeInsets.all(TokensStrip.s3),
      decoration: fxListCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            iaCotaEsgotadaTexto(
              limite: plano.limiteIaMensal ?? 0,
              agora: DateTime.now(),
            ),
            style: FocuxHubTypography.body(color: chrome.ink),
          ),
          if (offer.targetPlan case final alvo?) ...[
            const SizedBox(height: TokensStrip.s3),
            FxTonalButton(
              label: offer.ctaLabel,
              expanded: true,
              onPressed: () => context.push('/assinatura', extra: alvo.apiName),
            ),
          ],
        ],
      ),
    );
  }
}
