part of 'pacotes_storefront_widgets.dart';

class _PacoteTag extends StatelessWidget {
  const _PacoteTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: FocuxHubTypography.bodyMuted(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Estado de erro com retry — delega ao canônico [FxErrorState].
class PacotesLoadErrorState extends StatelessWidget {
  const PacotesLoadErrorState({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return FxErrorState(
      chromeOnDark: Theme.of(context).brightness == Brightness.dark,
      primary: Theme.of(context).colorScheme.primary,
      title: 'Não foi possível carregar seus planos',
      message: message ?? 'Verifique sua conexão e tente novamente.',
      onRetry: onRetry,
    );
  }
}

/// Abre bottom sheet premium; retorna true se pacote foi criado.
Future<bool> showNovoPacoteSheet(
  BuildContext context, {
  required PacoteRepository repo,
}) async {
  final created = await showFxHomeSheet<bool>(
    context,
    builder: (ctx) => _NovoPacoteSheet(repo: repo),
  );
  return created ?? false;
}

/// Confirma desativação antes de remover da vitrine.
Future<bool> confirmDesativarPacote(BuildContext context, String titulo) async {
  final mute = fxScreenMute(context);
  final confirmed = await showFxHomeSheet<bool>(
    context,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final primary = Theme.of(ctx).colorScheme.primary;
      return FxHomeSheetSurface(
        isDark: isDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FxHomeSheetHandle(isDark: isDark),
            SizedBox(height: TokensStrip.s4),
            FxHomeSheetHeader(
              isDark: isDark,
              title: 'Desativar plano?',
              leading: Icon(
                Icons.delete_outline_rounded,
                color: primary,
                size: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '“$titulo” some da sua página na internet. '
              'Quem abrir seu link não verá mais este plano. '
              'Você pode criar outro depois.',
              textAlign: TextAlign.center,
              style: TokensStrip.bodyMuted(color: mute).copyWith(height: 1.4),
            ),
            const SizedBox(height: 20),
            FxLiquidPrimaryButton(
              label: 'Desativar',
              icon: Icons.delete_outline_rounded,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
            const SizedBox(height: 10),
            FxLiquidSecondaryButton(
              label: 'Cancelar',
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
          ],
        ),
      );
    },
  );
  return confirmed ?? false;
}

class _NovoPacoteSheet extends StatefulWidget {
  const _NovoPacoteSheet({required this.repo});

  final PacoteRepository repo;

  @override
  State<_NovoPacoteSheet> createState() => _NovoPacoteSheetState();
}

class _NovoPacoteSheetState extends State<_NovoPacoteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();

  int _duracao = 1;
  bool _treino = true;
  bool _nutri = false;
  bool _consultoria = false;
  bool _destaque = false;
  bool _enviando = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_enviando) return;
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _enviando = true);
    try {
      await widget.repo.criar(
        titulo: _tituloCtrl.text.trim(),
        descricao: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        valor: double.parse(_valorCtrl.text.trim().replaceAll(',', '.')),
        duracaoMeses: _duracao,
        incluiTreino: _treino,
        incluiNutri: _nutri,
        incluiConsultoria: _consultoria,
        destaque: _destaque,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight:
          MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxHomeSheetHandle(isDark: isDark),
              SizedBox(height: TokensStrip.s4),
              FxHomeSheetHeader(
                isDark: isDark,
                title: 'Novo plano',
                subtitle:
                    'Quem abrir seu link verá este plano na sua página de vendas.',
                leading: Icon(
                  Icons.add_card_outlined,
                  color: primary,
                  size: 18,
                ),
                trailing: IconButton(
                  tooltip: 'Fechar',
                  onPressed:
                      _enviando ? null : () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(
                      FxHomeSheetChrome.touchTarget,
                      FxHomeSheetChrome.touchTarget,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 22),
                ),
              ),
              const SizedBox(height: 16),
              FxSettingsGroup(
                children: [
                  AlunoInsetFormField(
                    controller: _tituloCtrl,
                    label: 'Título',
                    icon: Icons.title_outlined,
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty
                                ? 'Informe um título'
                                : null,
                  ),
                  AlunoInsetFormField(
                    controller: _descCtrl,
                    label: 'Descrição',
                    icon: Icons.notes_outlined,
                    maxLines: 2,
                  ),
                  AlunoInsetFormField(
                    controller: _valorCtrl,
                    label: 'Valor que o cliente paga (R\$)',
                    icon: Icons.payments_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Informe o valor';
                      }
                      final valor =
                          double.tryParse(v.trim().replaceAll(',', '.')) ?? 0;
                      if (valor <= 0) return 'Valor deve ser maior que zero';
                      return null;
                    },
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FxSettingsGroup(
                header: 'Plano',
                children: [
                  FxInsetPickerRow(
                    icon: Icons.schedule_outlined,
                    label: 'Duração',
                    value: pacoteDuracaoLabel(_duracao),
                    onTap: _enviando
                        ? () {}
                        : () async {
                            final picked = await showFxInsetPickerSheet<int>(
                              context,
                              title: 'Duração',
                              selected: _duracao,
                              items: [
                                for (final meses in pacoteDuracaoMesesValues)
                                  FxInsetPickerSheetItem(
                                    value: meses,
                                    label: pacoteDuracaoLabel(meses),
                                  ),
                              ],
                            );
                            if (picked == null) return;
                            setState(() => _duracao = picked);
                          },
                  ),
                  FxSettingsTile(
                    icon: Icons.fitness_center_outlined,
                    label: 'Treino',
                    value: pacoteIncluiValue(_treino),
                    onTap: _enviando
                        ? () {}
                        : () => setState(() => _treino = !_treino),
                  ),
                  FxSettingsTile(
                    icon: Icons.restaurant_outlined,
                    label: 'Nutrição',
                    value: pacoteIncluiValue(_nutri),
                    onTap: _enviando
                        ? () {}
                        : () => setState(() => _nutri = !_nutri),
                  ),
                  FxSettingsTile(
                    icon: Icons.chat_bubble_outline,
                    label: 'Consultoria',
                    value: pacoteIncluiValue(_consultoria),
                    showDivider: false,
                    onTap: _enviando
                        ? () {}
                        : () => setState(() => _consultoria = !_consultoria),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FxSettingsGroup(
                children: [
                  FxSettingsTile(
                    icon: Icons.star_outline_rounded,
                    label: 'Mostrar em destaque',
                    value: pacoteIncluiValue(_destaque),
                    showDivider: false,
                    onTap: _enviando
                        ? () {}
                        : () => setState(() => _destaque = !_destaque),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FxLiquidPrimaryButton(
                label: 'Criar plano',
                icon: Icons.check_rounded,
                loading: _enviando,
                loadingLabel: 'Criando…',
                onPressed: _enviando ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void copyStorefrontLink(BuildContext context, String? slug) {
  if (slug == null || slug.isEmpty) {
    FeedbackHelper.showWarn(
      context,
      'Complete seu perfil para gerar o link da sua página de vendas.',
    );
    return;
  }
  Clipboard.setData(ClipboardData(text: Env.landingPageUrl(slug)));
  FeedbackHelper.showSuccess(context, 'Link copiado!');
}

Future<void> openStorefrontPreview(BuildContext context, String? slug) async {
  if (slug == null || slug.isEmpty) {
    FeedbackHelper.showWarn(
      context,
      'Complete seu perfil para abrir sua página de vendas.',
    );
    return;
  }
  final uri = Uri.parse(Env.landingPageUrl(slug));
  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (opened) {
      FeedbackHelper.showInfo(context, 'Abrindo como seu cliente vê…');
    } else {
      FeedbackHelper.showWarn(context, 'Não foi possível abrir o link.');
    }
  } catch (_) {
    if (!context.mounted) return;
    FeedbackHelper.showError(context, 'Não foi possível abrir a página.');
  }
}

