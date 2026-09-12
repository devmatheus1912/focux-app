import 'package:flutter/material.dart';

import '../../automacoes/screens/automacoes_screen.dart';
import '../../broadcasts/screens/broadcast_screen.dart';
import '../../captura/screens/leads_publicos_screen.dart';
import '../../dashboard/screens/qualidade_operacional_screen.dart';
import '../../desafios/screens/desafios_screen.dart';
import '../../dunning/screens/dunning_ops_screen.dart';
import '../../exercicios/screens/exercicios_list_screen.dart';
import '../../feed/screens/feed_screen.dart';
import '../../grupos/screens/grupo_aulas_personal_screen.dart';
import '../../habitos/screens/habitos_personal_screen.dart';
import '../../leads/screens/leads_list_screen.dart';
import '../../loja/screens/loja_screen.dart';
import '../../monetizacao/screens/ofertas_upsell_screen.dart';
import '../../nps/screens/nps_dashboard_screen.dart';
import '../../onboarding/screens/onboarding_wizard_screen.dart';
import '../../pacotes/screens/pacotes_screen.dart';
import '../../perfil/screens/equipe_screen.dart';
import '../../perfil/screens/landing_editor_screen.dart';
import '../../perfil/screens/white_label_settings_screen.dart';
import '../../recorrencia/screens/recorrencia_screen.dart';
import '../../referral/screens/referral_screen.dart';
import '../../relatorio/screens/business_reports_screen.dart';
import '../../retencao/screens/churn_dashboard_screen.dart';
import '../../winback/screens/winback_screen.dart';
import 'ferramentas_icons.dart';

/// Constrói a tela existente para [rotaApp] (abas do hub).
Widget? buildFerramentasTabScreen(String? rotaApp) {
  final path = normalizeFerramentasRotaApp(rotaApp);
  if (path == null) return null;
  switch (path) {
    case '/exercicios':
      return const ExerciciosListScreen();
    case '/feed':
      return const FeedScreen();
    case '/habitos':
      return const HabitosPersonalScreen();
    case '/desafios':
      return const DesafiosScreen();
    case '/leads':
      return const LeadsListScreen();
    case '/referral':
      return const ReferralScreen();
    case '/leads-publicos':
      return const LeadsPublicosScreen();
    case '/winback':
      return const WinbackScreen();
    case '/retencao':
      return const ChurnDashboardScreen();
    case '/perfil/landing-editor':
      return const LandingEditorScreen();
    case '/nps':
      return const NpsDashboardScreen();
    case '/ofertas-upsell':
      return const OfertasUpsellScreen();
    case '/pacotes':
      return const PacotesScreen();
    case '/loja':
      return const LojaScreen();
    case '/relatorio/business':
      return const BusinessReportsScreen();
    case '/dunning':
      return const DunningOpsScreen();
    case '/recorrencia':
      return const RecorrenciaScreen();
    case '/white-label':
      return const WhiteLabelSettingsScreen();
    case '/automacoes':
      return const AutomacoesScreen();
    case '/perfil/equipe':
      return const EquipeScreen();
    case '/grupo-aulas':
      return const GrupoAulasPersonalScreen();
    case '/onboarding/wizard':
      return const OnboardingWizardScreen();
    case '/dashboard/qualidade':
      return const QualidadeOperacionalScreen();
    case '/broadcasts':
      return const BroadcastScreen();
    default:
      return null;
  }
}
