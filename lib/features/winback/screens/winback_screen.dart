import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/winback_repository.dart';
import '../utils/winback_display.dart';

final winbackRepositoryProvider = Provider(
  (ref) => WinbackRepository(ref.read(apiClientProvider)),
);

class WinbackScreen extends ConsumerStatefulWidget {
  const WinbackScreen({super.key});

  @override
  ConsumerState<WinbackScreen> createState() => _WinbackScreenState();
}

class _WinbackScreenState extends ConsumerState<WinbackScreen> {
  List<WinbackLogEntry> _entries = [];
  bool _loading = true;
  String? _erro;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final entries = await ref.read(winbackRepositoryProvider).log();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = friendlyError(e);
      });
    }
  }

  void _abrirSaude() {
    HapticFeedback.selectionClick();
    context.push('/retencao');
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: 'Win-back automático',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Win-back automático',
          subtitle: winbackHubSubtitle(freshness),
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
        ),
        body:
            _loading
                ? const Padding(
                  padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                  child: SkeletonList(count: 5),
                )
                : _erro != null
                ? FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: primary,
                  message: _erro!,
                  onRetry: _carregar,
                )
                : FxContentWidthLimiter(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          32,
        ),
        children: [
          FxSettingsGroup(
            header: 'Automação',
            caption:
                'Push automático para alunos inativos. Trial do personal não entra neste log.',
            children: [
              FxSettingsTile(
                fxIcon: 'bell',
                label: 'FCM ativo',
                subtitle: 'Reengajamento em 7, 30 e 60 dias sem treino.',
                value: 'Saúde',
                showDivider: false,
                onTap: _abrirSaude,
              ),
            ],
          ),
          if (_entries.isEmpty)
            const FxEmptyState(
              icon: 'bell',
              title: 'Nenhum envio ainda',
              subtitle:
                  'Quando a automação disparar, os registros aparecem aqui.',
            )
          else
            FxSettingsGroup(
              header: 'Envios',
              caption: 'Push enviados pela automação de inatividade.',
              children: [
                for (var i = 0; i < _entries.length; i++)
                  FxSettingsTile(
                    fxIcon: winbackFxIcon(_entries[i].tipo),
                    label: winbackAlunoLabel(_entries[i].alunoNome),
                    subtitle: winbackSubtitle(
                      tipo: _entries[i].tipo,
                      mensagem: _entries[i].mensagem,
                    ),
                    value: winbackWhenLabel(_entries[i].enviadoEm),
                    showDivider: i != _entries.length - 1,
                    onTap: () {},
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
