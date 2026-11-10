import '../data/automacao_repository.dart';

String automacaoTriggerLabel(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'NOVO_ALUNO':
    case 'ALUNO_CRIADO':
      return 'Novo aluno';
    case 'DIAS_SEM_CHECKIN':
      return '4 dias sem treinar';
    case 'ALUNO_VIA_LEAD':
      return 'Interessado virou aluno';
    case 'RECORDE_PESSOAL':
      return 'Novo recorde';
    default:
      final t = raw.trim();
      return t.isEmpty ? 'Gatilho' : t;
  }
}

String automacaoLogStatusLabel(String status) {
  switch (status.trim().toUpperCase()) {
    case 'ATIVO':
      return 'Em andamento';
    case 'CONCLUIDO':
    case 'CONCLUÍDO':
      return 'Concluído';
    case 'PAUSADO':
      return 'Pausado';
    case 'ERRO':
      return 'Falhou';
    case 'CANCELADO':
      return 'Cancelado';
    default:
      final t = status.trim();
      return t.isEmpty ? 'Sem status' : t;
  }
}

String automacaoFluxoStatusLabel({required bool ativo}) =>
    ativo ? 'Ativo' : 'Pausado';

String automacaoLogSubtitle({
  required String status,
  required int passoAtual,
  int entregasOk = 0,
  int entregasFalha = 0,
}) {
  final passo = passoAtual < 0 ? 1 : passoAtual + 1;
  return [
    '${automacaoLogStatusLabel(status)} · passo $passo',
    if (entregasOk > 0) entregasOk == 1 ? '1 enviada' : '$entregasOk enviadas',
    if (entregasFalha > 0)
      entregasFalha == 1 ? '1 falhou' : '$entregasFalha falharam',
  ].join(' · ');
}

bool automacaoLogComProblema({
  required String status,
  required int entregasFalha,
}) => status.trim().toUpperCase() == 'ERRO' || entregasFalha > 0;

String automacaoAtivarTitle(String nome) => 'Ligar “$nome”?';

/// Nome mostrado: o do catálogo atual pelo id (fluxos antigos guardaram o
/// nome velho, como "Onboarding 7 dias").
String automacaoNome({String? templateId, required String nomeGravado}) =>
    switch (templateId) {
      'ONBOARDING_7D' => 'Boas-vindas',
      'REATIVACAO_4D' => 'Volta aos treinos',
      'FOLLOWUP_LEAD' => 'Boas-vindas do interessado',
      'UPSELL_PRO' => 'Recorde',
      _ => nomeGravado,
    };

String _quando(int minutosDesdeInicio) {
  if (minutosDesdeInicio <= 0) return 'Na hora';
  final horas = minutosDesdeInicio ~/ 60;
  if (horas < 24) return horas == 1 ? '1 hora depois' : '$horas horas depois';
  final dias = horas ~/ 24;
  return dias == 1 ? '1 dia depois' : '$dias dias depois';
}

/// Cada envio do modelo, com quando sai e o texto: o que o personal confere
/// antes de ligar. Espera não vira linha (só soma no tempo).
List<String> automacaoPassosLinhas(List<AutomacaoPassoDef> passos) {
  var minutos = 0;
  final linhas = <String>[];
  for (final p in passos) {
    minutos += p.delayMinutos;
    switch (p.acaoTipo.toUpperCase()) {
      case 'WAIT':
        continue;
      case 'PUSH':
        final titulo = '${p.config['titulo'] ?? ''}'.trim();
        final corpo = '${p.config['corpo'] ?? ''}'.trim();
        final texto = [titulo, corpo].where((s) => s.isNotEmpty).join(' ');
        linhas.add('${_quando(minutos)}: aviso “$texto”');
      case 'CHAT_TEMPLATE':
        final msg = '${p.config['mensagem'] ?? ''}'.trim();
        linhas.add(
          '${_quando(minutos)}: mensagem no chat, em seu nome: “$msg”',
        );
      default:
        linhas.add('${_quando(minutos)}: ${p.acaoTipo.toLowerCase()}');
    }
  }
  return linhas;
}

/// "3 avisos e 1 mensagem em 7 dias".
String automacaoResumoPassos(List<AutomacaoPassoDef> passos) {
  var avisos = 0;
  var mensagens = 0;
  var minutos = 0;
  for (final p in passos) {
    minutos += p.delayMinutos;
    switch (p.acaoTipo.toUpperCase()) {
      case 'PUSH':
        avisos++;
      case 'CHAT_TEMPLATE':
        mensagens++;
    }
  }
  final partes = [
    if (avisos > 0) avisos == 1 ? '1 aviso' : '$avisos avisos',
    if (mensagens > 0) mensagens == 1 ? '1 mensagem' : '$mensagens mensagens',
  ];
  if (partes.isEmpty) return 'Sem envios';
  final dias = (minutos / 1440).ceil();
  final prazo = dias <= 1 ? '' : ' em $dias dias';
  return '${partes.join(' e ')}$prazo';
}

/// Linha ligada: "Ligada", "Ligada · 1 aluno em andamento", "Ligada · 3 alunos em andamento".
String automacaoLigadaLabel(int? emAndamento) => switch (emAndamento) {
  null || 0 => 'Ligada',
  1 => 'Ligada · 1 aluno em andamento',
  final n => 'Ligada · $n alunos em andamento',
};

/// Cabeçalho: "1 de 4 ligadas".
String automacaoLigadasLabel({required int ligadas, required int total}) =>
    total == 0 ? 'Nenhuma automação' : '$ligadas de $total ligadas';

String automacaoIniciarLabel() => 'Iniciar para um aluno';

String automacaoIniciarPickerTitle() => 'Aluno';

String automacaoIniciarConfirmTitle(String nome) => 'Iniciar para $nome?';

String automacaoIniciarConfirmMessage() => 'O fluxo começa agora neste aluno.';

String automacaoIniciarSuccess() => 'Fluxo iniciado';

String automacaoSemAlunos() => 'Cadastre um aluno para iniciar o fluxo.';

String automacaoPausarLabel() => 'Pausar fluxo';

String automacaoRetomarLabel() => 'Retomar fluxo';

String automacaoPausarConfirmTitle(String nome) => 'Pausar “$nome”?';

String automacaoPausarConfirmMessage() =>
    'O gatilho para de disparar e quem está no meio do fluxo espera até você retomar.';

String automacaoRetomarConfirmTitle(String nome) => 'Retomar “$nome”?';

String automacaoRetomarConfirmMessage() =>
    'Quem estava no meio do fluxo continua de onde parou, e novos alunos voltam a entrar.';

String automacaoPausarSuccess() => 'Fluxo pausado';

String automacaoRetomarSuccess() => 'Fluxo retomado';
