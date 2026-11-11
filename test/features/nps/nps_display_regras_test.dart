import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/nps/utils/nps_display.dart';

void main() {
  test('menos de 5 respostas: sem NPS, mostra quanto falta', () {
    expect(npsBasePequena(1), isTrue);
    expect(npsBasePequena(5), isFalse);
    expect(npsFaltamTexto(1), startsWith('Faltam 4.'));
    expect(npsFaltamTexto(4), startsWith('Falta 1.'));
  });

  test('NPS inteiro, com sinal de menos tipográfico', () {
    expect(npsScoreTexto(100), '100');
    expect(npsScoreTexto(-20.4), '−20');
  });

  test('plurais e textos do topo', () {
    expect(npsRespostasLabel(1), '1 resposta');
    expect(npsRespostasLabel(3), '3 respostas');
    expect(npsTituloTopo(0), 'Nenhum detrator');
    expect(npsTituloTopo(1), '1 detrator para contato');
    expect(npsTituloTopo(2), '2 detratores para contato');
    expect(npsMediaTexto(10), '10');
    expect(npsMediaTexto(8.46), '8,5');
  });

  test('filtros só com mais de 3 respostas; classe pela nota', () {
    expect(npsMostraFiltros(3), isFalse);
    expect(npsMostraFiltros(4), isTrue);
    expect(npsClasseDe(9), NpsClasse.promotor);
    expect(npsClasseDe(7), NpsClasse.neutro);
    expect(npsClasseDe(6), NpsClasse.detrator);
  });
}
