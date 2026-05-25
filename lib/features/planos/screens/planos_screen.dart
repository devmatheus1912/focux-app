import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/fx_loading.dart';

/// `/planos` redireciona para a máquina de vendas unificada em `/assinatura`.
class PlanosScreen extends StatefulWidget {
  const PlanosScreen({super.key});

  @override
  State<PlanosScreen> createState() => _PlanosScreenState();
}

class _PlanosScreenState extends State<PlanosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go('/assinatura');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: FxLoading()));
  }
}
