import '../../subscription/utils/plano_ia_limits.dart';
import 'plano_recurso.dart';

/// Nome e venda de um recurso do plano. Benefícios dizem o que muda no dia do
/// personal e só listam o que o app faz hoje (conferido recurso por recurso
/// em 14/11/2026; ver PROJECT-MAP, "Textos de venda").
class PlanoRecursoTexto {
  const PlanoRecursoTexto({
    required this.nome,
    required this.frase,
    required this.beneficios,
  });

  /// Nome único do recurso em todas as telas ("Hábitos", "IA Focux").
  final String nome;

  /// Frase de ganho da folha e da tela de upgrade.
  final String frase;

  /// Sempre 3, curtos.
  final List<String> beneficios;
}

/// Fonte única de nome e texto de venda por recurso ([PlanoRecursoKeys]).
abstract final class PlanoRecursoTextos {
  /// Venda do limite de alunos (não é um recurso da matriz).
  static const limiteAlunos = 'limiteAlunos';

  static const porRecurso = <String, PlanoRecursoTexto>{
    PlanoRecursoKeys.ia: PlanoRecursoTexto(
      nome: 'IA Focux',
      frase: 'A IA Focux diz o que fazer com cada aluno',
      beneficios: [
        'Prioridade do dia pronta ao abrir o app',
        'Olha treinos, check-ins e faltas por você',
        'Sugere a mensagem e você envia num toque',
      ],
    ),
    PlanoRecursoKeys.financeiro: PlanoRecursoTexto(
      nome: 'Financeiro',
      frase: 'Cobre seus alunos sem correr atrás',
      beneficios: [
        'Cobrança por PIX direto no app',
        'Quem pagou, quem atrasou e o que vai entrar',
        'Histórico de pagamento de cada aluno',
      ],
    ),
    PlanoRecursoKeys.recorrencia: PlanoRecursoTexto(
      nome: 'Recorrência',
      frase: 'Mensalidade que se cobra sozinha',
      beneficios: [
        'Cobrança gerada todo mês, sem você lembrar',
        'O aluno paga por cartão ou PIX',
        'Menos mensalidade esquecida',
      ],
    ),
    PlanoRecursoKeys.carteira: PlanoRecursoTexto(
      nome: 'Chave PIX',
      frase: 'Receba dos alunos na sua chave PIX',
      beneficios: [
        'Pagamentos dos alunos na sua chave',
        'Usada nas cobranças do Financeiro',
        'Troca de chave confirmada no seu aparelho',
      ],
    ),
    PlanoRecursoKeys.relatorios: PlanoRecursoTexto(
      nome: 'Relatórios',
      frase: 'Saiba quem está treinando e quem está sumindo',
      beneficios: [
        'Aderência de cada aluno por período',
        'PDF da aderência para enviar',
        'Todos os alunos numa visão só',
      ],
    ),
    PlanoRecursoKeys.habitos: PlanoRecursoTexto(
      nome: 'Hábitos',
      frase: 'Acompanhe o aluno também fora do treino',
      beneficios: [
        'Água, sono e passos marcados pelo aluno',
        'Quem está em dia, numa lista',
        'Você escolhe a meta e os dias',
      ],
    ),
    PlanoRecursoKeys.feedbackVideo: PlanoRecursoTexto(
      nome: 'Feedback em vídeo',
      frase: 'Corrija a execução pelo vídeo do aluno',
      beneficios: [
        'O aluno grava e envia pelo app',
        'Sua correção fica junto do vídeo',
        'Menos dúvida entre uma aula e outra',
      ],
    ),
    PlanoRecursoKeys.leads: PlanoRecursoTexto(
      nome: 'Interessados',
      frase: 'Não perca quem pediu informação',
      beneficios: [
        'Todos os interessados num lugar',
        'Quem chegou pela sua página',
        'Vire aluno com um toque',
      ],
    ),
    PlanoRecursoKeys.importacaoFoto: PlanoRecursoTexto(
      nome: 'Importar por foto',
      frase: 'Traga seus alunos com uma foto',
      beneficios: [
        'Foto ou print da sua lista vira cadastro',
        'Sem digitar aluno por aluno',
        'Mais importações por mês',
      ],
    ),
    PlanoRecursoKeys.comunidadePrivada: PlanoRecursoTexto(
      nome: 'Comunidade',
      frase: 'Um grupo só dos seus alunos',
      beneficios: [
        'Grupos com os seus alunos',
        'Posts seus e dos alunos',
        'Você bloqueia e revê denúncias',
      ],
    ),
    PlanoRecursoKeys.whiteLabel: PlanoRecursoTexto(
      nome: 'Marca própria',
      frase: 'O app do aluno com a sua marca',
      beneficios: [
        'Sua cor e seu logo no app do aluno',
        'Capa com a sua cara na Hoje dele',
        'O aluno vê você, não o Focux',
      ],
    ),
    PlanoRecursoKeys.landing: PlanoRecursoTexto(
      nome: 'Página completa',
      frase: 'Sua página de vendas completa',
      beneficios: [
        'Depoimentos, fotos e perguntas frequentes',
        'Formulário que vira interessado',
        'Um link para divulgar',
      ],
    ),
    PlanoRecursoKeys.loja: PlanoRecursoTexto(
      nome: 'Vendas',
      frase: 'Venda seus planos com PIX',
      beneficios: [
        'Planos com preço na sua página',
        'O cliente paga por PIX',
        'Pagou, virou aluno',
      ],
    ),
    PlanoRecursoKeys.automacoes: PlanoRecursoTexto(
      nome: 'Automações',
      frase: 'Mensagens que saem na hora certa',
      beneficios: [
        'Boas-vindas para aluno novo',
        'Recado para quem sumiu',
        'Você escreve uma vez',
      ],
    ),
    PlanoRecursoKeys.winback: PlanoRecursoTexto(
      nome: 'Retomada',
      frase: 'Traga de volta quem parou de treinar',
      beneficios: [
        'Recado para quem sumiu',
        'Sai sozinho, na hora certa',
        'Aparece na linha do tempo do aluno',
      ],
    ),
    PlanoRecursoKeys.desafios: PlanoRecursoTexto(
      nome: 'Desafios',
      frase: 'Desafios com ranking entre os alunos',
      beneficios: [
        'Desafio com prazo e meta de pontos',
        'Ranking que o aluno acompanha',
        'Mais motivo para treinar',
      ],
    ),
    PlanoRecursoKeys.equipe: PlanoRecursoTexto(
      nome: 'Equipe',
      frase: 'Divida o trabalho com sua equipe',
      beneficios: [
        'Co-personal e secretária com acesso próprio',
        'Cada um vê só o que precisa',
        'Tudo no mesmo app',
      ],
    ),
    PlanoRecursoKeys.nfse: PlanoRecursoTexto(
      nome: 'Nota fiscal',
      frase: 'Nota fiscal sem sair do app',
      beneficios: [
        'Nota emitida quando a mensalidade é paga',
        'Sem entrar no site da prefeitura',
        'Nota que falhou é emitida de novo sozinha',
      ],
    ),
    PlanoRecursoKeys.agenda: PlanoRecursoTexto(
      nome: 'Agenda',
      frase: 'Seus horários num lugar só',
      beneficios: [
        'Aulas do dia na sua Hoje',
        'O aluno confere o horário dele',
        'Remarcar em poucos toques',
      ],
    ),
  };

  static const _limiteAlunos = PlanoRecursoTexto(
    nome: 'Mais vagas de alunos',
    frase: 'Você chegou ao limite de alunos',
    beneficios: [
      'Até ${PlanoAlunosLimits.pro} alunos no Pro',
      'Sem limite no Enterprise',
      'Seus alunos de hoje continuam iguais',
    ],
  );

  /// Texto pela capability (legada ou chave nova); `alunos` é o limite.
  static PlanoRecursoTexto? de(String? capability) {
    if (capability == 'alunos' || capability == limiteAlunos) {
      return _limiteAlunos;
    }
    final chave = PlanoRecursoKeys.fromCapability(capability);
    return chave == null ? null : porRecurso[chave];
  }

  /// Nome do recurso; [fallback] para capability desconhecida.
  static String nome(String? capability, {required String fallback}) =>
      de(capability)?.nome ?? fallback;
}
