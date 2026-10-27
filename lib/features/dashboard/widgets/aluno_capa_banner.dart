import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_cached_network_image.dart';

/// Capa 16:9 do personal no topo da Home do aluno. Um véu escuro suave embaixo
/// mantém o que vier por cima legível; sem imagem, não ocupa espaço.
class AlunoCapaBanner extends StatelessWidget {
  const AlunoCapaBanner({super.key, required this.url, this.altura = 150});

  final String? url;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final endereco = url?.trim() ?? '';
    if (endereco.isEmpty) return const SizedBox.shrink();
    return Semantics(
      image: true,
      label: 'Capa do seu personal',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        child: SizedBox(
          height: altura,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(
                image: fxCachedNetworkImageProvider(endereco, maxWidth: 1080),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
