part of 'aluno_detail_screen.dart';

extension _AlunoDetailActions on _AlunoDetailScreenState {
  String _deleteConfirmToken(String nome) {
    final trimmed = nome.trim();
    if (trimmed.isEmpty) return 'aluno';
    if (trimmed.length <= 3) return trimmed.toLowerCase();
    return trimmed.substring(0, 3).toLowerCase();
  }

  Future<void> _confirmarExclusao(
    BuildContext context,
    WidgetRef ref,
    Aluno aluno,
  ) async {
    final confirmToken = _deleteConfirmToken(aluno.nome);
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => _AlunoDeleteConfirmSheet(
            aluno: aluno,
            confirmToken: confirmToken,
          ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await AlunoRepository(ref.read(apiClientProvider)).excluirAluno(aluno.id);
      if (context.mounted) {
        FeedbackHelper.showSuccess(context, 'Aluno excluído.');
        safePopOrGo(context, '/alunos');
      }
    } catch (e) {
      if (context.mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _confirmarGerarSenha(
    BuildContext context,
    WidgetRef ref,
    Aluno aluno,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Gerar nova senha?'),
            content: Text(
              'A senha atual de ${aluno.nome} deixará de funcionar. Gere apenas se o aluno esqueceu a senha ou precisa recuperar acesso.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FxLiquidPrimaryButton(
                expand: false,
                icon: Icons.key_rounded,
                label: 'Gerar senha',
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
    );
    if (confirm != true || !context.mounted) return;

    try {
      final senha = await AlunoRepository(
        ref.read(apiClientProvider),
      ).gerarSenhaProvisoria(aluno.id);
      ref.invalidate(alunoProvider(aluno.id));
      if (context.mounted) {
        _showNovaSenhaSheet(context, aluno, senha);
      }
    } catch (e) {
      if (context.mounted) {
        FeedbackHelper.showSnackBar(
          context,
          SnackBar(
            content: Text(
              friendlyError(e, fallback: 'Não foi possível gerar senha.'),
            ),
          ),
        );
      }
    }
  }

  void _showNovaSenhaSheet(BuildContext context, Aluno aluno, String senha) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final ink = chrome.ink;
    final mute = chrome.mute;
    final whatsappNumber = (aluno.whatsapp ?? '').replaceAll(RegExp(r'\D'), '');
    final hasWhatsapp = whatsappNumber.isNotEmpty;
    final mensagem = _senhaProvisoriaMessage(aluno, senha);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(ctx).padding.bottom,
            ),
            child: ShellSurface(
              accent: primary,
              radius: TokensStrip.rCard,
              padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: chrome.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.key_rounded, color: primary, size: 28),
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  Text(
                    'Nova senha provisória',
                    style: TextStyle(
                      color: ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A senha anterior não funciona mais. ${aluno.nome} deve trocar no primeiro acesso.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mute,
                      fontSize: 13.4,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 15, 18, 14),
                    decoration: fxListCardDecoration(
                      ctx,
                      accent: primary,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Senha provisória',
                          style: TextStyle(
                            color: mute,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          senha,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ink,
                            fontSize: 31,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 5.5,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          'Compartilhe apenas com o aluno.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: mute,
                            fontSize: 11.8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        if (hasWhatsapp) {
                          final uri = Uri.parse(
                            'https://wa.me/55$whatsappNumber?text=${Uri.encodeComponent(mensagem)}',
                          );
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            return;
                          }
                        }
                        await copySensitiveToClipboard(mensagem);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (context.mounted) {
                          FeedbackHelper.showSnackBar(
                            context,
                            SnackBar(
                              content: Text(
                                hasWhatsapp
                                    ? 'Mensagem copiada. Abra o WhatsApp e envie ao aluno.'
                                    : 'Convite copiado.',
                              ),
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        hasWhatsapp ? Icons.send_rounded : Icons.copy_rounded,
                        size: 18,
                      ),
                      label: Text(
                        hasWhatsapp ? 'Enviar nova senha' : 'Copiar nova senha',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  if (hasWhatsapp) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await copySensitiveToClipboard(mensagem);
                          HapticFeedback.mediumImpact();
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (context.mounted) {
                            FeedbackHelper.showSnackBar(
                              context,
                              const SnackBar(content: Text('Convite copiado.')),
                            );
                          }
                        },
                        icon: Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: ink,
                        ),
                        label: Text(
                          'Copiar nova senha',
                          style: TextStyle(color: ink),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: chrome.line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        'Fechar',
                        style: TextStyle(
                          color: mute,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  String _senhaProvisoriaMessage(Aluno aluno, String senha) {
    final primeiroNome =
        aluno.nome.trim().isEmpty
            ? 'tudo bem'
            : aluno.nome.trim().split(RegExp(r'\s+')).first;
    return 'Olá $primeiroNome! Sua senha do Focux foi redefinida.\n\n'
        'Acesse com seu e-mail: ${aluno.email}\n'
        'Senha provisória: $senha\n\n'
        'Troque a senha no primeiro acesso.';
  }
}

class _AlunoDeleteConfirmSheet extends StatefulWidget {
  const _AlunoDeleteConfirmSheet({
    required this.aluno,
    required this.confirmToken,
  });

  final Aluno aluno;
  final String confirmToken;

  @override
  State<_AlunoDeleteConfirmSheet> createState() =>
      _AlunoDeleteConfirmSheetState();
}

class _AlunoDeleteConfirmSheetState extends State<_AlunoDeleteConfirmSheet> {
  late final TextEditingController _controller;
  var _inputMatches = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final displayName = fxTitleCaseName(widget.aluno.nome);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      child: ShellSurface(
        accent: EagleTokens.bad,
        radius: TokensStrip.rCard,
        padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: EagleTokens.bad.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: EagleTokens.bad,
                size: 26,
              ),
            ),
            const SizedBox(height: TokensStrip.s4),
            Text(
              'Excluir aluno?',
              style: AppTypography.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$displayName será removido permanentemente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: mute, fontSize: 13.4, height: 1.35),
            ),
            const SizedBox(height: 6),
            Text(
              'Treinos, check-ins e histórico vinculados também serão apagados.',
              textAlign: TextAlign.center,
              style: TextStyle(color: mute, fontSize: 12.5, height: 1.35),
            ),
            const SizedBox(height: 6),
            Text(
              'Esta ação não pode ser desfeita.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: EagleTokens.bad.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Digite "${widget.confirmToken}" para confirmar:',
                style: TextStyle(
                  color: mute,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              onChanged:
                  (value) => setState(
                    () =>
                        _inputMatches =
                            value.trim().toLowerCase() == widget.confirmToken,
                  ),
              onSubmitted:
                  (_) {
                    if (_inputMatches) {
                      HapticFeedback.heavyImpact();
                      Navigator.of(context).pop(true);
                    }
                  },
              decoration: InputDecoration(
                hintText: widget.confirmToken,
                isDense: true,
                filled: true,
                fillColor: EagleTokens.bad.withValues(alpha: isDark ? 0.08 : 0.05),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: EagleTokens.bad.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                    _inputMatches
                        ? () {
                          HapticFeedback.heavyImpact();
                          Navigator.of(context).pop(true);
                        }
                        : null,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text('Excluir $displayName'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EagleTokens.bad,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: EagleTokens.bad.withValues(
                    alpha: 0.35,
                  ),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.72),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: mute,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
