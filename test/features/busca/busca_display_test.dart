import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/busca/models/busca_global_models.dart';
import 'package:focux_app/features/busca/utils/busca_display.dart';

void main() {
  test('buscaCountLabel', () {
    expect(buscaCountLabel(0), 'Nenhum resultado');
    expect(buscaCountLabel(1), '1 resultado');
    expect(buscaCountLabel(3), '3 resultados');
  });

  test('buscaCountInFilterLabel', () {
    expect(buscaCountInFilterLabel(0, 'Alunos'), 'Nenhum resultado em Alunos');
    expect(buscaCountInFilterLabel(1, 'Treinos'), '1 resultado em Treinos');
    expect(buscaCountInFilterLabel(4, 'Cobranças'), '4 resultados em Cobranças');
  });

  test('buscaNormalizePath colapsa barras', () {
    expect(buscaNormalizePath('/alunos//12'), '/alunos/12');
  });

  test('buscaInternalPathAllowed', () {
    expect(buscaInternalPathAllowed('/alunos/1'), isTrue);
    expect(buscaInternalPathAllowed('/admin/rbac'), isFalse);
  });

  test('buscaIsHttpUrl', () {
    expect(buscaIsHttpUrl(Uri.parse('https://focux.app')), isTrue);
    expect(buscaIsHttpUrl(Uri.parse('javascript:alert(1)')), isFalse);
  });

  test('buscaFilterByTipo', () {
    const result = BuscaGlobalResult(
      alunos: [
        BuscaItem(id: 1, titulo: 'Ana', tipo: 'ALUNO', url: '/alunos/1'),
      ],
      treinos: [
        BuscaItem(id: 2, titulo: 'A', tipo: 'TREINO', url: '/treinos/2'),
      ],
      cobrancas: [],
    );
    expect(buscaFilterByTipo(result, BuscaTipo.aluno), hasLength(1));
    expect(buscaFilterByTipo(result, BuscaTipo.todos), hasLength(2));
  });

  test('BuscaItem.fromJson aceita url ou link e ignora email', () {
    final viaUrl = BuscaItem.fromJson({
      'id': 9,
      'titulo': 'Ana',
      'subtitulo': 'Hipertrofia',
      'tipo': 'ALUNO',
      'url': '/alunos/9',
      'email': 'ana@x.com',
    });
    expect(viaUrl.url, '/alunos/9');
    expect(viaUrl.subtitulo, 'Hipertrofia');

    final viaLink = BuscaItem.fromJson({
      'id': 9,
      'titulo': 'Ana',
      'tipo': 'ALUNO',
      'link': '/alunos/9',
    });
    expect(viaLink.url, '/alunos/9');
    expect(viaLink.subtitulo, isNull);
  });
}
