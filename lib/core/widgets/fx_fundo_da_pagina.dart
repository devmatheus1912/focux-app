import 'package:flutter/material.dart';

import 'fx_chao.dart';
import 'fx_chao_scope.dart';

/// Fundo opaco de uma página: o chão sólido ([FxChao]) pintado na própria
/// página.
///
/// Sem isso as telas abertas por cima ficam transparentes sobre um fundo
/// único atrás do navegador, e na transição (deslize do iPhone, voltar
/// preditivo do Android) a tela de baixo aparece através da de cima.
/// O [FxChaoScope] avisa o `FxShellScaffold` de que o fundo já existe.
class FxFundoDaPagina extends StatelessWidget {
  const FxFundoDaPagina({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FxChao(
      child: FxChaoScope(active: true, child: child),
    );
  }
}
