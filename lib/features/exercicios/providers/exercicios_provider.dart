import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/exercicio_repository.dart';
import '../data/exercicio_video_uploader.dart';

final exercicioRepositoryProvider = Provider<ExercicioRepository>(
  (ref) => ExercicioRepository(ref.read(apiClientProvider)),
);

final exercicioVideoUploaderProvider = Provider<ExercicioVideoUploader>(
  (ref) => ExercicioVideoUploader(ref.read(exercicioRepositoryProvider)),
);

// Parâmetros de filtro para a lista de exercícios
class ExercicioFilter {
  final String? nome;
  final String? categoria;
  final String? tag;
  final String? musculoAlvo;
  final String? equipamento;
  final String? nivel;
  final String? mecanica;
  final String? objetivo;
  final bool? hasVideo;
  final String? videoSource;
  final String? licenseStatus;
  final String? editorialStatus;
  final bool? favoritos;

  const ExercicioFilter({
    this.nome,
    this.categoria,
    this.tag,
    this.musculoAlvo,
    this.equipamento,
    this.nivel,
    this.mecanica,
    this.objetivo,
    this.hasVideo,
    this.videoSource,
    this.licenseStatus,
    this.editorialStatus,
    this.favoritos,
  });

  @override
  bool operator ==(Object other) =>
      other is ExercicioFilter &&
      other.nome == nome &&
      other.categoria == categoria &&
      other.tag == tag &&
      other.musculoAlvo == musculoAlvo &&
      other.equipamento == equipamento &&
      other.nivel == nivel &&
      other.mecanica == mecanica &&
      other.objetivo == objetivo &&
      other.hasVideo == hasVideo &&
      other.videoSource == videoSource &&
      other.licenseStatus == licenseStatus &&
      other.editorialStatus == editorialStatus &&
      other.favoritos == favoritos;

  @override
  int get hashCode => Object.hash(
    nome,
    categoria,
    tag,
    musculoAlvo,
    equipamento,
    nivel,
    mecanica,
    objetivo,
    hasVideo,
    videoSource,
    licenseStatus,
    editorialStatus,
    favoritos,
  );
}

// Provider com filtros
final exerciciosFilteredProvider =
    FutureProvider.family<List<Exercicio>, ExercicioFilter>((
      ref,
      filter,
    ) async {
      return ref
          .read(exercicioRepositoryProvider)
          .listar(
            nome: filter.nome,
            categoria: filter.categoria,
            tag: filter.tag,
            musculoAlvo: filter.musculoAlvo,
            equipamento: filter.equipamento,
            nivel: filter.nivel,
            mecanica: filter.mecanica,
            objetivo: filter.objetivo,
            hasVideo: filter.hasVideo,
            videoSource: filter.videoSource,
            licenseStatus: filter.licenseStatus,
            editorialStatus: filter.editorialStatus,
            favoritos: filter.favoritos,
          );
    });

// Provider sem filtro (compatibilidade)
final exerciciosProvider = FutureProvider<List<Exercicio>>((ref) async {
  return ref.read(exercicioRepositoryProvider).listar();
});

final exercicioProvider = FutureProvider.family<Exercicio, int>((
  ref,
  id,
) async {
  return ref.read(exercicioRepositoryProvider).buscar(id);
});

final exerciciosCuradoriaProvider = FutureProvider<ExercicioCuradoriaResumo>((
  ref,
) async {
  return ref.read(exercicioRepositoryProvider).buscarCuradoria();
});
