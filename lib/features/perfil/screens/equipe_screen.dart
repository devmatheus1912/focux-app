import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/equipe_repository.dart';
import '../models/tenant_membro.dart';
import '../utils/equipe_display.dart';

final equipeRepositoryProvider = Provider(
  (ref) => EquipeRepository(ref.read(apiClientProvider)),
);

class EquipeScreen extends ConsumerStatefulWidget {
  const EquipeScreen({super.key});

  @override
  ConsumerState<EquipeScreen> createState() => _EquipeScreenState();
}

class _EquipeScreenState extends ConsumerState<EquipeScreen> {
  List<TenantMembro> _membros = [];
  bool _loading = true;
  String? _error;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _membros = await ref.read(equipeRepositoryProvider).listar();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = friendlyError(e);
      });
    }
  }

  Future<void> _convidar() async {
    final ctrl = TextEditingController();
    var sent = false;
    try {
      final ok = await showFxFormSheet(
        context,
        title: 'Convidar assistente',
        icon: Icons.mail_outline_rounded,
        confirmLabel: 'Convidar',
        child: AlunoInsetFormField(
          controller: ctrl,
          label: 'Email',
          icon: Icons.alternate_email_outlined,
          keyboardType: TextInputType.emailAddress,
          showDivider: false,
        ),
      );
      if (ok != true || ctrl.text.trim().isEmpty) return;
      await ref
          .read(equipeRepositoryProvider)
          .convidar(email: ctrl.text.trim());
      sent = true;
      if (mounted) FeedbackHelper.showSuccess(context, 'Convite enviado');
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      ctrl.dispose();
    }
    if (sent) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chrome = ShellChrome.of(context);
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: 'Equipe',
      child: FeatureGate(
        featureName: 'Equipe',
        requiredPlan: SubscriptionPlan.ENTERPRISE,
        capability: 'equipeRbac',
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Equipe',
            subtitle: equipeHubSubtitle(freshnessLabel),
            actions: [
              ShellHeaderIconButton(
                icon: 'plus',
                tooltip: 'Convidar membro',
                onTap: _convidar,
              ),
            ],
          ),
          body:
              _loading
                  ? const Padding(
                    padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                    child: SkeletonList(count: 5),
                  )
                  : _error != null
                  ? FxErrorState(
                    chromeOnDark: chrome.isDark,
                    primary: scheme.primary,
                    message: _error!,
                    onRetry: _load,
                    title: 'Não conseguimos carregar a equipe',
                  )
                  : FxContentWidthLimiter(child: _buildBody()),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final chrome = ShellChrome.of(context);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          32,
        ),
        children: [
          if (_membros.isEmpty)
            FxEmptyState(
              icon: 'users',
              title: 'Nenhum membro',
              subtitle: 'Convide assistentes para escalar sua operação.',
              action: FxEmptyAction(label: 'Convidar', onTap: _convidar),
            )
          else
            FxSettingsGroup(
              header: 'Membros',
              caption: 'Papel e status de cada convite.',
              children: [
                for (var i = 0; i < _membros.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: TokensStrip.s3,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _membros[i].userEmail,
                                style: FxSettingsLayout.rowLabel(
                                  color: chrome.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                equipeMembroSubtitle(
                                  role: _membros[i].role,
                                  status: _membros[i].status,
                                ),
                                style: FxSettingsLayout.subhead(
                                  color: chrome.mute,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          equipeStatusLabel(_membros[i].status),
                          style: FxSettingsLayout.rowValue(color: chrome.mute),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
