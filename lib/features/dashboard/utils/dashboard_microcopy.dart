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

  static const scrollPeekHint = 'Deslize horizontalmente para ver mais';
  static const precisaDeAtencao = 'Precisa de atenção';
  static const aderenciaDaSemana = 'Aderência da semana';
  static const maisFerramentas = 'Mais ferramentas';
  static const ferramentasEmDestaque = 'Ferramentas em destaque';
  static const verCatalogoCompleto = 'Ver catálogo completo';
  static const catalogoCompleto = 'Catálogo completo';
  static const catalogoSubtitle =
      'Ferramentas do plano. Bloqueadas abrem o upgrade.';
  static const buscarFerramenta = 'Buscar ferramenta...';
  static const tendencia7Dias = 'Tendência 7 dias';
  static const tendenciaVaziaChip = 'Sem treinos';
  static const checkinsPulseLabel = 'Check-ins';
  static const tendenciaVaziaBase =
      'Base ativa · nenhum treino nos últimos 7 dias';
  static const tendenciaVaziaGeral = 'Sem check-ins nos últimos 7 dias';
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
  static const helpHomeTitle = 'Ajuda da Home';
  static const helpHomeBody =
      'Foco do dia prioriza o que importa. Próximas ações são o 1-toque. '
      'Radar mostra saúde da base. Use busca ou o catálogo em Mais ferramentas. '
      'Modo Foco esconde o secundário em dia de crise.';
  static const helpHomeOpen = 'Ajuda';
  static const radarDaBase = 'Radar da base';
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
  static const toqueParaExpandir = 'toque para expandir';
  static const toqueParaVer = 'toque para ver';
  static const abrirFinanceiro = 'Abrir financeiro';
  static const rankingSemanalHint = 'Ranking semanal · toque para ver';
  static const treinosRankingHint = 'Treinos e ranking · toque para ver';
  static const abrirCatalogo = 'Abrir catálogo';
  static const nenhumaFerramenta = 'Nenhuma ferramenta encontrada.';
  static const modoFocoChipOnHint = 'Toque para desligar o foco';
  static const modoFocoChipOffHint = 'Toque para ligar o foco';
}
