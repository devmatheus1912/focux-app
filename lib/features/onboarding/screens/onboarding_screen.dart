import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _current = 0;

  static const _pages = [
    _OnboardPage(
      icon: Icons.fitness_center,
      title: 'Gerencie seus alunos',
      subtitle: 'Cadastre, acompanhe e evolua cada aluno com precisão.',
    ),
    _OnboardPage(
      icon: Icons.auto_awesome,
      title: 'IA no seu time',
      subtitle: 'Gere treinos e dietas personalizados com inteligência artificial.',
    ),
    _OnboardPage(
      icon: Icons.insights,
      title: 'Resultados reais',
      subtitle: 'Monitore check-ins, aderência e evolução física em tempo real.',
    ),
    _OnboardPage(
      icon: Icons.attach_money,
      title: 'Seu negócio organizado',
      subtitle: 'Controle financeiro, agenda e planos de assinatura em um só lugar.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: PageView.builder(
              controller: _page,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) => _pages[i],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _current == i ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _current == i
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            )),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _current < _pages.length - 1
                ? Row(children: [
                    TextButton(onPressed: () => context.go('/login'), child: const Text('Pular')),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => _page.nextPage(
                          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                      child: const Text('Próximo'),
                    ),
                  ])
                : FilledButton(
                    onPressed: () => context.go('/login'),
                    style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                    child: const Text('Começar'),
                  ),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardPage({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 96, color: theme.colorScheme.primary),
        const SizedBox(height: 40),
        Text(title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(subtitle, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
      ]),
    );
  }
}
