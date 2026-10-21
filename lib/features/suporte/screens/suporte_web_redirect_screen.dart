import 'package:flutter/material.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/support/intercom_service.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

/// Abre o Messenger do Intercom como overlay e retorna ao perfil.
class SuporteWebRedirectScreen extends StatefulWidget {
  const SuporteWebRedirectScreen({super.key});

  @override
  State<SuporteWebRedirectScreen> createState() =>
      _SuporteWebRedirectScreenState();
}

class _SuporteWebRedirectScreenState
    extends State<SuporteWebRedirectScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openSupport());
  }

  Future<void> _openSupport() async {
    if (!mounted) return;
    setState(() => _error = null);
    try {
      await IntercomService.openMessenger();
      if (!mounted) return;
      safePopOrGo(context, '/perfil');
    } catch (e) {
      if (!mounted) return;
      const message = 'Não conseguimos abrir o suporte. Tente novamente.';
      setState(() => _error = message);
      FeedbackHelper.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Suporte',
      child: FxShellScaffold(
        useMesh: true,
        appBar: const FxShellAppBar(title: 'Suporte'),
        body: _error != null
            ? FxErrorState(
                chromeOnDark: chrome.isDark,
                primary: primary,
                title: 'Suporte indisponível',
                message: _error!,
                onRetry: _openSupport,
              )
            : const Center(child: FxLoading()),
      ),
    );
  }
}
