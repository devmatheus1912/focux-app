import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/monetizacao/data/cancel_save_repository.dart';
import 'package:focux_app/features/monetizacao/screens/cancel_save_screen.dart';

import '../../support/screen_source_bundle.dart';

class _FakeRepo implements CancelSaveRepository {
  _FakeRepo(this.resposta);

  final CancelSaveOferta resposta;

  @override
  Future<CancelSaveOferta> oferta(String motivo) async => resposta;

  @override
  Future<CancelSaveResposta> responder({
    required String motivo,
    required String ofertaApresentada,
    required bool aceitar,
    String? feedback,
  }) async => CancelSaveResposta(aceita: aceitar, mensagem: 'ok');
}

void main() {
  test('oferta sem troca na loja não tem botão de aceitar', () {
    final oferta = CancelSaveOferta.fromJson({
      'tipo': 'NENHUMA',
      'titulo': 'Seu plano segue até 10/11/2026',
      'descricao': 'Ao desativar a renovação na App Store…',
      'ctaLabel': null,
      'billingChannel': 'NATIVE_STORE',
      'requiresStoreAction': false,
      'cancelLabel': 'Cancelar na App Store',
    });

    expect(oferta.temOferta, isFalse);
    expect(oferta.cancelLabel, 'Cancelar na App Store');
  });

  test('backend antigo sem cancelLabel mantém o texto padrão', () {
    final oferta = CancelSaveOferta.fromJson({
      'tipo': 'DISCOUNT_20',
      'titulo': '20% off por 3 meses',
      'descricao': '…',
      'ctaLabel': 'Aceitar desconto',
    });

    expect(oferta.temOferta, isTrue);
    expect(oferta.cancelLabel, 'Cancelar mesmo assim');
  });

  test('título do resultado avisa quando falta concluir na loja', () {
    expect(
      cancelSaveResultadoTitulo(
        CancelSaveResposta(aceita: false, mensagem: '', requiresStoreAction: true),
      ),
      'Falta um passo',
    );
    expect(
      cancelSaveResultadoTitulo(CancelSaveResposta(aceita: false, mensagem: '')),
      'Cancelamento registrado',
    );
    expect(
      cancelSaveResultadoTitulo(CancelSaveResposta(aceita: true, mensagem: '')),
      'Oferta registrada',
    );
  });

  testWidgets('sem troca possível, o padrão é manter o plano', (tester) async {
    final oferta = CancelSaveOferta(
      tipo: 'NENHUMA',
      titulo: 'Seu plano segue até 10/11/2026',
      descricao: 'Ao desativar a renovação na App Store, você mantém tudo.',
      ctaLabel: null,
      billingChannel: 'NATIVE_STORE',
      requiresStoreAction: false,
      cancelLabel: 'Cancelar na App Store',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cancelSaveRepositoryProvider.overrideWithValue(_FakeRepo(oferta)),
        ],
        child: const MaterialApp(home: CancelSaveScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Outro motivo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Seu plano segue até 10/11/2026'), findsOneWidget);
    expect(find.text('Manter meu plano'), findsOneWidget);
    expect(
      find.textContaining('Cancelar na App Store', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Cancelar mesmo assim', findRichText: true),
      findsNothing,
    );
  });

  test('cancelar abre a loja quando o backend pede', () {
    final screen = readScreenSourceBundle(
      'lib/features/monetizacao/screens/cancel_save_screen.dart',
    );
    expect(screen, contains('resposta.requiresStoreAction ||'));
    expect(screen, contains('openNativeSubscriptionManagement()'));
    expect(screen, isNot(contains("'Conclusão ")));
  });

  test('sucesso da assinatura não usa animação de demonstração', () {
    final screen = readScreenSourceBundle(
      'lib/features/assinatura/screens/assinatura_success_screen.dart',
    );
    expect(screen, isNot(contains('FxRivePlayer')));
    expect(screen, contains('_SuccessBadge'));
  });
}
