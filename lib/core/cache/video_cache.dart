import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

/// Caches exercise videos locally for offline playback and faster loading.
///
/// Videos are cached by URL hash in the app's temporary directory.
/// Cache is limited by age (7 days) and size (500MB).
class VideoCache {
  VideoCache._();

  static const _dirName = 'video_cache';
  static const _maxAgeDays = 7;
  static const _maxSizeBytes = 500 * 1024 * 1024; // 500MB

  static final Dio _dio = Dio();

  /// Get cached file path for a URL, or download and cache it.
  /// Returns the local file path, or null if download fails.
  static Future<String?> getCachedPath(String url) async {
    if (url.isEmpty) return null;

    try {
      final dir = await _cacheDir();
      final filename = _hashUrl(url);
      final file = File('${dir.path}/$filename');

      if (await file.exists()) {
        // Touch the file to update modified time for LRU
        await file.setLastModified(DateTime.now());
        return file.path;
      }

      // Download to temp first, then move (atomic)
      final tmpFile = File('${dir.path}/$filename.tmp');
      await _dio.download(url, tmpFile.path);

      if (await tmpFile.exists()) {
        await tmpFile.rename(file.path);
        // Prune cache in background
        _pruneCache(dir);
        return file.path;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[VideoCache] Error caching $url: $e');
    }

    return null;
  }

  /// Check if a URL is already cached.
  static Future<bool> isCached(String url) async {
    if (url.isEmpty) return false;
    try {
      final dir = await _cacheDir();
      final filename = _hashUrl(url);
      return File('${dir.path}/$filename').exists();
    } catch (_) {
      return false;
    }
  }

  /// Preload a list of video URLs in the background.
  static Future<void> preload(List<String> urls) async {
    for (final url in urls) {
      if (url.isEmpty) continue;
      if (await isCached(url)) continue;
      await getCachedPath(url);
    }
  }

  /// Clear entire video cache.
  static Future<void> clearAll() async {
    try {
      final dir = await _cacheDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[VideoCache] Clear error: $e');
    }
  }

  static Future<Directory> _cacheDir() async {
    final tmp = await getTemporaryDirectory();
    final dir = Directory('${tmp.path}/$_dirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _hashUrl(String url) {
    // Simple hash for filename — deterministic and fast
    var hash = 0;
    for (var i = 0; i < url.length; i++) {
      hash = ((hash << 5) - hash + url.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    final ext = url.contains('.mp4')
        ? '.mp4'
        : url.contains('.webm')
            ? '.webm'
            : '.vid';
    return 'v_$hash$ext';
  }

  static Future<void> _pruneCache(Directory dir) async {
    try {
      final files = await dir.list().toList();
      final cutoff = DateTime.now().subtract(const Duration(days: _maxAgeDays));

      // Remove expired files
      for (final entity in files) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoff)) {
            await entity.delete();
          }
        }
      }

      // Check total size
      var totalSize = 0;
      final remaining = <File>[];
      for (final entity in await dir.list().toList()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
          remaining.add(entity);
        }
      }

      // If over max size, remove oldest files
      if (totalSize > _maxSizeBytes) {
        remaining.sort((a, b) {
          final aTime = a.statSync().modified;
          final bTime = b.statSync().modified;
          return aTime.compareTo(bTime);
        });

        for (final file in remaining) {
          if (totalSize <= _maxSizeBytes) break;
          totalSize -= file.statSync().size;
          await file.delete();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[VideoCache] Prune error: $e');
    }
  }
}
