import 'package:flutter/material.dart';

import '../../../core/legal/focux_legal.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

/// Pré-lançamento: suporte oficial é o site (e-mail / WhatsApp).
/// Deep link `/suporte` abre a web e volta — sem ticket/chat no app.
class SuporteWebRedirectScreen extends StatefulWidget {
  const SuporteWebRedirectScreen({super.key});

  @override
  State<SuporteWebRedirectScreen> createState() =>
      _SuporteWebRedirectScreenState();
}

class _SuporteWebRedirectScreenState extends State<SuporteWebRedirectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openAndLeave());
  }

  Future<void> _openAndLeave() async {
    final opened = await FocuxLegal.openSupport();
    if (!mounted) return;
    if (!opened) {
      FeedbackHelper.showError(
        context,
        'Não abrimos o site de suporte. Tente de novo em breve.',
      );
    }
    safePopOrGo(context, '/perfil');
  }

  @override
  Widget build(BuildContext context) {
    return const FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(title: 'Suporte'),
      body: Center(child: FxLoading()),
    );
  }
}
