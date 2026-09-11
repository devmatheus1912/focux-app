part of 'focux_surfaces.dart';

const _s1 = FocuxSurfaceType.s1;
const _s2 = FocuxSurfaceType.s2;
const _s3 = FocuxSurfaceType.s3;
const _s4 = FocuxSurfaceType.s4;
const _s5 = FocuxSurfaceType.s5;
const _s6 = FocuxSurfaceType.s6;
const _s8 = FocuxSurfaceType.s8;
const _s9 = FocuxSurfaceType.s9;

const _s1Tab = FocuxSurfaceSpec(type: _s1, shellTab: true);
const _s2Tab = FocuxSurfaceSpec(type: _s2, shellTab: true);
const _s4Tab = FocuxSurfaceSpec(type: _s4, shellTab: true);
const _s6Root = FocuxSurfaceSpec(type: _s6);
const _s9Root = FocuxSurfaceSpec(type: _s9);

const _home = '/dashboard/personal';
const _alunoHome = '/dashboard/aluno';
const _perfil = '/perfil';
const _ferramentas = '/perfil/ferramentas';

const Map<String, FocuxSurfaceSpec> focuxSurfaceCatalog = {
  '/': _s6Root,
  '/home': FocuxSurfaceSpec(type: _s1, redirectTo: _home),
  '/dashboard': FocuxSurfaceSpec(type: _s1, redirectTo: _home),
  '/dashboard/home': FocuxSurfaceSpec(type: _s1, redirectTo: _home),
  '/personal': FocuxSurfaceSpec(type: _s1, redirectTo: _home),
  '/aluno': FocuxSurfaceSpec(type: _s1, redirectTo: _alunoHome),
  '/ia': FocuxSurfaceSpec(type: _s1, redirectTo: '/ia/copiloto'),
  '/evolucao': FocuxSurfaceSpec(type: _s1, redirectTo: _alunoHome),
  '/login': _s6Root,
  '/login/mfa': FocuxSurfaceSpec(
    type: _s6,
    hasInput: true,
    logicalParent: '/login',
  ),
  '/register': FocuxSurfaceSpec(
    type: _s6,
    hasInput: true,
    logicalParent: '/login',
  ),
  '/register/aluno': FocuxSurfaceSpec(
    type: _s6,
    hasInput: true,
    logicalParent: '/login',
  ),
  '/esqueci-senha': FocuxSurfaceSpec(
    type: _s6,
    hasInput: true,
    logicalParent: '/login',
  ),
  '/resetar-senha': FocuxSurfaceSpec(
    type: _s6,
    hasInput: true,
    logicalParent: '/login',
  ),
  '/resetar-senha/verificar-codigo': FocuxSurfaceSpec(
    type: _s6,
    hasInput: true,
    logicalParent: '/esqueci-senha',
  ),
  '/aluno/definir-senha': FocuxSurfaceSpec(
    type: _s6,
    hasInput: true,
    logicalParent: '/login',
  ),
  '/onboarding': _s9Root,
  '/onboarding/wizard': FocuxSurfaceSpec(
    type: _s9,
    logicalParent: _home,
  ),
  '/dashboard/personal': _s1Tab,
  '/alunos': FocuxSurfaceSpec(
    type: _s4,
    shellTab: true,
    hasInput: true,
  ),
  '/treinos': FocuxSurfaceSpec(
    type: _s4,
    shellTab: true,
    hasInput: true,
  ),
  '/agenda': _s1Tab,
  '/ia/copiloto': _s1Tab,
  '/dashboard/aluno': _s1Tab,
  '/checkin/treinos': _s4Tab,
  '/saude': _s1Tab,
  '/aluno/perfil': _s2Tab,
  '/aluno/perfil/editar': FocuxSurfaceSpec(
    type: _s5,
    hasInput: true,
    logicalParent: '/aluno/perfil',
  ),
  '/aluno/ativacao': FocuxSurfaceSpec(type: _s9, logicalParent: _alunoHome),
  '/aluno/habitos': FocuxSurfaceSpec(type: _s4, logicalParent: _alunoHome),
  '/aluno/habitos/:id': FocuxSurfaceSpec(
    type: _s3,
    logicalParent: '/aluno/habitos',
  ),
  '/aluno/desafios': FocuxSurfaceSpec(type: _s4, logicalParent: _alunoHome),
  '/aluno/desafios/:id': FocuxSurfaceSpec(
    type: _s3,
    logicalParent: '/aluno/desafios',
  ),
  '/aluno/recorrencia': FocuxSurfaceSpec(type: _s3, logicalParent: _alunoHome),
  '/aluno/trilhas': FocuxSurfaceSpec(type: _s3, logicalParent: _alunoHome),
  '/aluno/grupo-aulas': FocuxSurfaceSpec(type: _s4, logicalParent: _alunoHome),
  '/aluno/form-check': FocuxSurfaceSpec(
    type: _s5,
    hasInput: true,
    logicalParent: _alunoHome,
    redirectTo: _alunoHome,
  ),
  '/aluno/anamnese': FocuxSurfaceSpec(
    type: _s5,
    hasInput: true,
    logicalParent: '/aluno/perfil',
  ),
  '/dashboard/qualidade': FocuxSurfaceSpec(type: _s1, logicalParent: _home),
  '/dashboard/command-center/copiloto': FocuxSurfaceSpec(
    type: _s1,
    logicalParent: _home,
  ),
  '/alunos/novo': FocuxSurfaceSpec(
    type: _s5,
    hasInput: true,
    logicalParent: '/alunos',
  ),
  '/alunos/acoes-massa': FocuxSurfaceSpec(
    type: _s5,
    hasInput: true,
    logicalParent: '/alunos',
  ),
  '/kanban': FocuxSurfaceSpec(type: _s4, logicalParent: '/alunos'),
  '/alunos/:id': FocuxSurfaceSpec(type: _s3, logicalParent: '/alunos'),
  '/alunos/:id/editar': FocuxSurfaceSpec(
    type: _s5,
    hasInput: true,
    logicalParent: '/alunos/:id',
  ),
  '/alunos/:id/equipamentos': FocuxSurfaceSpec(
    type: _s5,
    logicalParent: '/alunos/:id',
  ),
  '/alunos/:id/relatorio': FocuxSurfaceSpec(
    type: _s3,
    logicalParent: '/alunos/:id',
  ),
  '/alunos/:id/evolucao': FocuxSurfaceSpec(
    type: _s3,
    logicalParent: '/alunos/:id',
  ),
  '/alunos/:id/plano-sucesso': FocuxSurfaceSpec(
    type: _s3,
    logicalParent: '/alunos/:id',
  ),
  '/alunos/:id/fotos': FocuxSurfaceSpec(
    type: _s4,
    logicalParent: '/alunos/:id',
  ),
  '/treino-presencial/:id': FocuxSurfaceSpec(
    type: _s8,
    logicalParent: '/treinos/:id',
  ),
  '/alunos/:id/anamnese': FocuxSurfaceSpec(
    type: _s3,
    hasInput: true,
    logicalParent: '/alunos/:id',
  ),
  '/personal/alunos/:id/anamnese': FocuxSurfaceSpec(
    type: _s3,
    hasInput: true,
    logicalParent: '/alunos/:id',
  ),
  '/alunos/:id/treinos-list': FocuxSurfaceSpec(
    type: _s4,
    logicalParent: '/alunos/:id',
  ),
  '/alunos/:id/ia/progressao': FocuxSurfaceSpec(
    type: _s3,
    hasInput: true,
    logicalParent: '/alunos/:id',
  ),
  '/alunos/:id/chat': FocuxSurfaceSpec(type: _s1, logicalParent: '/alunos/:id'),
  '/alunos/:id/feedback-video': FocuxSurfaceSpec(
    type: _s4,
    hasInput: true,
    logicalParent: '/alunos/:id',
  ),
  '/alunos/:id/engajamento': FocuxSurfaceSpec(
    type: _s3,
    logicalParent: '/alunos/:id',
  ),
  '/alunos/:id/evolucao-comparativo': FocuxSurfaceSpec(
    type: _s3,
    logicalParent: '/alunos/:id',
  ),
  '/alunos/:id/trilhas': FocuxSurfaceSpec(
    type: _s3,
    hasInput: true,
    logicalParent: '/alunos/:id',
  ),
  '/alunos/:id/feedback-videos': FocuxSurfaceSpec(
    type: _s4,
    hasInput: true,
    logicalParent: '/alunos/:id',
  ),
  '/treinos/novo': FocuxSurfaceSpec(
    type: _s5,
    hasInput: true,
    logicalParent: '/treinos',
  ),
  '/treinos/:id': FocuxSurfaceSpec(type: _s3, logicalParent: '/treinos'),
  '/treinos/:id/exercicios/add': FocuxSurfaceSpec(
    type: _s5,
    hasInput: true,
    logicalParent: '/treinos/:id',
  ),
  '/exercicios': FocuxSurfaceSpec(
    type: _s4,
    hasInput: true,
    logicalParent: '/treinos',
  ),
  '/exercicios/novo': FocuxSurfaceSpec(
    type: _s5,
    hasInput: true,
    logicalParent: '/exercicios',
  ),
  '/exercicios/biblioteca-wizard': FocuxSurfaceSpec(
    type: _s9,
    logicalParent: '/exercicios',
  ),
  '/exercicios/:id/editar': FocuxSurfaceSpec(
    type: _s5,
    hasInput: true,
    logicalParent: '/exercicios/:id',
  ),
  '/exercicios/:id': FocuxSurfaceSpec(type: _s3, logicalParent: '/exercicios'),
  '/checkin': FocuxSurfaceSpec(type: _s1, logicalParent: _home),
  '/checkin/executar': FocuxSurfaceSpec(
    type: _s8,
    logicalParent: '/checkin/treinos',
  ),
  '/checkin/historico': FocuxSurfaceSpec(
    type: _s4,
    hasInput: true,
    logicalParent: '/checkin/treinos',
  ),
  '/checkin/historico/:id': FocuxSurfaceSpec(
    type: _s3,
    logicalParent: '/checkin/historico',
  ),
  '/agenda/novo': FocuxSurfaceSpec(
    type: _s5,
    hasInput: true,
    logicalParent: '/agenda',
  ),
  '/agenda/aluno': FocuxSurfaceSpec(type: _s4, logicalParent: _alunoHome),
  '/financeiro': FocuxSurfaceSpec(type: _s1, logicalParent: _home),
  '/perfil': FocuxSurfaceSpec(type: _s2, logicalParent: _home),
  '/perfil/mfa': FocuxSurfaceSpec(
    type: _s5,
    hasInput: true,
    logicalParent: _perfil,
  ),
  '/configuracoes': FocuxSurfaceSpec(type: _s2, logicalParent: _home),
  '/perfil/editar': FocuxSurfaceSpec(
    type: _s5,
    hasInput: true,
    logicalParent: _perfil,
  ),
  '/perfil/wallet': FocuxSurfaceSpec(
    type: _s3,
    hasInput: true,
    logicalParent: _perfil,
  ),
  '/perfil/ferramentas': FocuxSurfaceSpec(type: _s2, logicalParent: _perfil),
  '/identidade-visual': FocuxSurfaceSpec(
    type: _s5,
    hasInput: true,
    logicalParent: _perfil,
  ),
  '/white-label': FocuxSurfaceSpec(
    type: _s5,
    hasInput: true,
    logicalParent: _perfil,
  ),
  '/perfil/white-label': FocuxSurfaceSpec(
    type: _s5,
    hasInput: true,
    logicalParent: _perfil,
  ),
  '/setup/identidade': FocuxSurfaceSpec(
    type: _s5,
    hasInput: true,
    logicalParent: _perfil,
  ),
  '/ia/chat': FocuxSurfaceSpec(type: _s1, logicalParent: '/ia/copiloto'),
  '/ia/aluno': FocuxSurfaceSpec(type: _s1, logicalParent: _alunoHome),
  '/ia/checkin': FocuxSurfaceSpec(type: _s1, logicalParent: '/ia/copiloto'),
  '/ia/progressao/aceitar': FocuxSurfaceSpec(
    type: _s5,
    logicalParent: '/ia/copiloto',
  ),
  '/chat/inbox': FocuxSurfaceSpec(
    type: _s4,
    hasInput: true,
    logicalParent: _home,
  ),
  '/chat/aluno': FocuxSurfaceSpec(type: _s1, logicalParent: _alunoHome),
  '/financeiro/aluno': FocuxSurfaceSpec(type: _s3, logicalParent: _alunoHome),
  '/financeiro/mensalidades/:id': FocuxSurfaceSpec(
    type: _s3,
    logicalParent: '/financeiro',
  ),
  '/feed': FocuxSurfaceSpec(
    type: _s4,
    hasInput: true,
    logicalParent: _home,
  ),
  '/feed/aluno': FocuxSurfaceSpec(type: _s4, logicalParent: _alunoHome),
  '/leads': FocuxSurfaceSpec(
    type: _s4,
    hasInput: true,
    logicalParent: _home,
  ),
  '/leads/kanban': FocuxSurfaceSpec(type: _s4, logicalParent: '/leads'),
  '/leads/novo': FocuxSurfaceSpec(
    type: _s5,
    hasInput: true,
    logicalParent: '/leads',
  ),
  '/leads/:id': FocuxSurfaceSpec(type: _s3, logicalParent: '/leads'),
  '/alertas': FocuxSurfaceSpec(
    type: _s4,
    hasInput: true,
    logicalParent: _home,
  ),
  '/alertas/aluno/:id': FocuxSurfaceSpec(type: _s3, logicalParent: '/alertas'),
  '/alertas/config': FocuxSurfaceSpec(
    type: _s5,
    hasInput: true,
    logicalParent: '/alertas',
  ),
  '/relatorios/global': FocuxSurfaceSpec(type: _s1, logicalParent: _home),
  '/convites': FocuxSurfaceSpec(type: _s4, logicalParent: _home),
  '/convite/:token': FocuxSurfaceSpec(
    type: _s6,
    hasInput: true,
    logicalParent: '/login',
  ),
  '/p/:slug': FocuxSurfaceSpec(
    type: _s6,
    hasInput: true,
    logicalParent: '/login',
  ),
  '/planos': FocuxSurfaceSpec(type: _s6, logicalParent: _perfil),
  '/paywall': FocuxSurfaceSpec(type: _s6, logicalParent: _home),
  '/assinatura': FocuxSurfaceSpec(type: _s6, logicalParent: _perfil),
  '/assinatura/review': FocuxSurfaceSpec(
    type: _s6,
    logicalParent: '/assinatura',
  ),
  '/assinatura/success': FocuxSurfaceSpec(type: _s6, logicalParent: _home),
  '/referral': FocuxSurfaceSpec(type: _s1, logicalParent: _perfil),
  '/retencao': FocuxSurfaceSpec(type: _s1, logicalParent: _home),
  '/ofertas-upsell': FocuxSurfaceSpec(
    type: _s6,
    hasInput: true,
    logicalParent: '/assinatura',
  ),
  '/cancel-save': FocuxSurfaceSpec(
    type: _s6,
    hasInput: true,
    logicalParent: '/assinatura',
  ),
  '/habitos': FocuxSurfaceSpec(type: _s4, logicalParent: _ferramentas),
  '/habitos/:id': FocuxSurfaceSpec(type: _s3, logicalParent: '/habitos'),
  '/automacoes': FocuxSurfaceSpec(
    type: _s4,
    hasInput: true,
    logicalParent: _ferramentas,
  ),
  '/desafios': FocuxSurfaceSpec(type: _s4, logicalParent: _ferramentas),
  '/desafios/:id': FocuxSurfaceSpec(type: _s3, logicalParent: '/desafios'),
  '/loja': FocuxSurfaceSpec(
    type: _s4,
    hasInput: true,
    logicalParent: _ferramentas,
  ),
  '/perfil/equipe': FocuxSurfaceSpec(
    type: _s4,
    hasInput: true,
    logicalParent: _perfil,
  ),
  '/pacotes': FocuxSurfaceSpec(
    type: _s4,
    hasInput: true,
    logicalParent: '/financeiro',
  ),
  '/ferramentas/hub/:itemId': FocuxSurfaceSpec(
    type: _s4,
    logicalParent: _home,
  ),
  '/leads-publicos': FocuxSurfaceSpec(
    type: _s4,
    hasInput: true,
    logicalParent: '/leads',
  ),
  '/perfil/landing-editor': FocuxSurfaceSpec(
    type: _s5,
    hasInput: true,
    logicalParent: _perfil,
  ),
  '/dunning': FocuxSurfaceSpec(type: _s1, logicalParent: '/financeiro'),
  '/winback': FocuxSurfaceSpec(
    type: _s1,
    hasInput: true,
    logicalParent: _home,
  ),
  '/relatorio/business': FocuxSurfaceSpec(type: _s1, logicalParent: _home),
  '/recorrencia': FocuxSurfaceSpec(
    type: _s4,
    hasInput: true,
    logicalParent: '/financeiro',
  ),
  '/nps': FocuxSurfaceSpec(type: _s1, logicalParent: _home),
  '/grupo-aulas': FocuxSurfaceSpec(type: _s4, logicalParent: _home),
  '/migracao-magica': FocuxSurfaceSpec(
    type: _s9,
    hasInput: true,
    logicalParent: _perfil,
  ),
  '/migracao-focux': FocuxSurfaceSpec(
    type: _s9,
    logicalParent: _perfil,
    redirectTo: '/migracao-magica',
  ),
  '/growth/migracao': FocuxSurfaceSpec(
    type: _s9,
    logicalParent: _perfil,
    redirectTo: '/migracao-magica',
  ),
  '/promo-enterprise': FocuxSurfaceSpec(type: _s6, logicalParent: '/planos'),
  '/ranking': FocuxSurfaceSpec(
    type: _s4,
    hasInput: true,
    logicalParent: _home,
  ),
  '/coach': FocuxSurfaceSpec(type: _s1, logicalParent: _home),
  '/notificacoes': FocuxSurfaceSpec(
    type: _s4,
    hasInput: true,
    logicalParent: _home,
  ),
  '/suporte': FocuxSurfaceSpec(
    type: _s4,
    hasInput: true,
    logicalParent: _perfil,
  ),
  '/broadcasts': FocuxSurfaceSpec(
    type: _s5,
    hasInput: true,
    logicalParent: _home,
  ),
  '/depoimentos-aluno': FocuxSurfaceSpec(
    type: _s5,
    hasInput: true,
    logicalParent: _alunoHome,
  ),
  '/depoimentos': FocuxSurfaceSpec(type: _s4, logicalParent: _ferramentas),
  '/galeria': FocuxSurfaceSpec(type: _s4, logicalParent: _home),
  '/feedback-videos': FocuxSurfaceSpec(
    type: _s4,
    hasInput: true,
    logicalParent: _home,
  ),
  '/busca': FocuxSurfaceSpec(type: _s4, hasInput: true, logicalParent: _home),
  '/analytics': FocuxSurfaceSpec(type: _s1, logicalParent: _home),
  '/admin/rbac': FocuxSurfaceSpec(type: _s2, logicalParent: _perfil),
  '/gamificacao': FocuxSurfaceSpec(type: _s1, logicalParent: _ferramentas),
  '/qa/smoke': FocuxSurfaceSpec(type: _s4, logicalParent: _home),
  '/qa/tokens-strip': FocuxSurfaceSpec(type: _s2, logicalParent: '/qa/smoke'),
};
