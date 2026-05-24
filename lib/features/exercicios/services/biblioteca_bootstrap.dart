import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/exercicio_repository.dart';
import '../providers/exercicios_provider.dart';
import '../screens/widgets/exercise_media_thumb.dart';
import 'biblioteca_sync_status.dart';

const _bootstrapKey = 'biblioteca_bootstrap_v1_done';
const _mediaPublishKey = 'biblioteca_media_publish_v1_done';

/// Garante biblioteca curada + mídia/substitutos sem ação do personal.
class BibliotecaBootstrap {
  BibliotecaBootstrap._();

  static bool _running = false;

  static Future<void> ensureReady(WidgetRef ref) async {
    if (_running) return;
    _running = true;
    BibliotecaSyncStatus.instance.start('Preparando biblioteca de exercícios...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final repo = ref.read(exercicioRepositoryProvider);
      var list = await ref.read(exerciciosProvider.future);

      if (list.isEmpty) {
        BibliotecaSyncStatus.instance.start('Importando exercícios padrão...');
        await repo.importarSeedPremiumV1();
        ref.invalidate(exerciciosProvider);
        list = await ref.read(exerciciosProvider.future);
      }

      final needsEnrich =
          list.any(
            (exercicio) =>
                exercicio.curado &&
                (exercicio.gifUrl?.trim().isEmpty ?? true) &&
                (exercicio.substitutos?.trim().isEmpty ?? true),
          );

      if (needsEnrich || !(prefs.getBool(_bootstrapKey) ?? false)) {
        BibliotecaSyncStatus.instance.start('Enriquecendo demonstrações...');
        await repo.enriquecerBibliotecaCurada();
        ref.invalidate(exerciciosProvider);
        await prefs.setBool(_bootstrapKey, true);
        list = await ref.read(exerciciosProvider.future);
      }

      if (_needsMediaPublish(list)) {
        final pending = list.where(exercicioMissingPreviewPoster).length;
        BibliotecaSyncStatus.instance.start(
          'Publicando demonstrações ($pending)...',
        );
        await repo.publicarMidiasCuradas();
        ref.invalidate(exerciciosProvider);
        list = await ref.read(exerciciosProvider.future);
        if (!_needsMediaPublish(list)) {
          await prefs.setBool(_mediaPublishKey, true);
        } else {
          await prefs.remove(_mediaPublishKey);
        }
      } else {
        await prefs.setBool(_mediaPublishKey, true);
      }
    } catch (e) {
      BibliotecaSyncStatus.instance.start(
        'Não foi possível sincronizar todas as demonstrações.',
      );
      await Future<void>.delayed(const Duration(seconds: 2));
    } finally {
      BibliotecaSyncStatus.instance.stop();
      _running = false;
    }
  }

  static bool _needsMediaPublish(List<Exercicio> list) {
    return list.any(exercicioMissingPreviewPoster);
  }
}
