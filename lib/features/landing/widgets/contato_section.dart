import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/public_personal_data.dart';
import 'landing_design_helpers.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';

class ContatoSection extends StatelessWidget {
  final PublicPersonalData data;
  const ContatoSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.instagram == null || data.instagram!.isEmpty) {
      return const SizedBox.shrink();
    }

    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      color: const Color(0xFF070B16),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 34),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF101827),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.camera_alt_outlined, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CONTATO',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${data.instagram}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: 'https://instagram.com/${data.instagram}',
                      ),
                    );
                    FeedbackHelper.showSnackBar(
                      context,
                      const SnackBar(
                        content: Text('Link do Instagram copiado!'),
                      ),
                    );
                  },
                  child: Text(LandingDesign.contactCta(data)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
