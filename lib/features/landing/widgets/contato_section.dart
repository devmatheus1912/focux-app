import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/public_personal_data.dart';

class ContatoSection extends StatelessWidget {
  final PublicPersonalData data;
  const ContatoSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.instagram == null || data.instagram!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONTATO',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text('@${data.instagram}'),
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: 'https://instagram.com/${data.instagram}'),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link do Instagram copiado!')),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Color(0xFF374151)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
