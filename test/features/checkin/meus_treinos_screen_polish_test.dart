import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'aba Treinos: só o agregado da Home, um destaque e fold antigo fora',
    () {
      final screen =
          File(
            'lib/features/checkin/screens/meus_treinos_screen.dart',
          ).readAsStringSync();
      final destaque =
          File(
            'lib/features/checkin/widgets/treinos_destaque_card.dart',
          ).readAsStringSync();

      expect(screen, contains('alunoDashboardHomeProvider'));
      expect(screen, contains('buildTreinosHubView'));
      expect(screen, contains('fxScreenA11yScope'));
      expect(screen, contains('FxAsyncBody<AlunoDashboardHomeBundle>'));
      expect(screen, contains('skipError: true'));
      expect(screen, contains('showBack: false'));
      expect(screen, contains('RefreshIndicator'));
      expect(screen, contains('refreshAlunoDashboardHome'));
      expect('emphasize: true'.allMatches(screen), isEmpty);
      expect('emphasize: true'.allMatches(destaque), hasLength(1));

      for (final morto in [
        'checkinRepositoryProvider',
        'meusTreinosPagina',
        'ProgressoSemanalWidget',
        '_WeekProgressStrip',
        '_TrainingPlanCard',
        '_RetomarTreinoBanner',
        'confirmarPlano',
        'Fiz o treino',
        'Carregar mais',
        'Icons.refresh_rounded',
        'aderencia',
        'volumeSemanaKg',
      ]) {
        expect(screen, isNot(contains(morto)), reason: morto);
      }
      expect(
        File(
          'lib/features/checkin/data/meus_treinos_mem_cache.dart',
        ).existsSync(),
        isFalse,
      );
      expect(
        File(
          'lib/features/dashboard/screens/progresso_semanal_widget.dart',
        ).existsSync(),
        isFalse,
      );
    },
  );
}
