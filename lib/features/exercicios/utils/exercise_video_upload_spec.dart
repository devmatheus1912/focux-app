/// Contrato de gravação do vídeo do personal — alinhado ao POST /api/exercicios/{id}/video.
abstract final class ExerciseVideoUploadSpec {
  ExerciseVideoUploadSpec._();

  static const int maxBytes = 120 * 1024 * 1024;
  static const Duration maxDuration = Duration(seconds: 45);
  static const Set<String> allowedExtensions = {'mp4', 'mov', 'm4v', 'webm'};

  static const String aspectLabel = 'Vertical 9:16';
  static const String idealResolution = '1080 × 1920';
  static const String minResolution = '720 × 1280';
  static const String formatsLabel = 'MP4 ou MOV';
  static const String sizeLabel = 'Até 120 MB';
  static const String durationLabel = '10 a 45 segundos';

  static const List<ExerciseVideoSpecTip> tips = [
    ExerciseVideoSpecTip(
      title: 'Celular em pé (9:16)',
      body:
          'Filme na vertical, como o aluno vê no app. Horizontal corta o movimento.',
      icon: 'spark',
    ),
    ExerciseVideoSpecTip(
      title: '1080 × 1920 (ideal)',
      body:
          'Full HD vertical. O mínimo que ainda fica nítido é 720 × 1280. Evite 4K: pesa e o app reduz.',
      icon: 'target',
    ),
    ExerciseVideoSpecTip(
      title: '10 a 45 segundos',
      body:
          'Um movimento completo, de frente ou ¾. Sem intro, música alta ou corte no meio da repetição.',
      icon: 'flame',
    ),
    ExerciseVideoSpecTip(
      title: 'MP4 ou MOV · até 120 MB',
      body:
          'O celular já exporta nesse formato. Arquivo maior que 120 MB o servidor recusa.',
      icon: 'article',
    ),
  ];

  static String extensionOf(String filename) {
    final name = filename.trim().toLowerCase();
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1);
  }

  static String? rejectionFor({required String filename, required int bytes}) {
    if (bytes <= 0) {
      return 'Esse arquivo está vazio. Grave de novo ou escolha outro vídeo.';
    }
    if (bytes > maxBytes) {
      return 'O vídeo passa de 120 MB. Grave em 1080p vertical, até 45 segundos.';
    }
    final ext = extensionOf(filename);
    if (ext.isNotEmpty && !allowedExtensions.contains(ext)) {
      return 'Use MP4 ou MOV. $ext não entra neste envio.';
    }
    return null;
  }
}

class ExerciseVideoSpecTip {
  const ExerciseVideoSpecTip({
    required this.title,
    required this.body,
    this.icon,
  });

  final String title;
  final String body;
  final String? icon;
}
