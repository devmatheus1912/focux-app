import 'package:flutter/material.dart';

import '../../../core/media/fx_economia_de_dados.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../l10n/app_localizations.dart';

/// Perfil > Conta: "Economizar dados móveis" (ligado por padrão).
class EconomiaDeDadosTile extends StatefulWidget {
  const EconomiaDeDadosTile({super.key});

  @override
  State<EconomiaDeDadosTile> createState() => _EconomiaDeDadosTileState();
}

class _EconomiaDeDadosTileState extends State<EconomiaDeDadosTile> {
  bool _ligada = true;

  @override
  void initState() {
    super.initState();
    FxEconomiaDeDados.ligada().then((v) {
      if (mounted) setState(() => _ligada = v);
    });
  }

  Future<void> _mudar(bool v) async {
    setState(() => _ligada = v);
    await FxEconomiaDeDados.definir(v);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    return FxSettingsTile(
      icon: FxIcons.celular,
      label: s.alunoPerfilEconomizarDados,
      subtitle: s.alunoPerfilEconomizarDadosDetalhe,
      value: '',
      mute: chrome.mute,
      line: chrome.line,
      onTap: () => _mudar(!_ligada),
      accessory: Switch.adaptive(value: _ligada, onChanged: _mudar),
    );
  }
}
