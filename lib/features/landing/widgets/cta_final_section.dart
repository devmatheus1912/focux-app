import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/public_personal_data.dart';

class CtaFinalSection extends StatelessWidget {
  final PublicPersonalData data;
  final String slug;
  final Color primaryColor;
  
  const CtaFinalSection({super.key, required this.data, required this.slug, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: data.isEnterprise ? primaryColor : const Color(0xFF3B5FE2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Comece hoje.\nSeu personal está esperando.',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.3),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.go('/register/aluno?p=$slug');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: data.isEnterprise ? primaryColor : const Color(0xFF3B5FE2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Criar minha conta grátis →',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
