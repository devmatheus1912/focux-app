import 'package:flutter/material.dart';

import 'cinematic_mesh_background.dart';
import 'mesh_scope.dart';

/// Fundo opaco de uma página: o degradê da marca pintado na própria página.
///
/// Sem isso as telas abertas por cima ficam transparentes sobre um degradê
/// único atrás do navegador, e na transição (deslize do iPhone, voltar
/// preditivo do Android) a tela de baixo aparece através da de cima.
/// O [MeshScope] avisa o `FxShellScaffold` de que o fundo já existe.
class FxFundoDaPagina extends StatelessWidget {
  const FxFundoDaPagina({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CinematicMeshBackground(
      showCenterGlow: false,
      child: MeshScope(active: true, child: child),
    );
  }
}
