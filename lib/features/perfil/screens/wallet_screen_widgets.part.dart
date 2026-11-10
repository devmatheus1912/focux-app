part of 'wallet_screen.dart';

/// Um bloco só: a chave salva com Alterar/Copiar, ou o formulário.
class _WalletChave extends StatelessWidget {
  const _WalletChave({
    required this.tipoChavePix,
    required this.chavePixCtrl,
    required this.carregando,
    required this.tipoSalvo,
    required this.chaveSalva,
    required this.editando,
    required this.podeCancelar,
    required this.onEditarChave,
    required this.onCancelar,
    required this.onSelecionarTipo,
    required this.onCopiarChave,
  });

  final String? tipoChavePix;
  final TextEditingController chavePixCtrl;
  final bool carregando;

  /// O que já está salvo no servidor (o bloco não segue o que se digita).
  final String? tipoSalvo;
  final String chaveSalva;

  /// Formulário aberto: sem chave salva, ou depois de "Alterar chave".
  final bool editando;
  final bool podeCancelar;
  final VoidCallback onEditarChave;
  final VoidCallback onCancelar;
  final ValueChanged<String> onSelecionarTipo;
  final VoidCallback onCopiarChave;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);

    return FxStripCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            walletPixSectionTitle(),
            style: FocuxHubTypography.chip(mute),
          ),
          const SizedBox(height: TokensStrip.s1),
          if (!editando) ...[
            Semantics(
              label: walletChaveSemantica(tipoSalvo, chaveSalva),
              excludeSemantics: true,
              child: Text(
                walletRotuloMascarado(tipoSalvo, chaveSalva),
                style: FocuxHubTypography.cardTitle(color: ink),
              ),
            ),
            const SizedBox(height: TokensStrip.s1),
            Text(
              walletParaQueServe(),
              style: FocuxHubTypography.bodyMuted(color: mute),
            ),
            const SizedBox(height: TokensStrip.s3),
            Wrap(
              spacing: TokensStrip.s2,
              runSpacing: TokensStrip.s2,
              children: [
                FxActionChip(
                  label: 'Alterar chave',
                  accent: primary,
                  isDark: isDark,
                  enabled: !carregando,
                  onPressed: onEditarChave,
                ),
                FxActionChip(
                  label: walletCopiarTileLabel(),
                  accent: primary,
                  isDark: isDark,
                  enabled: !carregando,
                  onPressed: onCopiarChave,
                ),
              ],
            ),
          ] else ...[
            Text(
              walletParaQueServe(),
              style: FocuxHubTypography.bodyMuted(color: mute),
            ),
            const SizedBox(height: TokensStrip.s3),
            Text(
              'Tipo de chave',
              style: FxSettingsLayout.subhead(color: mute),
            ),
            const SizedBox(height: TokensStrip.s2),
            FxChoiceStrip<String>(
              itens: [
                for (final tipo in walletTiposChave)
                  FxChoiceItem(value: tipo, label: walletTipoCurto(tipo)),
              ],
              selecionado: tipoChavePix,
              onSelecionar: carregando ? (_) {} : onSelecionarTipo,
            ),
            const SizedBox(height: TokensStrip.s3),
            AlunoInsetFormField(
              controller: chavePixCtrl,
              label: 'Chave PIX',
              icon: FxIcons.pix,
              hint: WalletPixValidation.hintForTipo(tipoChavePix),
              keyboardType: WalletPixValidation.keyboardForTipo(tipoChavePix),
              inputFormatters: [
                ...WalletPixValidation.formattersForTipo(tipoChavePix),
                LengthLimitingTextInputFormatter(walletChavePixMax),
              ],
              validator:
                  (v) => WalletPixValidation.validateChave(tipoChavePix, v ?? ''),
              showDivider: false,
            ),
            if (podeCancelar) ...[
              const SizedBox(height: TokensStrip.s2),
              Align(
                alignment: Alignment.centerLeft,
                child: FxActionChip(
                  label: 'Manter a chave atual',
                  accent: primary,
                  isDark: isDark,
                  enabled: !carregando,
                  onPressed: onCancelar,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
