import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/models/treino_previa.dart';
import 'package:focux_app/features/checkin/utils/treino_previa_view.dart';
import 'package:focux_app/l10n/app_localizations_pt.dart';

final _now = DateTime(2026, 9, 27, 18);
final _s = SPt();

ExecucaoTreino _ficha(int id, {String status = 'DISPONIVEL', int count = 5}) =>
    ExecucaoTreino.fromJson({
      'treinoId': id,
      'treinoNome': 'Treino $id',
      'status': status,
      'exercicios': [],
      'exerciciosCount': count,
    });

ExecucaoTreino _concluida(int treinoId, DateTime quando) =>
    ExecucaoTreino.fromHistoricoResumoJson({
      'id': 50 + treinoId,
      'treinoId': treinoId,
      'treinoNome': 'Treino $treinoId',
      'status': 'CONCLUIDO',
      'iniciadoEm':
          quando.subtract(const Duration(minutes: 45)).toIso8601String(),
      'concluidoEm': quando.toIso8601String(),
    });

TreinoPreviaSituacao? _situacao(
  int treinoId,
  List<ExecucaoTreino> treinos, {
  List<ExecucaoTreino> historico = const [],
}) => treinoPreviaSituacao(
  treinoId: treinoId,
  treinos: treinos,
  historico: historico,
  now: _now,
);

void main() {
  group('treinoPreviaSituacao', () {
    test('ficha fora da Home: null, rodapé só com Iniciar', () {
      expect(_situacao(9, [_ficha(1)]), isNull);
      expect(treinoPreviaMostraJaFiz(null), isFalse);
    });

    test('livre e não feita hoje: disponível, com Já fiz', () {
      final s = _situacao(1, [_ficha(1), _ficha(2)]);
      expect(s, TreinoPreviaSituacao.disponivel);
      expect(treinoPreviaMostraJaFiz(s), isTrue);
    });

    test('sessão aberta desta ficha vence tudo', () {
      expect(
        _situacao(
          1,
          [_ficha(1, status: 'EM_ANDAMENTO')],
          historico: [_concluida(1, _now.subtract(const Duration(hours: 2)))],
        ),
        TreinoPreviaSituacao.emAndamento,
      );
    });

    test('sem exercícios: em preparação', () {
      expect(
        _situacao(1, [_ficha(1, status: 'AGUARDANDO_LIBERACAO', count: 0)]),
        TreinoPreviaSituacao.emPreparacao,
      );
    });

    test('outra ficha com sessão aberta: sem Já fiz', () {
      final s = _situacao(1, [_ficha(1), _ficha(2, status: 'EM_ANDAMENTO')]);
      expect(s, TreinoPreviaSituacao.outraSessaoAberta);
      expect(treinoPreviaMostraJaFiz(s), isFalse);
    });

    test('feita hoje: concluído; feita ontem: disponível', () {
      expect(
        _situacao(
          1,
          [_ficha(1)],
          historico: [_concluida(1, _now.subtract(const Duration(hours: 2)))],
        ),
        TreinoPreviaSituacao.concluidoHoje,
      );
      expect(
        _situacao(
          1,
          [_ficha(1)],
          historico: [_concluida(1, _now.subtract(const Duration(days: 1)))],
        ),
        TreinoPreviaSituacao.disponivel,
      );
    });
  });

  group('treinoPreviaPrescricao', () {
    test('só o que o personal prescreveu', () {
      expect(
        treinoPreviaPrescricao(
          _s,
          const TreinoPreviaExercicio(
            treinoExercicioId: 1,
            exercicioNome: 'Supino',
            series: 4,
            repeticoes: '8',
            cargaKg: 32.5,
            descansoSegundos: 90,
          ),
        ),
        '4 × 8 · 32,5 kg · descanso 90 s',
      );
      expect(
        treinoPreviaPrescricao(
          _s,
          const TreinoPreviaExercicio(
            treinoExercicioId: 2,
            exercicioNome: 'Prancha',
            cargaKg: 0,
            descansoSegundos: 0,
          ),
        ),
        isEmpty,
      );
    });

    test('cabeçalho conta exercícios da prévia', () {
      expect(
        treinoPreviaCabecalho(
          _s,
          const TreinoPrevia(
            treinoId: 1,
            treinoNome: 'Treino A',
            exercicios: [
              TreinoPreviaExercicio(treinoExercicioId: 1, exercicioNome: 'A'),
            ],
          ),
          hoje: _now,
        ),
        '1 exercício',
      );
    });
  });
}
