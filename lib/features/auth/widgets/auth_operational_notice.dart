import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

class AuthOperationalNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final String? action;

  const AuthOperationalNotice({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: EagleTokens.opsNotice.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EagleTokens.opsNotice.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: EagleTokens.opsNotice.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: EagleTokens.planUsageWarn),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.6,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12.2,
                    height: 1.35,
                  ),
                ),
                if (action != null && action!.trim().isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    action!,
                    style: TextStyle(
                      color: EagleTokens.planUsageWarn,
                      fontSize: 12.1,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
