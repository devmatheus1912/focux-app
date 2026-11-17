import '../utils/prescricao_atalhos.dart';

/// Copy da sheet de prescrição — PT-BR.
const prescriptionObjetivo = 'Objetivo';
const prescriptionObjetivoSubtitle = 'Ajusta séries, reps e descanso.';
const prescriptionRepsLabel = 'Repetições';
const prescriptionRepsSubtitle = 'Faixa ou número alvo por série.';
const prescriptionAplicar = 'Aplicar';
const prescriptionPadrao = 'Prescrição padrão';
const prescriptionDoExercicio = 'Prescrição do exercício';
const prescriptionGroupHeader = 'Prescrição';
const prescriptionSeries = 'Séries';
const prescriptionDescanso = 'Descanso';
const prescriptionMaisDetalhes = 'Mais detalhes';
const prescriptionCarga = 'Carga (kg)';
const prescriptionOpcional = 'Opcional';
const prescriptionAddCarga = 'Adicionar carga (kg)';
const prescriptionRpe = 'RPE alvo das válidas';
const prescriptionAddRpe = 'Adicionar RPE alvo';
const prescriptionAddNotas = prescriptionDicaAluno;
const prescriptionFechar = 'Fechar';
const prescriptionMetodo = 'Método';
const prescriptionMetodoQuedas = 'Quedas';
const prescriptionMetodoReducao = 'Redução da carga';
const prescriptionMetodoPausa = 'Pausa entre mini-séries';
const prescriptionMetodoMiniSeries = 'Mini-séries';
const prescriptionMetodoProgressao = 'Progressão das válidas';
const prescriptionMetodoTecnica = 'Técnica';
const prescriptionMetodoSegurarNoPico = 'Segurar no pico';
const prescriptionMetodoDescerEm = 'Descer em';
const prescriptionMetodoPararPor = 'Parar no meio por';
const prescriptionMetodoParciais = 'Parciais no fim';
const prescriptionMetodoEmQuais = 'Em quais séries';
const prescriptionMetodoSoAUltima = 'Só a última';
const prescriptionMetodoTodasValidas = 'Todas as válidas';
const prescriptionMetodoEscolher = 'Escolher';
const prescriptionMaisDetalhesSubtitulo = 'Carga, RPE e dica para o aluno';
const prescriptionDicaAluno = 'Adicionar dica para o aluno';
const prescriptionSemCarga = 'Sem carga';
const prescriptionSemRpe = 'Sem';
const prescriptionOrientacoes = 'Orientações para o aluno';

/// Atalhos de descanso com o valor atual no lugar certo (nunca no fim da fila).
List<int> descansoComValorNoLugar(String bloco, int atual) {
  final itens = {...atalhosDescansoSeg(bloco), atual}.toList()..sort();
  return itens;
}

/// "Séries, repetições e descanso de: Agachamento, Leg press e mais 2".
String prescricaoAplicarAoBlocoTexto(List<String> nomes, int total) {
  if (nomes.isEmpty) {
    return total == 1
        ? 'Séries, repetições e descanso do outro exercício do bloco'
        : 'Séries, repetições e descanso dos outros $total do bloco';
  }
  final mostrados = nomes.take(2).join(', ');
  final resto = nomes.length - 2;
  return 'Séries, repetições e descanso de: $mostrados'
      '${resto > 0 ? ' e mais $resto' : ''}';
}
