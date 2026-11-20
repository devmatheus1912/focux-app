import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/exercicios/utils/exercicios_aba_display.dart';

Exercicio _ex({String? videoSource, String? videoUrl, bool curado = false}) =>
    Exercicio(
      id: 1,
      nome: 'Supino',
      videoSource: videoSource,
      videoUrl: videoUrl,
      curado: curado,
    );

void main() {
  group('topo da aba Exercícios', () {
    test('sem filtro: seus e da biblioteca, nunca modelos', () {
      expect(
        exerciciosResumoTopo(
          meus: 3,
          biblioteca: 492,
          filtrando: false,
          totalFiltrado: 3,
        ),
        '3 seus · 492 da biblioteca',
      );
      expect(
        exerciciosResumoTopo(
          meus: 1,
          biblioteca: 0,
          filtrando: false,
          totalFiltrado: 1,
        ),
        '1 seu · 0 da biblioteca',
      );
    });

    test('com busca ou filtro: quantos sobraram', () {
      expect(
        exerciciosResumoTopo(
          meus: 3,
          biblioteca: 492,
          filtrando: true,
          totalFiltrado: 12,
        ),
        '12 exercícios',
      );
      expect(
        exerciciosResumoTopo(
          meus: null,
          biblioteca: null,
          filtrando: true,
          totalFiltrado: 1,
        ),
        '1 exercício',
      );
    });

    test('contagem ainda não carregada não inventa número', () {
      expect(
        exerciciosResumoTopo(
          meus: null,
          biblioteca: 10,
          filtrando: false,
          totalFiltrado: 0,
        ),
        isNull,
      );
    });

    test('abas viram o parâmetro do servidor', () {
      expect(exerciciosAbaParam(ExerciciosAba.meus), 'MEUS');
      expect(exerciciosAbaParam(ExerciciosAba.biblioteca), 'FOCUX');
      expect(exerciciosAbaParam(ExerciciosAba.favoritos), isNull);
    });
  });

  group('"⋯" do exercício', () {
    test('do personal: vídeo, editar, duplicar e excluir', () {
      final e = _ex(
        videoSource: 'PERSONAL_UPLOAD',
        videoUrl: 'https://x/v.mp4',
      );
      expect(exercicioAcoesDisponiveis(e), [
        ExercicioAcao.assistir,
        ExercicioAcao.video,
        ExercicioAcao.editar,
        ExercicioAcao.duplicar,
        ExercicioAcao.excluir,
      ]);
      expect(exercicioAcaoRotulo(ExercicioAcao.video, e), 'Trocar vídeo');
      expect(exercicioAcaoRotulo(ExercicioAcao.duplicar, e), 'Duplicar');
    });

    test('da biblioteca intocado: só assiste e cria o seu', () {
      final e = _ex(
        videoSource: 'FOCUX_LIBRARY',
        videoUrl: 'https://x/v.mp4',
        curado: true,
      );
      expect(exercicioAcoesDisponiveis(e), [
        ExercicioAcao.assistir,
        ExercicioAcao.duplicar,
      ]);
      expect(
        exercicioAcaoRotulo(ExercicioAcao.duplicar, e),
        'Criar o meu a partir deste',
      );
    });

    test('excluir diz o efeito: com fichas bloqueia com a contagem', () {
      expect(exercicioExcluirTitulo(0), 'Excluir exercício?');
      expect(
        exercicioExcluirMensagem(0),
        'Sai da sua lista. Nenhuma ficha usa este exercício.',
      );
      expect(exercicioExcluirTitulo(2), 'Este exercício está em uso');
      expect(
        exercicioExcluirMensagem(1),
        'Está em 1 ficha. Tire da ficha antes de excluir.',
      );
      expect(
        exercicioExcluirMensagem(3),
        'Está em 3 fichas. Tire das fichas antes de excluir.',
      );
    });
  });
}
