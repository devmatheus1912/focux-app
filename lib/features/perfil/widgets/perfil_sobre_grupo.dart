import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/legal/focux_legal.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';

/// "Sobre": termos, privacidade, licenças e versão. Igual no perfil do
/// personal e no do aluno (os documentos do Focux valem para os dois).
class PerfilSobreGrupo extends StatelessWidget {
  const PerfilSobreGrupo({super.key, required this.mute, required this.line});

  final Color mute;
  final Color line;

  @override
  Widget build(BuildContext context) {
    return FxSettingsGroup(
      header: 'Sobre',
      children: [
        FxSettingsTile(
          icon: FxIcons.juridico,
          label: 'Termos de uso',
          value: '',
          mute: mute,
          line: line,
          onTap: () => FocuxLegal.openTerms(),
        ),
        FxSettingsTile(
          icon: FxIcons.seguranca,
          label: 'Política de privacidade',
          value: '',
          mute: mute,
          line: line,
          onTap: () => FocuxLegal.openPrivacy(),
        ),
        FxSettingsTile(
          icon: FxIcons.juridico,
          label: 'Licenças de código aberto',
          value: '',
          mute: mute,
          line: line,
          onTap: () => FocuxLegal.abrirLicencas(context),
        ),
        PerfilVersaoDoAppTile(mute: mute, line: line),
      ],
    );
  }
}

/// Versão instalada ("1.2.4 (228)"), para o suporte saber qual build o usuário tem.
class PerfilVersaoDoAppTile extends StatelessWidget {
  const PerfilVersaoDoAppTile({
    super.key,
    required this.mute,
    required this.line,
  });

  final Color mute;
  final Color line;

  static final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _info,
      builder: (context, snap) {
        final info = snap.data;
        final valor =
            info == null
                ? ''
                : info.buildNumber.isEmpty
                ? info.version
                : '${info.version} (${info.buildNumber})';
        return FxSettingsTile(
          icon: FxIcons.info,
          label: 'Versão do app',
          value: valor,
          mute: mute,
          line: line,
          showDivider: false,
          accessory: const SizedBox.shrink(),
        );
      },
    );
  }
}
