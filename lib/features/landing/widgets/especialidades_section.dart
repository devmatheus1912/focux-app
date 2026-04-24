import 'package:flutter/material.dart';
import '../models/public_personal_data.dart';

class EspecialidadesSection extends StatelessWidget {
  final PublicPersonalData data;
  final Color primaryColor;
  
  const EspecialidadesSection({super.key, required this.data, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    if (data.especialidades == null || data.especialidades!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESPECIALIDADES',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: data.especialidades!
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .map((e) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: data.isEnterprise
                            ? primaryColor.withValues(alpha: 0.18)
                            : const Color(0xFF3B5FE2).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: data.isEnterprise
                              ? primaryColor.withValues(alpha: 0.4)
                              : const Color(0xFF3B5FE2).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        e,
                        style: TextStyle(
                          color: data.isEnterprise ? primaryColor : const Color(0xFF3B5FE2),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
