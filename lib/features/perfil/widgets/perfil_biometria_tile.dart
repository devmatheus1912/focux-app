import 'package:flutter/material.dart';

import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../auth/services/biometria_login.dart';

/// "Entrar com Face ID": só aparece quando está ativo neste aparelho; tocar
/// desliga e apaga a credencial guardada.
class PerfilBiometriaTile extends StatefulWidget {
  const PerfilBiometriaTile({
    super.key,
    required this.mute,
    required this.line,
    this.biometria,
  });

  final Color mute;
  final Color line;
  final BiometriaLogin? biometria;

  @override
  State<PerfilBiometriaTile> createState() => _PerfilBiometriaTileState();
}

class _PerfilBiometriaTileState extends State<PerfilBiometriaTile> {
  late final BiometriaLogin _bio = widget.biometria ?? BiometriaLogin();
  BiometriaTipo? _tipo;

  @override
  void initState() {
    super.initState();
    _bio.tipoParaEntrar().then((t) {
      if (mounted) setState(() => _tipo = t);
    });
  }

  Future<void> _desativar() async {
    final nome = _tipo?.rotulo ?? 'biometria';
    await _bio.desativar();
    if (!mounted) return;
    setState(() => _tipo = null);
    FeedbackHelper.showSuccess(context, 'Entrar com $nome desativado.');
  }

  @override
  Widget build(BuildContext context) {
    final tipo = _tipo;
    if (tipo == null) return const SizedBox.shrink();
    return FxSettingsTile(
      icon: Icons.fingerprint_rounded,
      label: 'Entrar com ${tipo.rotulo}',
      value: 'Ativado · toque para desativar',
      mute: widget.mute,
      line: widget.line,
      onTap: _desativar,
    );
  }
}
