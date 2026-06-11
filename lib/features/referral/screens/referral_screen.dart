import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/referral_repository.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

final referralRepositoryProvider = Provider(
  (ref) => ReferralRepository(ref.read(apiClientProvider)),
);

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  ReferralInfo? _info;
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await ref.read(referralRepositoryProvider).getInfo();
      if (mounted) {
        setState(() {
          _info = info;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = friendlyError(e);
        });
      }
    }
  }

  Future<void> _share() async {
    final info = _info;
    if (info == null) return;
    final text =
        'Use meu código ${info.codigo} e ganhe vantagens no Focux Personal!\n${info.linkCompartilhamento}';
    await AnalyticsService.instance.track(
      'referral_link_shared',
      props: {'codigo': info.codigo},
    );
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      FeedbackHelper.showSuccess(
        context,
        'Convite copiado! Cole no WhatsApp ou Instagram.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return fxScreenA11yScope(
      label: 'Indique e ganhe',
      child: FxShellScaffold(
        appBar: FxShellAppBar(title: 'Indique e ganhe'),
        body:
            _loading
                ? const Center(child: FxLoading())
                : _erro != null
                ? Center(child: Text(_erro!, textAlign: TextAlign.center))
                : Padding(
                  padding: const EdgeInsets.all(TokensStrip.s5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Indique outro personal. Quando ele assinar, você ganha 30 dias extras no plano.',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _info?.codigo ?? '—',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                color: primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_info?.usosTotais ?? 0} indicações convertidas',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _share,
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Compartilhar link'),
                      ),
                      TextButton(
                        onPressed: () {
                          final link = _info?.linkCompartilhamento ?? '';
                          if (link.isEmpty) return;
                          Clipboard.setData(ClipboardData(text: link));
                          FeedbackHelper.showSuccess(context, 'Link copiado!');
                        },
                        child: const Text('Copiar link'),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
