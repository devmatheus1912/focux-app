import '../data/planos_repository.dart';

/// Resolve flags de capability vindas de `/api/planos/me`.
class PlanoCapability {
  PlanoCapability._();

  static bool has(PlanoFeatures features, String capability) {
    switch (capability) {
      case 'financeiro':
        return features.financeiro;
      case 'agenda':
        return features.agenda;
      case 'relatorios':
        return features.relatorios;
      case 'whiteLabel':
        return features.whiteLabel;
      case 'iaCopiloto':
        return features.iaCopiloto;
      case 'migracaoFoto':
        return features.migracaoFoto;
      case 'landingCompleta':
        return features.landingCompleta;
      case 'habitCoaching':
        return features.habitCoaching;
      case 'comunidadePrivada':
        return features.comunidadePrivada;
      case 'automacoes':
        return features.automacoes;
      case 'automacoesAvancadas':
        return features.automacoesAvancadas;
      case 'comunidadeGrupos':
        return features.comunidadeGrupos;
      case 'equipeRbac':
        return features.equipeRbac;
      case 'lojaDigital':
        return features.lojaDigital;
      case 'poseCoach':
        return features.poseCoach;
      default:
        return false;
    }
  }
}
