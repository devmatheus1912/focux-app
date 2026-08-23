import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../widgets/auth_shell.dart';

/// Campo OTP 6 dígitos reutilizável (cadastro + reset de senha).
class AuthOtpField extends StatelessWidget {
  const AuthOtpField({
    super.key,
    required this.controller,
    required this.onResend,
    required this.resendSeconds,
    required this.sending,
    required this.disabled,
    this.resendLabel = 'Reenviar',
  });

  final TextEditingController controller;
  final VoidCallback? onResend;
  final int resendSeconds;
  final bool sending;
  final bool disabled;
  final String resendLabel;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AuthField(
      label: 'Código do e-mail',
      controller: controller,
      hintText: '6 dígitos',
      icon: Icons.pin_outlined,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      validator: (value) {
        if (value == null || value.trim().length != 6) {
          return 'Informe o código de 6 dígitos.';
        }
        return null;
      },
      suffix: Semantics(
        button: true,
        label:
            resendSeconds > 0
                ? 'Reenviar código em $resendSeconds segundos'
                : resendLabel,
        child: TextButton(
          onPressed:
              (sending || disabled || resendSeconds > 0) ? null : onResend,
          child: Text(
            sending
                ? 'Enviando…'
                : resendSeconds > 0
                ? '${resendSeconds}s'
                : resendLabel,
            style: FocuxHubTypography.chip(primary).copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Countdown simples para reenvio de OTP.
mixin AuthOtpResendTimer<T extends StatefulWidget> on State<T> {
  int _resendSeconds = 0;
  Timer? _resendTimer;

  int get resendSeconds => _resendSeconds;

  void startResendCooldown([int seconds = 60]) {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}
