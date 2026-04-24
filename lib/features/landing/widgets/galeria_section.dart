import 'package:flutter/material.dart';
import '../models/public_personal_data.dart';

class GaleriaSection extends StatelessWidget {
  final PublicPersonalData data;
  const GaleriaSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (!data.isEnterprise || data.fotos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GALERIA',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: data.fotos.length,
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(data.fotos[i], fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
