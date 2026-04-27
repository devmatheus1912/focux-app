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
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _dio.post('/api/uploads', data: form);
    return response.data['url'] as String;
  }
}
