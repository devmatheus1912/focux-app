import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/utils/checkin_descanso_relogio.dart';

/// Fim do descanso com a tela bloqueada (SPEC-notificacoes): o relógio diz
/// quando agendar, reagendar ou cancelar o aviso.
void main() {
  late DateTime agora;
  late List<DateTime?> fins;
  late bool primeiroPlano;

  CheckinDescansoRelogio novo() => CheckinDescansoRelogio(
    agora: () => agora,
    onTick: () {},
    onFim: () {},
    aoMudarFim: fins.add,
    emPrimeiroPlano: () => primeiroPlano,
  );

  setUp(() {
    agora = DateTime(2026, 11, 20, 10);
    fins = [];
    primeiroPlano = true;
  });

  test('iniciar agenda para o fim; ±15 s reagenda', () {
    final r = novo();
    r.iniciar(60);
    expect(fins.single, agora.add(const Duration(seconds: 60)));
    r.ajustar(15);
    expect(fins.last, agora.add(const Duration(seconds: 75)));
    r.dispose();
  });

  test('pular cancela', () {
    final r = novo();
    r.iniciar(60);
    r.parar();
    expect(fins.last, isNull);
    r.dispose();
  });

  test('tirar além do que resta encerra e cancela', () {
    final r = novo();
    r.iniciar(20);
    r.ajustar(-30);
    expect(r.ativo, isFalse);
    expect(fins.last, isNull);
    r.dispose();
  });

  test(
    'fim com o app aberto cancela (vale o bipe); em segundo plano o aviso fica',
    () {
      fakeAsync((async) {
        final r = novo();
        r.iniciar(15);
        agora = agora.add(const Duration(seconds: 16));
        async.elapse(const Duration(seconds: 1));
        expect(r.ativo, isFalse);
        expect(fins.last, isNull);
        r.dispose();
      });
      fakeAsync((async) {
        fins.clear();
        primeiroPlano = false;
        final r = novo();
        r.iniciar(15);
        agora = agora.add(const Duration(seconds: 16));
        async.elapse(const Duration(seconds: 1));
        expect(r.ativo, isFalse);
        expect(fins, hasLength(1), reason: 'não cancelou o aviso agendado');
        expect(fins.single, isNotNull);
        r.dispose();
      });
    },
  );

  test('voltar ao app depois do fim limpa o aviso entregue', () {
    final r = novo();
    r.iniciar(15);
    agora = agora.add(const Duration(seconds: 30));
    r.sincronizar();
    expect(fins.last, isNull);
    r.dispose();
  });
}
