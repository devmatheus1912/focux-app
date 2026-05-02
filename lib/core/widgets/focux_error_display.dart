import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/design_tokens.dart';

/// Fase 3: Observability-aware error display.
/// Extracts requestId from backend error responses and shows
/// actionable error messages users can share with support.
class FocuxErrorDisplay {
  FocuxErrorDisplay._();

  /// Extract a human-readable error from a DioException or generic error.
  /// Includes requestId if present for end-to-end tracing.
  static FocuxError parse(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      String message = 'Erro de conexão. Verifique sua internet.';
      String? requestId;
      int? status;

      if (data is Map<String, dynamic>) {
        message = data['erro'] as String? ?? message;
        requestId = data['requestId'] as String?;
        status = data['status'] as int?;
      }

      status ??= error.response?.statusCode;

      // Also try X-Request-Id header
      requestId ??= error.response?.headers.value('X-Request-Id');

      return FocuxError(
        message: message,
        requestId: requestId,
        statusCode: status,
        isNetworkError: error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout,
      );
    }

    return FocuxError(message: error.toString());
  }

  /// Show a user-friendly error snackbar with optional requestId for support.
  static void showError(BuildContext context, Object error) {
    final parsed = parse(error);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            parsed.message,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          if (parsed.requestId != null) ...[
            const SizedBox(height: 4),
            Text(
              'Ref: ${parsed.requestId}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
      backgroundColor: isDark ? const Color(0xFF2D1414) : EagleTokens.bad,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
      action: parsed.requestId != null
          ? SnackBarAction(
              label: 'Copiar',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(
                  text: 'Erro: ${parsed.message}\nRef: ${parsed.requestId}\nStatus: ${parsed.statusCode}',
                ));
              },
            )
          : null,
    ));
  }

  /// Show an error dialog with full details for debugging.
  static void showErrorDialog(BuildContext context, Object error) {
    final parsed = parse(error);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? EagleTokens.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: EagleTokens.bad, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Erro', style: TextStyle(color: ink, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(parsed.message, style: TextStyle(color: ink, fontSize: 14)),
            if (parsed.statusCode != null) ...[
              const SizedBox(height: 8),
              Text('HTTP ${parsed.statusCode}', style: TextStyle(color: mute, fontSize: 12)),
            ],
            if (parsed.requestId != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : EagleTokens.paper,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ref: ${parsed.requestId}',
                        style: TextStyle(color: mute, fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: parsed.requestId!));
                        HapticFeedback.lightImpact();
                      },
                      child: Icon(Icons.copy, size: 16, color: mute),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Fechar', style: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute)),
          ),
          if (parsed.requestId != null)
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(
                  text: 'Erro: ${parsed.message}\nRef: ${parsed.requestId}\nStatus: ${parsed.statusCode}',
                ));
                HapticFeedback.mediumImpact();
                Navigator.pop(ctx);
              },
              child: const Text('Copiar detalhes'),
            ),
        ],
      ),
    );
  }
}

class FocuxError {
  final String message;
  final String? requestId;
  final int? statusCode;
  final bool isNetworkError;

  const FocuxError({
    required this.message,
    this.requestId,
    this.statusCode,
    this.isNetworkError = false,
  });

  @override
  String toString() =>
      'FocuxError(message: $message, requestId: $requestId, status: $statusCode)';
}
