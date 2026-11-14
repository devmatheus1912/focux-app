import 'package:flutter/material.dart';

import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../alunos/widgets/aluno_avatar.dart';

/// Topo dos perfis (personal e aluno): cartão na cor da marca com a foto, o
/// nome e as linhas de apoio de cada um. [rodape] entra abaixo de uma linha
/// fina (as conquistas do aluno).
class PerfilTopoMarca extends StatelessWidget {
  const PerfilTopoMarca({
    super.key,
    required this.nome,
    required this.fotoUrl,
    required this.onEditar,
    required this.editarSemantica,
    this.carregando = false,
    this.linhas = const [],
    this.rodape,
    this.accent,
  });

  final String nome;
  final String? fotoUrl;

  /// O toque na foto abre a edição do cadastro.
  final VoidCallback onEditar;
  final String editarSemantica;

  /// Foto subindo: o lápis vira carregando e a foto não responde.
  final bool carregando;

  /// Linhas abaixo do nome (slogan, "Treina com…"), já com a cor de
  /// [fxPaletaSobreMarca].
  final List<Widget> linhas;
  final Widget? rodape;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final cor = accent ?? Theme.of(context).colorScheme.primary;
    final sobre = fxPaletaSobreMarca(context, accent: cor);
    return FxStripCard(
      marca: true,
      accent: cor,
      child: Column(
        children: [
          _Foto(
            nome: nome,
            fotoUrl: fotoUrl,
            cor: cor,
            tinta: sobre.ink,
            onTap: onEditar,
            carregando: carregando,
            semantica: editarSemantica,
          ),
          const SizedBox(height: TokensStrip.s3),
          Text(
            nome,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: FxSettingsLayout.profileName(context, color: sobre.ink),
          ),
          for (final linha in linhas) ...[
            const SizedBox(height: TokensStrip.s1),
            linha,
          ],
          if (rodape case final rodape?) ...[
            const SizedBox(height: TokensStrip.s3),
            Divider(height: 1, color: sobre.line),
            const SizedBox(height: TokensStrip.s3),
            rodape,
          ],
        ],
      ),
    );
  }
}

class _Foto extends StatelessWidget {
  const _Foto({
    required this.nome,
    required this.fotoUrl,
    required this.cor,
    required this.tinta,
    required this.onTap,
    required this.carregando,
    required this.semantica,
  });

  final String nome;
  final String? fotoUrl;
  final Color cor;
  final Color tinta;
  final VoidCallback onTap;
  final bool carregando;
  final String semantica;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantica,
      enabled: !carregando,
      excludeSemantics: true,
      child: InkWell(
        onTap: carregando ? null : onTap,
        customBorder: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: tinta, width: 2),
              ),
              child: AlunoAvatar(
                name: nome,
                photoUrl: fotoUrl,
                variant: AlunoAvatarVariant.profile,
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: FxSettingsLayout.editBadge,
                height: FxSettingsLayout.editBadge,
                decoration: BoxDecoration(color: tinta, shape: BoxShape.circle),
                child:
                    carregando
                        ? Padding(
                          padding: const EdgeInsets.all(6),
                          child: FxLoading(strokeWidth: 2, color: cor),
                        )
                        : Icon(FxIcons.editarPequeno, size: 14, color: cor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
