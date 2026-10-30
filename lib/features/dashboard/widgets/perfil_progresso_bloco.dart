import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_cached_network_image.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../evolucao/data/evolucao_repository.dart';

String _num(double v) => formatBrDecimal(v).replaceFirst(RegExp(r',0$'), '');

/// "30/10 · 90 kg · cintura 50 cm": uma linha por registro.
String resumoDaMedida(MedidaCorporal m) {
  final data = DateTime.tryParse(m.data);
  return [
    if (data != null)
      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}'
    else
      m.data,
    if (m.peso != null) '${_num(m.peso!)} kg',
    if (m.cintura != null) 'cintura ${_num(m.cintura!)} cm',
    if (m.quadril != null) 'quadril ${_num(m.quadril!)} cm',
    if (m.braco != null) 'braço ${_num(m.braco!)} cm',
  ].join(' · ');
}

/// Progresso no Perfil: medidas em linhas e foto pequena, que só abre no toque.
class PerfilProgressoBloco extends StatelessWidget {
  const PerfilProgressoBloco({super.key, required this.medidas});

  final List<MedidaCorporal> medidas;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    return FxSettingsGroup(
      header: s.alunoPerfilGrupoProgresso,
      children: [
        for (final m in medidas.take(3))
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FxSettingsLayout.groupPadH,
              vertical: TokensStrip.s2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    resumoDaMedida(m),
                    style: FocuxHubTypography.bodyMuted(color: chrome.ink),
                  ),
                ),
                if (m.fotoUrl?.isNotEmpty == true) _Miniatura(url: m.fotoUrl!),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(FxSettingsLayout.groupPadH),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FxTonalButton(
              label: s.alunoPerfilRegistrarMedida,
              icon: Icons.add_chart,
              compact: true,
              onPressed: () => context.push('/aluno/perfil/editar?acao=medida'),
            ),
          ),
        ),
      ],
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: S.of(context).alunoPerfilVerFoto,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(TokensStrip.rSm),
        onTap: () => showDialog<void>(
          context: context,
          builder: (ctx) => GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: Center(
              child: FxCachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
            ),
          ),
        ),
        child: SizedBox(
          width: 48,
          height: 48,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TokensStrip.rSm),
            child: FxCachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              memCacheWidth: 144,
            ),
          ),
        ),
      ),
    );
  }
}
