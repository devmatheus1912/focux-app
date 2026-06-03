part of 'aluno_detail_screen.dart';

extension _AlunoDetailActions on _AlunoDetailScreenState {
  Future<void> _confirmarExclusao(
    BuildContext context,
    WidgetRef ref,
    Aluno aluno,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Excluir aluno'),
            content: Text(
              'Tem certeza que deseja excluir ${aluno.nome}? Esta ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: EagleTokens.bad),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Excluir'),
              ),
            ],
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
