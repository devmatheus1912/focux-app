import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/captura_repository.dart';
import '../utils/leads_publicos_display.dart';

final _repoProvider = Provider(
  (ref) => CapturaRepository(ref.read(apiClientProvider)),
);

enum _LeadPublicoAcao { criarAluno, converter }

class LeadsPublicosScreen extends ConsumerStatefulWidget {
  const LeadsPublicosScreen({super.key});

  @override
  ConsumerState<LeadsPublicosScreen> createState() =>
      _LeadsPublicosScreenState();
}

class _LeadsPublicosScreenState extends ConsumerState<LeadsPublicosScreen> {
  List<SubmissaoCaptura> _leads = [];
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
      final lista = await ref.read(_repoProvider).meus();
      if (!mounted) return;
      setState(() {
        _leads = lista;
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

  void _abrirNovoAluno({String? nome, String? email}) {
    HapticFeedback.selectionClick();
    final q = <String, String>{
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (nome != null && nome.trim().isNotEmpty) 'nome': nome.trim(),
    };
    if (q.isEmpty) {
      context.push('/alunos/novo');
      return;
    }
    context.push(Uri(path: '/alunos/novo', queryParameters: q).toString());
  }

  Future<void> _marcarConvertido(SubmissaoCaptura lead) async {
    try {
      await ref.read(_repoProvider).marcarConvertido(lead.id);
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _abrirAcoes(SubmissaoCaptura lead) async {
    if (lead.convertido) return;
    final items = <FxInsetPickerSheetItem<_LeadPublicoAcao>>[
      if (leadPublicoPodeCriarAluno(lead.email))
        const FxInsetPickerSheetItem(
          value: _LeadPublicoAcao.criarAluno,
          label: 'Criar aluno',
        ),
      const FxInsetPickerSheetItem(
        value: _LeadPublicoAcao.converter,
        label: 'Marcar como convertido',
      ),
    ];
    final picked = await showFxInsetPickerSheet<_LeadPublicoAcao>(
      context,
      title: leadPublicoNome(lead.nome),
      items: items,
    );
    if (picked == null || !mounted) return;
    switch (picked) {
      case _LeadPublicoAcao.criarAluno:
        _abrirNovoAluno(nome: lead.nome, email: lead.email);
      case _LeadPublicoAcao.converter:
        await _marcarConvertido(lead);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: 'Leads do link público',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Leads do link público',
          subtitle: leadPublicoHubSubtitle(freshnessLabel),
          actions: [
            ShellHeaderIconButton(
              icon: 'plus',
              tooltip: 'Criar aluno',
              onTap: () => _abrirNovoAluno(),
            ),
          ],
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
    final primary = Theme.of(context).colorScheme.primary;
    return RefreshIndicator(
      onRefresh: _carregar,
      child: _leads.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                8,
                FxSettingsLayout.pageInset,
                32,
              ),
              children: const [
                FxEmptyState(
                  icon: 'users',
                  title: 'Nenhum lead ainda',
                  subtitle:
                      'Compartilhe o link do seu storefront para começar a captar contatos.',
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                TokensStrip.s3,
                FxSettingsLayout.pageInset,
                TokensStrip.s6,
              ),
              itemCount: _leads.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: TokensStrip.s3),
                    child: DashboardSectionHeader(title: 'Contatos captados'),
                  );
                }
                final lead = _leads[i - 1];
                return FxSatelliteListTile(
                  title: leadPublicoNome(lead.nome),
                  subtitle: Text(
                    leadPublicoSubtitle(
                      telefone: lead.telefone,
                      email: lead.email,
                      objetivo: lead.objetivo,
                    ),
                  ),
                  trailing: Text(
                    leadPublicoValue(lead.convertido),
                    style: FocuxHubTypography.bodyMuted(
                      color: fxScreenMute(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  accent: lead.convertido ? null : primary,
                  onTap: () => _abrirAcoes(lead),
                );
              },
            ),
    );
  }
}
