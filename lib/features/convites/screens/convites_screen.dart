import 'package:flutter/material.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/convite_repository.dart';
import '../providers/convite_provider.dart';
import '../../../core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';

class ConvitesScreen extends ConsumerStatefulWidget {
  const ConvitesScreen({super.key});

  @override
  ConsumerState<ConvitesScreen> createState() => _ConvitesScreenState();
}

class _ConvitesScreenState extends ConsumerState<ConvitesScreen> {
  Convite? _convite;
  bool _loading = false;
  String? _error;

  Future<void> _gerar() async {
    setState(() {
      _loading = true;
      _error = null;
      _convite = null;
    });
    try {
      final convite = await ref.read(conviteRepositoryProvider).gerar();
      setState(() {
        _convite = convite;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao gerar convite. Tente novamente.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _copiar(String texto) {
    Clipboard.setData(ClipboardData(text: texto));
    FeedbackHelper.showSnackBar(
      context,
      const SnackBar(content: Text('Link copiado!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: FxShellAppBar(
        title: 'Convidar aluno',
        onBack: () => safePopOrGo(context, '/dashboard/personal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Gere um link de convite único para seu aluno criar a conta no app.',
              style: TextStyle(color: EagleTokens.inkMute),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.link),
              label: const Text('Gerar novo link'),
              onPressed: _loading ? null : _gerar,
            ),
            if (_loading) ...[const SizedBox(height: 24), const FxLoading()],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: EagleTokens.bad)),
            ],
            if (_convite != null) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: fxListCardDecoration(
                  context,
                  accent: Theme.of(context).colorScheme.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Link gerado',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _convite!.link,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copiar link'),
                      onPressed: () => _copiar(_convite!.link),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Compartilhe este link com o aluno. Ele expira em 24h e pode ser usado uma única vez.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: EagleTokens.inkMute),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
