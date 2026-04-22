import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../auth/providers/auth_provider.dart';

final _referralProvider = FutureProvider.autoDispose((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.dio.get('/api/referral');
  return res.data as Map<String, dynamic>;
});

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralAsync = ref.watch(_referralProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Indicar & Ganhar')),
      body: referralAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (data) {
          final codigo = data['codigo'] as String? ?? '';
          final usos = data['usosTotais'] as int? ?? 0;
          final link = data['linkCompartilhamento'] as String? ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.card_giftcard, color: Colors.white, size: 48),
                      const SizedBox(height: 12),
                      const Text('Indique um colega personal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Cada colega que assinar usando seu código, você ganha benefícios exclusivos!', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Código
                Text('Seu código de indicação', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(codigo, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, letterSpacing: 3)),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        color: Theme.of(context).colorScheme.primary,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: codigo));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Código copiado!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stats
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text('$usos', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                              const Text('Indicações', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 50, color: Colors.grey[200]),
                        Expanded(
                          child: Column(
                            children: [
                              Text('${usos * 30}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green[600])),
                              const Text('Dias grátis ganhos', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Share
                FilledButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: link));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copiado! Compartilhe com colegas.')),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Compartilhar meu link'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
