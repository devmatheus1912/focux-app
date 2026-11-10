part of 'ia_copiloto_screen.dart';

/// Uma análise só; progressão de carga fica no "⋯" do resultado.
const _mode = 'Treino';

class _IaCopilotoScreenState extends ConsumerState<IaCopilotoScreen>
    with SingleTickerProviderStateMixin {
  bool _gerando = false;
  bool _gerado = false;
  bool _mensagemEnviada = false;
  Object? _erro;
  int? _selectedAlunoId;
  String? _selectedAlunoNome;
  int _geracaoMs = 0;
  IaCopilotProximaAcao? _proximaAcao;
  bool _aplicando = false;
  final DateTime _openedAt = DateTime.now();
  bool _viewTracked = false;
  bool _ttvTracked = false;

  List<IaCopilotInsight> get _insights =>
      ref
          .read(
            insightsProvider(
              InsightsQuery(alunoId: _selectedAlunoId, mode: _mode),
            ),
          )
          .value ??
      const [];

  IaCopilotoApplySpec? _acaoDoInsight(IaCopilotInsight insight) =>
      iaCopilotoApplySpec(
        tipoAcao: insight.tipoAcao,
        mensagemSugerida: insight.mensagemSugerida,
        alunoId: _selectedAlunoId,
      );

  /// A barra usa a ação da primeira recomendação que tem ação; sem nenhuma,
  /// a da próxima ação.
  IaCopilotoApplySpec? get _applySpec {
    for (final i in _insights) {
      final acao = _acaoDoInsight(i);
      if (acao != null) return acao;
    }
    return iaCopilotoApplySpec(
      tipoAcao: _proximaAcao?.tipoAcao,
      mensagemSugerida: _proximaAcao?.mensagemSugerida,
      alunoId: _selectedAlunoId,
    );
  }

  String get _resultPrimaryLabel =>
      _mensagemEnviada
          ? S.of(context).copilotoAnalisarOutro
          : _applySpec?.label ?? iaCopilotoCriarTarefaLabel();

  VoidCallback get _resultPrimaryAction {
    if (_mensagemEnviada) return _voltarAoInicio;
    final acao = _applySpec;
    if (acao == null) {
      return () {
        final primeiro = _insights.firstOrNull;
        _atribuir(
          texto: primeiro?.recomendacao,
          motivo: primeiro?.detalhe,
        );
      };
    }
    return () => _aplicarAcao(acao);
  }

  void _voltarAoInicio() {
    setState(() {
      _gerado = false;
      _mensagemEnviada = false;
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
