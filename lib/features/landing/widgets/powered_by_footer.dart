import 'package:flutter/material.dart';
import '../models/public_personal_data.dart';

class PoweredByFooter extends StatelessWidget {
  final PublicPersonalData data;
  const PoweredByFooter({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEnterprise) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Divider(color: Color(0xFF1F2937)),
          const SizedBox(height: 12),
          Text(
            'Powered by Focux Personal - ${DateTime.now().year}',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
