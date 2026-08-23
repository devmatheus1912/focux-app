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
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
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
              TextFormField(
                controller: _tituloCtrl,
                enabled: !_enviando,
                textInputAction: TextInputAction.next,
                decoration: FxInputDeco.build(
                  context,
                  'Título *',
                  icon: Icons.title_rounded,
                ),
                validator:
                    (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Informe um título'
                            : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                enabled: !_enviando,
                textInputAction: TextInputAction.next,
                maxLines: 2,
                decoration: FxInputDeco.build(
                  context,
                  'Descrição',
                  icon: Icons.notes_rounded,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valorCtrl,
                enabled: !_enviando,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                decoration: FxInputDeco.build(
                  context,
                  'Valor que o cliente paga (R\$) *',
                  icon: Icons.attach_money_rounded,
                  hint: 'Ex.: 500',
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
              ),
              const SizedBox(height: 18),
              _SheetSectionLabel('Duração do plano', ink: ink),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final meses in [1, 3, 6, 12])
                    _PacoteOptionChip(
                      label: meses == 1 ? '1 mês' : '$meses meses',
                      selected: _duracao == meses,
                      onTap:
                          _enviando
                              ? null
                              : () {
                                HapticFeedback.selectionClick();
                                setState(() => _duracao = meses);
                              },
                    ),
                ],
              ),
              const SizedBox(height: 18),
              _SheetSectionLabel('O que inclui', ink: ink),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PacoteOptionChip(
                    label: 'Treino',
                    selected: _treino,
                    onTap:
                        _enviando
                            ? null
                            : () => setState(() => _treino = !_treino),
                  ),
                  _PacoteOptionChip(
                    label: 'Nutrição',
                    selected: _nutri,
                    onTap:
                        _enviando
                            ? null
                            : () => setState(() => _nutri = !_nutri),
                  ),
                  _PacoteOptionChip(
                    label: 'Consultoria',
                    selected: _consultoria,
                    onTap:
                        _enviando
                            ? null
                            : () =>
                                setState(() => _consultoria = !_consultoria),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SheetSectionLabel('Mostrar em destaque', ink: ink),
              const SizedBox(height: 10),
              _PacoteOptionChip(
                label: 'Aparecer primeiro na página',
                selected: _destaque,
                onTap:
                    _enviando
                        ? null
                        : () => setState(() => _destaque = !_destaque),
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

class _SheetSectionLabel extends StatelessWidget {
  const _SheetSectionLabel(this.label, {required this.ink});

  final String label;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: ink,
        fontWeight: FontWeight.w700,
        fontSize: 13.5,
        letterSpacing: -0.1,
      ),
    );
  }
}

class _PacoteOptionChip extends StatelessWidget {
  const _PacoteOptionChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: onTap == null ? null : (_) => onTap!(),
        showCheckmark: selected,
        checkmarkColor: Colors.white,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 10 : 9,
          vertical: selected ? 7 : 6,
        ),
        labelStyle: TextStyle(
          color: selected ? Colors.white : ink,
          fontSize: selected ? 12 : 11.5,
          fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
        ),
        selectedColor: primary,
        backgroundColor:
            isDark ? Colors.white.withValues(alpha: 0.035) : TokensStrip.pageBg,
        side: BorderSide(
          color:
              selected
                  ? primary
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : TokensStrip.borderDefault),
        ),
      ),
    );
  }
}

/// Copia link real; toast amigável sem URL crua.
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

/// Abre vitrine no navegador externo.
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
