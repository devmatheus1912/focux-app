part of 'ia_copiloto_screen.dart';

class _IaCopilotoScreenState extends ConsumerState<IaCopilotoScreen>
    with SingleTickerProviderStateMixin {
  int _modeIdx = 0;
  bool _gerando = false;
  bool _gerado = false;
  Object? _erro;
  int? _selectedAlunoId;
  String? _selectedAlunoNome;
  // BUG-21: tempo real de geração
  int _geracaoMs = 0;
  DateTime? _fetchedAt;
  IaCopilotProximaAcao? _proximaAcao;
  bool _tarefaCriada = false;
  bool _tarefaPersistida = false;
  bool _aplicando = false;
  final DateTime _openedAt = DateTime.now();
  bool _viewTracked = false;
  bool _ttvTracked = false;
  final _modes = ['Treino', 'Progressão'];

  String get _mode => _modes[_modeIdx];
  String get _modeDisplay => _mode == 'Progressão' ? 'Progresso' : _mode;

  IaCopilotoApplySpec? get _applySpec => iaCopilotoApplySpec(
        tipoAcao: _proximaAcao?.tipoAcao,
        mensagemSugerida: _proximaAcao?.mensagemSugerida,
      );

  bool get _resultUsesApplyOrProgressao =>
      _applySpec != null ||
      iaCopilotoShouldReviewProgressao(mode: _mode, apply: _applySpec);

  String get _resultPrimaryLabel {
    final apply = _applySpec;
    if (apply != null) return apply.label;
    if (iaCopilotoShouldReviewProgressao(mode: _mode, apply: apply)) {
      return iaCopilotoRevisarProgressaoLabel();
    }
    return iaCopilotoCriarTarefaLabel();
  }

  VoidCallback get _resultPrimaryAction {
    final apply = _applySpec;
    if (apply != null) return _aplicarAcao;
    if (iaCopilotoShouldReviewProgressao(mode: _mode, apply: apply)) {
      return _abrirProgressao;
    }
    return _atribuir;
  }

  String get _howItWorksPreview {
    switch (_mode) {
      case 'Progressão':
        return 'O Copiloto sugere ajustes com base em dados do aluno. Nada altera treino ou carga automaticamente — você revisa e aplica no atendimento.';
      default:
        return 'O Copiloto não monta fichas de treino. Ele gera recomendações em texto (riscos, volume, foco). Você cria e edita os treinos em Treinos, com total autonomia.';
    }
  }

  String get _resultNote {
    switch (_mode) {
      case 'Progressão':
        return 'Recomendações de progressão com base nos treinos do plano. Revise antes de ajustar carga ou volume na prática.';
      default:
        return 'Recomendações para prescrever o treino. Use como apoio à decisão; monte e publique o treino manualmente em Treinos.';
    }
  }

  @override
  Widget build(BuildContext context) => buildIaCopilotoBody(context);

  String _quotaHeaderLabel(PlanoFeatures? features) {
    if (features == null) return 'Pronto';
    if (features.iaQuotaEsgotada) return 'Cota esgotada';
    return ptCountLabel(features.iaRestantes, 'restante', 'restantes');
  }
}
