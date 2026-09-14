import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

/// Preview HTML autenticado do studio — WebView in-app (sem data: URI).
Future<void> openLandingPreviewScreen(
  BuildContext context, {
  required String html,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => LandingPreviewScreen(html: html),
    ),
  );
}

class LandingPreviewScreen extends StatefulWidget {
  const LandingPreviewScreen({super.key, required this.html});

  final String html;

  @override
  State<LandingPreviewScreen> createState() => _LandingPreviewScreenState();
}

class _LandingPreviewScreenState extends State<LandingPreviewScreen> {
  WebViewController? _controller;
  bool _loading = true;
  bool _unsupported = false;

  @override
  void initState() {
    super.initState();
    if (!_platformSupportsWebView) {
      _unsupported = true;
      _loading = false;
      return;
    }
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
          ),
        )
        ..loadHtmlString(widget.html);
    } catch (_) {
      _unsupported = true;
      _loading = false;
    }
  }

  static bool get _platformSupportsWebView {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return FxShellScaffold(
      useMesh: false,
      appBar: FxShellAppBar(
        title: 'Preview',
        subtitle: 'Como o lead vê · ainda não publicado',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: _unsupported
          ? ListView(
              padding: const EdgeInsets.all(TokensStrip.s4),
              children: [
                Text(
                  'Preview completo roda no app Android/iOS. '
                  'Neste desktop, use o HTML abaixo ou publique o link.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: chrome.mute,
                  ),
                ),
                const SizedBox(height: TokensStrip.s3),
                SelectableText(
                  widget.html,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: chrome.mute,
                  ),
                ),
              ],
            )
          : Stack(
              children: [
                if (_controller != null)
                  WebViewWidget(controller: _controller!),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(TokensStrip.s4),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
    );
  }
}
