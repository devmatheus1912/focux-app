import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/fx_icons.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../data/grupo_aula_repository.dart';
import '../utils/grupo_aula_display.dart';

/// Linha da Home do aluno com a próxima aula em grupo em que ele se inscreveu.
class AlunoProximaAulaLinha extends StatelessWidget {
  const AlunoProximaAulaLinha({
    super.key,
    required this.aula,
    required this.hoje,
  });

  final GrupoAula aula;
  final DateTime hoje;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final quando = grupoAulaDiaRelativo(aula.inicio, hoje);
    final linha = grupoAulaLinha(
      inicio: aula.inicio,
      fim: aula.fim,
      localAula: aula.localAula,
    );
    return FxSettingsGroup(
      children: [
        FxSettingsTile(
          icon: FxIcons.grupo,
          label: s.alunoProximaAulaTitulo(aula.titulo),
          subtitle: '$quando · $linha',
          value: '',
          showDivider: false,
          onTap: () => context.push('/aluno/grupo-aulas'),
        ),
      ],
    );
  }
}
