import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/perfil_repository.dart';
import '../providers/perfil_provider.dart';
import '../utils/brand_public_identity.dart';

/// Nome + link público quando Apple/Google deixou placeholder ou relay.
class BrandPublicIdentityScreen extends ConsumerStatefulWidget {
  const BrandPublicIdentityScreen({super.key, this.perfil});

  final PerfilPersonal? perfil;

  @override
  ConsumerState<BrandPublicIdentityScreen> createState() =>
      _BrandPublicIdentityScreenState();
}

class _BrandPublicIdentityScreenState
    extends ConsumerState<BrandPublicIdentityScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _slugCtrl;
  bool _loading = false;
  bool _slugTouched = false;

  @override
  void initState() {
    super.initState();
    final p = widget.perfil;
    final nome = (p?.nome ?? '').trim();
    final showNome = nome.isNotEmpty &&
            nome.toLowerCase() != 'personal' &&
            !nome.contains('@')
        ? nome
        : '';
    _nomeCtrl = TextEditingController(text: showNome);
    final slug = (p?.slug ?? '').trim();
    final editable = p?.slugEditable ?? true;
    final badSlug = slug.isEmpty ||
        slug.contains('privaterelay') ||
        slug == 'personal' ||
        RegExp(r'^personal-\d+$').hasMatch(slug);
    _slugCtrl = TextEditingController(
      text: editable && badSlug
          ? suggestSlugFromNome(showNome)
          : (editable ? '' : slug),
    );
    _nomeCtrl.addListener(_onNomeChanged);
  }

  void _onNomeChanged() {
    if (_slugTouched || !mounted) return;
    final suggested = suggestSlugFromNome(_nomeCtrl.text);
    if (suggested.isNotEmpty) {
      _slugCtrl.text = suggested;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nomeCtrl
      ..removeListener(_onNomeChanged)
      ..dispose();
    _slugCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate() || _loading) return;
    setState(() => _loading = true);
    HapticFeedback.mediumImpact();
    try {
      final repo = PerfilRepository(ref.read(apiClientProvider));
      final slug = _slugCtrl.text.trim().toLowerCase();
      await repo.atualizar(
        nome: _nomeCtrl.text.trim(),
        slug: slug,
      );
      ref.invalidate(perfilProvider);
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Link público pronto.');
      context.go('/dashboard/personal');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(perfilProvider);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    if (widget.perfil == null && async.isLoading) {
      return fxScreenA11yScope(
        label: 'Nome e link público',
        child: const FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(title: 'Seu link público'),
          body: Center(child: FxLoading()),
        ),
      );
    }
    if (widget.perfil == null && async.hasError) {
      return fxScreenA11yScope(
        label: 'Nome e link público',
        child: FxShellScaffold(
          useMesh: true,
          appBar: const FxShellAppBar(title: 'Seu link público'),
          body: FxErrorState(
            chromeOnDark: chrome.isDark,
            primary: primary,
            title: 'Não carregou seu perfil',
            message: friendlyError(async.error!),
            onRetry: () => ref.invalidate(perfilProvider),
          ),
        ),
      );
    }
    final live = widget.perfil ?? async.valueOrNull;
    if (live != null &&
        _nomeCtrl.text.isEmpty &&
        live.nome.trim().isNotEmpty &&
        live.nome.toLowerCase() != 'personal' &&
        !live.nome.contains('@')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _nomeCtrl.text.isNotEmpty) return;
        _nomeCtrl.text = live.nome.trim();
        if (!_slugTouched) {
          final s = suggestSlugFromNome(_nomeCtrl.text);
          if (s.isNotEmpty) _slugCtrl.text = s;
        }
        setState(() {});
      });
    }

    final preview = _slugCtrl.text.trim().isEmpty
        ? Env.landingPageDisplayLabel('seu-nome')
        : Env.landingPageDisplayLabel(_slugCtrl.text.trim().toLowerCase());

    return fxScreenA11yScope(
      label: 'Nome e link público',
      child: FxKeyboardDismissScope(
        child: FxShellScaffold(
          useMesh: true,
          appBar: const FxShellAppBar(
            title: 'Seu link público',
            subtitle: 'Como alunos e leads te encontram',
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(
                  'Na Apple, se você ocultou o e-mail, o link saía feio. '
                  'Defina seu nome e um endereço de marca.',
                  style: TextStyle(
                    color: EagleTokens.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nomeCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: FxInputDeco.build(
                    context,
                    'Nome profissional',
                    hint: 'Ex.: Matheus Oliveira',
                  ),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return 'Informe seu nome.';
                    if (t.contains('@') || t.toLowerCase() == 'personal') {
                      return 'Use seu nome real, não e-mail.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _slugCtrl,
                  onChanged: (_) {
                    _slugTouched = true;
                    setState(() {});
                  },
                  autocorrect: false,
                  decoration: FxInputDeco.build(
                    context,
                    'Link público',
                    hint: 'matheus-oliveira',
                  ).copyWith(prefixText: 'focuxpersonal.com/p/'),
                  validator: (v) => validateBrandSlug(v ?? ''),
                ),
                const SizedBox(height: 10),
                Text(
                  preview,
                  style: TextStyle(
                    color: EagleTokens.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _loading ? null : _salvar,
                  child: Text(_loading ? 'Salvando…' : 'Continuar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
