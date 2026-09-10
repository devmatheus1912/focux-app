import 'package:dio/dio.dart';
import 'api_client.dart';

class MediaUploadService {
  final Dio _dio;
  MediaUploadService(ApiClient client) : _dio = client.dio;

  Future<String> uploadBytes({
    required List<int> bytes,
    required String filename,
    String folder = 'uploads',
    String resourceType = 'auto',
  }) async {
    final form = FormData.fromMap({
      'folder': folder,
      'resourceType': resourceType,
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: _contentTypeFor(filename, resourceType),
      ),
    });
    final response = await _dio.post('/api/uploads', data: form);
    return response.data['url'] as String;
  }

  /// Upload direto do caminho — evita carregar vídeo inteiro em RAM.
  Future<String> uploadFile({
    required String path,
    required String filename,
    String folder = 'uploads',
    String resourceType = 'auto',
  }) async {
    final form = FormData.fromMap({
      'folder': folder,
      'resourceType': resourceType,
      'file': await MultipartFile.fromFile(
        path,
        filename: filename,
        contentType: _contentTypeFor(filename, resourceType),
      ),
    });
    final response = await _dio.post('/api/uploads', data: form);
    return response.data['url'] as String;
  }

  DioMediaType? _contentTypeFor(String filename, String resourceType) {
    final ext = filename.toLowerCase().split('.').lastOrNull ?? '';
    return switch (ext) {
      'jpg' || 'jpeg' => DioMediaType('image', 'jpeg'),
      'png' => DioMediaType('image', 'png'),
      'webp' => DioMediaType('image', 'webp'),
      'gif' => DioMediaType('image', 'gif'),
      'heic' => DioMediaType('image', 'heic'),
      'heif' => DioMediaType('image', 'heif'),
      'mp4' => DioMediaType('video', 'mp4'),
      'mov' => DioMediaType('video', 'quicktime'),
      'webm' => DioMediaType('video', 'webm'),
      'm4a' => DioMediaType('audio', 'mp4'),
      'mp3' => DioMediaType('audio', 'mpeg'),
      'wav' => DioMediaType('audio', 'wav'),
      _ =>
        resourceType == 'image'
            ? DioMediaType('image', 'jpeg')
            : resourceType == 'video'
            ? DioMediaType('video', 'mp4')
            : null,
    };
  }
}
