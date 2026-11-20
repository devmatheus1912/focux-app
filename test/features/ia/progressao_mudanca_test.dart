import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/models/progressao_sugestao.dart';
import 'package:focux_app/features/ia/utils/progressao_copy.dart';

/// SPEC Revisar cargas (20/11/2026): carga nova e troca de repetições contam
/// como mudança; antes só a variação de kg contava e a revisão travava.
void main() {
  ProgressaoSugestao s({
    required String atual,
    required String sugerida,
    double? anterior,
    double? sugeridaKg,
    double? delta,
  }) => ProgressaoSugestao(
    id: 1,
    alunoId: 1,
    exercicio: 'Crucifixo',
    cargaAtual: atual,
    cargaSugerida: sugerida,
    cargaAnteriorKg: anterior,
    cargaSugeridaKg: sugeridaKg,
    deltaKg: delta,
  );

  test('partes: só prescrição, carga e prescrição, vazio', () {
    expect(progressaoPartes('4×8-12'), (carga: '', prescricao: '4×8-12'));
    expect(
      progressaoPartes('17 kg · 4×8-10'),
      (carga: '17 kg', prescricao: '4×8-10'),
    );
    expect(progressaoPartes('80kg 4x20'), (carga: '80kg', prescricao: '4x20'));
    expect(progressaoPartes('—'), (carga: '', prescricao: ''));
  });

  test('ficha sem carga recebendo carga é carga nova (o caso do print)', () {
    final x = s(atual: '4×8-12', sugerida: '17 kg · 4×8-10', sugeridaKg: 17);
    expect(progressaoMudanca(x), ProgressaoMudanca.cargaNova);
    expect(progressaoMuda(x), isTrue);
  });

  test('kg sobe e desce pela carga anterior, sem depender do delta', () {
    final sobe = s(
      atual: '18 kg · 4×8-10',
      sugerida: '20 kg · 4×8-10',
      anterior: 18,
      sugeridaKg: 20,
    );
    expect(progressaoMudanca(sobe), ProgressaoMudanca.sobe);
    expect(progressaoDiferenca(sobe, null), '+2 kg');
    expect(progressaoMudanca(sobe, editada: 16), ProgressaoMudanca.desce);
  });

  test('só repetições muda; tudo igual não', () {
    final reps = s(
      atual: '20 kg · 4×8-12',
      sugerida: '20 kg · 4×8-10',
      anterior: 20,
      sugeridaKg: 20,
    );
    expect(progressaoMudanca(reps), ProgressaoMudanca.prescricao);
    final igual = s(
      atual: '20 kg · 4×8-10',
      sugerida: '20 kg · 4×8-10',
      anterior: 20,
      sugeridaKg: 20,
    );
    expect(progressaoMudanca(igual), ProgressaoMudanca.nenhuma);
  });

  test('editar a carga de uma linha igual vira mudança', () {
    final igual = s(
      atual: '20 kg · 4×8-10',
      sugerida: '20 kg · 4×8-10',
      anterior: 20,
      sugeridaKg: 20,
    );
    expect(progressaoMuda(igual), isFalse);
    expect(progressaoMuda(igual, editada: 22.5), isTrue);
  });

  test('sugestão antiga sem carga anterior segue pelo delta', () {
    final x = s(
      atual: '80kg 4x20',
      sugerida: '82,5kg 4x18-20',
      sugeridaKg: 82.5,
      delta: 2.5,
    );
    expect(progressaoMudanca(x), ProgressaoMudanca.sobe);
  });

  test('json lê a carga anterior', () {
    final x = ProgressaoSugestao.fromApi({
      'id': 1,
      'alunoId': 2,
      'exercicio': 'Supino',
      'cargaAtual': '4×8-12',
      'cargaSugerida': '17 kg · 4×8-10',
      'cargaAnteriorKg': null,
      'cargaSugeridaKg': 17,
    });
    expect(x.cargaAnteriorKg, isNull);
    expect(progressaoMudanca(x), ProgressaoMudanca.cargaNova);
  });
}
