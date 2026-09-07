import '../../../core/ux/fx_hub_freshness.dart';

/// Microcopy do hub personal — títulos e CTAs recorrentes.
abstract final class DashboardMicrocopy {
  DashboardMicrocopy._();

  static const panoramaFinanceiro = 'Panorama financeiro';
  static const pulsoOperacional = 'Pulso operacional';
  static const impactoHoje = 'Impacto hoje';
  static const verPrioridades = 'Ver prioridades';
  static const maisPrioridades = 'Mais prioridades';
  static const lendoSinais = 'lendo sinais';
  static const verTudo = 'Ver tudo';
  static const painelAtualizado = 'Painel atualizado';

  static String atualizadoHa(Duration age) => FxHubFreshness.atualizadoHa(age);

  static const precisaDeAtencao = 'Precisa de atenção';
  static const aderenciaDaSemana = 'Aderência da semana';
  static const maisFerramentas = 'Mais ferramentas';
  static const ferramentasEmDestaque = 'Ferramentas em destaque';
  static const verCatalogoCompleto = 'Ver catálogo';
  static const catalogoCompleto = 'Catálogo';
  static const catalogoSubtitle =
      'Hubs do plano. Bloqueados abrem o upgrade.';
  static const buscarFerramenta = 'Buscar ferramenta ou nome antigo...';
  static const tendencia7Dias = '7 dias';
  static const checkinsPulseLabel = 'Check-ins';
  static const tendenciaVaziaBase = 'Sem treinos';
  static const abrirMensagens = 'Abrir mensagens';
  static const proximasAcoes = 'Próximas ações';
  static const agendaHoje = 'Agenda de hoje';
  static const verAgenda = 'Ver agenda';
  static const buscaRapida = 'Busca rápida';
  static const buscaRapidaHint = 'Aluno ou ferramenta…';
  static const headerRailBuscar = 'Buscar';
  static const headerRailBuscarHint = 'Encontre rápido';
  static const headerRailAjuda = 'Ajuda';
  static const headerRailAjudaHint = 'Central de ajuda';
  static const headerRailFocoHint = 'Menos distrações';
  static const headerRailNotif = 'Notificações';
  static const headerRailNotifHint = 'Novidades e alertas';

  /// Personalidade da marca — fora do header (evita eco com «Foco do dia»).
  static const headerTaglineLead = '';
  static const headerTaglineAccent = 'Resultado';
  static const headerTaglineTail = ' começa hoje.';
  static const sugestaoIa = 'Sugestão IA';
  static const sugestaoIaDisclaimer =
      'Sugestão opcional — você decide se aplica.';
  static const scoreComoCalculamos =
      'Índice Focux (0–100): perfil, consistência de treinos (7d), evolução (30d), '
      'medida recente, chat recente e status financeiro. Risco sobe com dias sem treino.';
  static const helpHomeTitle = 'Como usar o Hoje';
  static const helpHomeBody =
      'Cobrar, retomar e a agenda do dia — um toque no que importa agora.';
  static const helpHomeFocusTitle = 'Foco do dia';
  static const helpHomeFocusBody =
      'O banner é a prioridade do dia. Toque para agir. O chip Foco esconde o resto quando o dia aperta.';
  static const helpHomeActionsTitle = 'Próximas ações';
  static const helpHomeActionsBody =
      'Lista 1-toque abaixo do Foco. Desça até as ferramentas e o sticky some.';
  static const helpHomeRadarTitle = 'Radar e pulso';
  static const helpHomeRadarBody =
      'Até 2 no Hoje — quem pede contato. Cadastro e ficha incompleta ficam no aluno.';
  static const helpHomeSearchTitle = 'Busca e catálogo';
  static const helpHomeSearchBody =
      'A lupa acha aluno ou ferramenta. Mais ferramentas abre o catálogo do plano.';
  static const helpHomeFooter =
      'Sugestão opcional — você decide se aplica. IA só na aba IA, nunca sozinha.';
  static const helpHomeOpen = 'Ajuda';
  static const radarDaBase = 'Radar da base';
  static const radarVerTodos = 'Ver todos';
  static const radarSheetSubtitle =
      'Contato hoje — cadastro e ficha ficam no aluno.';
  static const coachCatalogHint =
      'Abra o catálogo em Mais ferramentas para achar qualquer recurso.';
  static const coachEntendi = 'Entendi';

  /// Alias estável de [proximasAcoes] (contratos/source-scan).
  static const commandCenterTitle = proximasAcoes;
  static const commandCenterSubtitle =
      'A melhor próxima ação para proteger receita e aderência.';
  static const modoFoco = 'Modo foco';
  static const modoFocoOn = 'Modo foco ligado';
  static const modoFocoOff = 'Modo foco desligado';

  /// Chip no banner: estado ativo.
  static const modoFocoChipOn = 'Foco';

  /// Chip no banner: ação para entrar no modo foco.
  static const modoFocoChipOff = 'Focar';
  static const abrirFinanceiro = 'Abrir financeiro';
  static const abrirCatalogo = 'Abrir catálogo';
  static const nenhumaFerramenta = 'Nenhuma ferramenta encontrada.';
  static const modoFocoChipOnHint = 'Toque para desligar o foco';
  static const modoFocoChipOffHint = 'Toque para ligar o foco';
}
