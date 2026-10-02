import '../../subscription/models/subscription_plan.dart';

/// Recurso do plano conforme `recursos` de `/api/planos/me` e
/// `/api/planos/contexto-aluno` (plano efetivo, validade já aplicada).
class PlanoRecurso {
  final bool liberado;
  final SubscriptionPlan planoMinimo;

  const PlanoRecurso({required this.liberado, required this.planoMinimo});

  static PlanoRecurso? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final liberado = raw['liberado'];
    if (liberado is! bool) return null;
    final minimo = raw['planoMinimo'];
    return PlanoRecurso(
      liberado: liberado,
      planoMinimo:
          minimo is String && minimo.trim().isNotEmpty
              ? subscriptionPlanFromApi(minimo)
              : SubscriptionPlan.PRO,
    );
  }

  Map<String, dynamic> toJson() => {
    'liberado': liberado,
    'planoMinimo': planoMinimo.name,
  };

  @override
  bool operator ==(Object other) =>
      other is PlanoRecurso &&
      other.liberado == liberado &&
      other.planoMinimo == planoMinimo;

  @override
  int get hashCode => Object.hash(liberado, planoMinimo);

  @override
  String toString() => 'PlanoRecurso($liberado, ${planoMinimo.name})';
}

/// Chaves de `recursos` e matriz de produto usada quando o backend não as envia.
abstract final class PlanoRecursoKeys {
  static const financeiro = 'financeiro';
  static const recorrencia = 'recorrencia';
  static const carteira = 'carteira';
  static const relatorios = 'relatorios';
  static const habitos = 'habitos';
  static const feedbackVideo = 'feedbackVideo';
  static const ia = 'ia';
  static const importacaoFoto = 'importacaoFoto';
  static const leads = 'leads';
  static const landing = 'landing';
  static const whiteLabel = 'whiteLabel';
  static const loja = 'loja';
  static const automacoes = 'automacoes';
  static const winback = 'winback';
  static const desafios = 'desafios';
  static const equipe = 'equipe';
  static const nfse = 'nfse';

  static const matrix = <String, SubscriptionPlan>{
    financeiro: SubscriptionPlan.PRO,
    recorrencia: SubscriptionPlan.PRO,
    carteira: SubscriptionPlan.PRO,
    relatorios: SubscriptionPlan.PRO,
    habitos: SubscriptionPlan.PRO,
    feedbackVideo: SubscriptionPlan.PRO,
    ia: SubscriptionPlan.PRO,
    importacaoFoto: SubscriptionPlan.PRO,
    leads: SubscriptionPlan.PRO,
    landing: SubscriptionPlan.ENTERPRISE,
    whiteLabel: SubscriptionPlan.ENTERPRISE,
    loja: SubscriptionPlan.ENTERPRISE,
    automacoes: SubscriptionPlan.ENTERPRISE,
    winback: SubscriptionPlan.ENTERPRISE,
    desafios: SubscriptionPlan.ENTERPRISE,
    equipe: SubscriptionPlan.ENTERPRISE,
    nfse: SubscriptionPlan.ENTERPRISE,
  };

  static const _fromLegacy = <String, String>{
    'iaCopiloto': ia,
    'migracaoFoto': importacaoFoto,
    'landingCompleta': landing,
    'habitCoaching': habitos,
    'lojaDigital': loja,
    'comunidadeGrupos': desafios,
    'equipeRbac': equipe,
    'automacoesAvancadas': automacoes,
  };

  static const _toLegacy = <String, String>{
    ia: 'iaCopiloto',
    importacaoFoto: 'migracaoFoto',
    landing: 'landingCompleta',
    habitos: 'habitCoaching',
    loja: 'lojaDigital',
    desafios: 'comunidadeGrupos',
    equipe: 'equipeRbac',
    recorrencia: 'financeiro',
    carteira: 'financeiro',
    winback: 'automacoes',
  };

  /// Chave de `recursos` para uma capability (legada ou já no formato novo).
  static String? fromCapability(String? capability) {
    if (capability == null || capability.isEmpty) return null;
    if (matrix.containsKey(capability)) return capability;
    return _fromLegacy[capability];
  }

  /// Capability conhecida pela copy de upgrade ([PlanEntitlements]).
  static String? toCopyCapability(String? capability) {
    if (capability == null) return null;
    return _toLegacy[capability] ?? capability;
  }

  static PlanoRecurso fallbackFor(String key, SubscriptionPlan plano) {
    final minimo = matrix[key] ?? SubscriptionPlan.PRO;
    return PlanoRecurso(liberado: plano.canAccess(minimo), planoMinimo: minimo);
  }
}
