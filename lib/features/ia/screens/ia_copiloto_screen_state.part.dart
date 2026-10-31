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

  IaCopilotoApplySpec? get _applySpec => iaCopilotoApplySpec(
        tipoAcao: _proximaAcao?.tipoAcao,
        mensagemSugerida: _proximaAcao?.mensagemSugerida,
      );

  String get _resultPrimaryLabel =>
      _mensagemEnviada
          ? S.of(context).copilotoAnalisarOutro
          : _applySpec?.label ?? iaCopilotoCriarTarefaLabel();

  VoidCallback get _resultPrimaryAction {
    if (_mensagemEnviada) return _voltarAoInicio;
    return _applySpec != null ? _aplicarAcao : _atribuir;
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
