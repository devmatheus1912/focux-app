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
  final _modes = ['Treino', 'Dieta', 'Progressão'];

  String get _mode => _modes[_modeIdx];
  String get _modeDisplay => _mode == 'Progressão' ? 'Progresso' : _mode;

  IconData get _modeIcon {
    switch (_mode) {
      case 'Dieta':
        return Icons.restaurant_menu_outlined;
      case 'Progressão':
        return Icons.trending_up_outlined;
      default:
        return Icons.fitness_center_outlined;
    }
  }

  String get _readinessHeadline {
    switch (_mode) {
      case 'Dieta':
        return 'Recomendações · Dieta';
      case 'Progressão':
        return 'Recomendações · Progresso';
      default:
        return 'Recomendações · Treino';
    }
  }

  String get _modePromise {
    switch (_mode) {
      case 'Dieta':
        return 'Analisa objetivo e rotina do aluno e sugere pontos de atenção. O plano alimentar continua sendo montado por você.';
      case 'Progressão':
        return 'Lê histórico, check-ins e aderência para sugerir ajuste de carga, volume ou frequência — você decide o que aplicar.';
      default:
        return 'Analisa objetivo, nível, equipamentos e histórico do aluno. Você monta e edita os treinos na aba Treinos.';
    }
  }

  List<String> get _modeChecks {
    switch (_mode) {
      case 'Dieta':
        return [
          'Objetivo do aluno',
          'Rotina declarada',
          'Alertas para revisão',
        ];
      case 'Progressão':
        return ['Histórico recente', 'Prontidão wearable', 'Próxima ação'];
      default:
        return ['Objetivo e nível', 'Foco de volume', 'Próxima ação sugerida'];
    }
  }

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
      case 'Dieta':
        return 'O Copiloto não cria plano alimentar no app. Ele gera recomendações em texto para você revisar e montar a prescrição com autonomia.';
      case 'Progressão':
        return 'O Copiloto sugere ajustes com base em dados do aluno. Nada altera treino ou carga automaticamente — você revisa e aplica no atendimento.';
      default:
        return 'O Copiloto não monta fichas de treino. Ele gera recomendações em texto (riscos, volume, foco). Você cria e edita os treinos em Treinos, com total autonomia.';
    }
  }

  String get _resultNote {
    switch (_mode) {
      case 'Dieta':
        return 'Recomendações de dieta para revisão. Monte o plano no fluxo que você já usa — nada é aplicado ao aluno automaticamente.';
      case 'Progressão':
        return 'Recomendações de progressão com base em check-ins e histórico. Revise antes de ajustar carga ou volume na prática.';
      default:
        return 'Recomendações para prescrever o treino. Use como apoio à decisão; monte e publique o treino manualmente em Treinos.';
    }
  }

  @override
  Widget build(BuildContext context) => buildIaCopilotoBody(context);

  String _quotaHeaderLabel(PlanoFeatures? features) {
    if (features == null) return 'Pronto';
    if (features.iaQuotaEsgotada) return 'Cota esgotada';
    return '${features.iaRestantes} restantes';
  }
}
