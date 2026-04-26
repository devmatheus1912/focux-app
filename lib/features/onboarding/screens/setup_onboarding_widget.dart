import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/onboarding_provider.dart';
import '../../perfil/providers/perfil_provider.dart';

class SetupOnboardingWidget extends ConsumerWidget {
  const SetupOnboardingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(onboardingStatusProvider);

    return statusAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const SizedBox.shrink(),
      data: (data) {
        if (data.progressoPercentual == 100) return const SizedBox.shrink();

        return Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sua Ativação', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text('${data.progressoPercentual}%', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: data.progressoPercentual / 100,
                  backgroundColor: Colors.white.withValues(alpha: 0.5),
                  color: Theme.of(context).colorScheme.primary,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                _StepTile(
                  title: 'Configure seu Perfil',
                  isDone: data.perfilCompleto,
                  onTap: () async {
                    try {
                      final perfil = await ref.read(perfilProvider.future);
                      if (context.mounted) {
                        context.push('/perfil/editar', extra: perfil);
                      }
                    } catch (_) {
                      if (context.mounted) context.push('/perfil');
                    }
                  },
                ),
                _StepTile(
                  title: 'Adicione o primeiro Aluno',
                  isDone: data.primeiroAlunoAdicionado,
                  onTap: () => context.push('/alunos/novo'),
                ),
                _StepTile(
                  title: 'Crie um Treino',
                  isDone: data.primeiroTreinoCriado,
                  onTap: () => context.push('/treinos'),
                ),
                _StepTile(
                  title: 'Configure Pagamentos',
                  isDone: data.primeiroPagamentoRecebido,
                  onTap: () => context.push('/financeiro'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StepTile extends StatelessWidget {
  final String title;
  final bool isDone;
  final VoidCallback onTap;

  const _StepTile({required this.title, required this.isDone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDone ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isDone ? EagleTokens.good : EagleTokens.inkMute,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? EagleTokens.inkMute : Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: isDone ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),
            if (!isDone)
              const Icon(Icons.arrow_forward_ios, size: 14, color: EagleTokens.inkMute),
          ],
        ),
      ),
    );
  }
}
