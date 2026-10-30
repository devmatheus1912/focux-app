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
          ? S.of(context).copilotoMensagemEnviada
          : _applySpec?.label ?? iaCopilotoCriarTarefaLabel();

  VoidCallback? get _resultPrimaryAction {
    if (_mensagemEnviada) return null;
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

  /// Cota só aparece quando pede atenção.
  String? _quotaHeaderLabel(PlanoFeatures? features) {
    if (features == null) return null;
    if (features.iaQuotaEsgotada) return 'Cota esgotada';
    final limite = features.limiteIaMensal ?? 0;
    if (limite <= 0 || features.iaRestantes * 5 > limite) return null;
    return ptCountLabel(features.iaRestantes, 'restante', 'restantes');
  }
}
