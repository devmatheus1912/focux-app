import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/utils/progressao_copy.dart';

/// SPEC Ajustar cargas v2 (10/11/2026): atalhos viram sinais e a revisão mostra
/// só o que muda.
void main() {
  test('atalhos do pedido viram sinais da API, não texto no campo', () {
    expect(ProgressaoSinal.values.map((s) => s.api), [
      'SEMANA_LEVE',
      'DOR',
      'POUCO_TEMPO',
    ]);
    final card = File(
      'lib/features/ia/widgets/ia_progressao_pedido_card.dart',
    ).readAsStringSync();
    expect(card, isNot(contains('observacoes.text =')));
    expect(card, contains('FxChoiceChip'));
    expect(progressaoObservacoesHint, isNot(contains('deload')));
  });

  test('revisão: fica igual fechado e sem caixa; marcar é ação, não navegação', () {
    final tela = File(
      'lib/features/ia/screens/progressao_aceitar_screen.dart',
    ).readAsStringSync();
    expect(tela, contains('initiallyExpanded: false'));
    expect(tela, contains('mudanca: progressaoMudanca(s, editada: _cargas[s.id])'));
    expect(tela, contains('cargasMarcarAsN'));
    expect(tela, isNot(contains('FxActionLink(')));
    expect(tela, contains('cargasParaRevisar(mudancas.length - mantem)'));
  });
}
