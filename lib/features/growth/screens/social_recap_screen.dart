import 'package:flutter/material.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/feedback_helper.dart';

class SocialRecapScreen extends StatelessWidget {
  const SocialRecapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryDeep = BrandPalette.deep(primary);
    // In a real app, fetch from GET /api/v1/social/recap/{alunoId}
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,title: const Text('Recapitulação Mensal 🏆')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The "Spotify Wrapped" Card
            Container(
              width: 300,
              height: 500,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryDeep, primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.purple.withAlpha(50), blurRadius: 20, spreadRadius: 5)
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Icon(Icons.fitness_center, size: 200, color: Colors.white.withAlpha(20)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ABRIL 2026', style: TextStyle(color: Colors.white70, letterSpacing: 2, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        const Text(
                          'Mais forte a\ncada dia!',
                          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1.1),
                        ),
                        const SizedBox(height: 32),
                        _buildStatRow('Treinos Concluídos', '22'),
                        const SizedBox(height: 16),
                        _buildStatRow('Carga Levantada', '15.4 Toneladas'),
                        const SizedBox(height: 16),
                        _buildStatRow('Marcos Atingidos', '3'),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('João Pedro\n@marcos_personal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/React-icon.svg/1200px-React-icon.svg.png', // Mock Logo
                              width: 30,
                              height: 30,
                              color: Colors.white,
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                FeedbackHelper.showSuccess(context, 'Imagem exportada para os Stories do Instagram!');
              },
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text('Compartilhar no Instagram', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
