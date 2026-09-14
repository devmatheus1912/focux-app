import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  Widget build(BuildContext context) {
    return FxShellScaffold(
      useMesh: false,
      appBar: FxShellAppBar(
        title: 'Preview',
        subtitle: 'Como o lead vê · ainda não publicado',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
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
