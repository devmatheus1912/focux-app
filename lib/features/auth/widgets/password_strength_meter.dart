import 'package:flutter/material.dart';

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({
    super.key,
    required this.password,
    this.minLength = 8,
    this.dark = true,
  });

  final String password;
  final int minLength;
  final bool dark;

  int get _score {
    if (password.isEmpty) return 0;
    var score = 0;
    if (password.length >= minLength) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return score;
  }

  _PasswordStrength get _strength {
    final score = _score;
    if (score == 0) {
      return _PasswordStrength(
        label: 'Digite a senha',
        value: 0,
        color: Colors.white24,
      );
    }
    if (score <= 2) {
      return const _PasswordStrength(
        label: 'Senha fraca',
        value: 0.34,
        color: Color(0xFFFF7A7A),
      );
    }
    if (score <= 4) {
      return const _PasswordStrength(
        label: 'Senha media',
        value: 0.67,
        color: Color(0xFFFFC857),
      );
    }
    return const _PasswordStrength(
      label: 'Senha forte',
      value: 1,
      color: Color(0xFF38E68A),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strength = _strength;
    final baseColor =
        dark ? Colors.white.withValues(alpha: 0.12) : Colors.black12;
    final textColor =
        dark ? Colors.white.withValues(alpha: 0.68) : Colors.black54;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: strength.value,
            minHeight: 5,
            backgroundColor: baseColor,
            valueColor: AlwaysStoppedAnimation<Color>(strength.color),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.shield_outlined, size: 13, color: strength.color),
            const SizedBox(width: 5),
            Text(
              strength.label,
              style: TextStyle(
                color: password.isEmpty ? textColor : strength.color,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (password.isNotEmpty && password.length < minLength) ...[
              const SizedBox(width: 6),
              Text(
                'min. $minLength caracteres',
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PasswordStrength {
  const _PasswordStrength({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}
