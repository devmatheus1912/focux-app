part of 'wallet_screen.dart';

class _WalletFormFields extends StatelessWidget {
  const _WalletFormFields({
    required this.tipoChavePix,
    required this.chavePixCtrl,
    required this.bancoCtrl,
    required this.agenciaCtrl,
    required this.contaCtrl,
    required this.carregando,
    required this.secao,
    required this.onSecao,
    required this.onSelecionarTipo,
    required this.onCopiarChave,
    required this.tipoSalvo,
    required this.chaveSalva,
    required this.editandoChave,
    required this.onEditarChave,
  });

  final String? tipoChavePix;
  final TextEditingController chavePixCtrl;
  final TextEditingController bancoCtrl;
  final TextEditingController agenciaCtrl;
  final TextEditingController contaCtrl;
  final bool carregando;
  final String secao;
  final ValueChanged<String> onSecao;
  final ValueChanged<String> onSelecionarTipo;
  final VoidCallback onCopiarChave;

  /// O que já está salvo no servidor (o estado do cartão não segue o que se digita).
  final String? tipoSalvo;
  final String chaveSalva;

  /// Com chave salva, o campo só abre depois de "Alterar chave".
  final bool editandoChave;
  final VoidCallback onEditarChave;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cadastrada = chaveSalva.trim().isNotEmpty &&
        (tipoSalvo ?? '').trim().isNotEmpty;
    final masked = maskPixKeyForDisplay(tipoSalvo, chaveSalva);
    final mostrarCampo = !cadastrada || editandoChave;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FxHubHeader(
          title: 'Recebimentos',
          subtitle: walletHubSubtitle(),
        ),
        const SizedBox(height: TokensStrip.s3),
        OperationalMetricTile(
          label: 'PIX',
          value: walletPixStatusValue(tipoSalvo, chaveSalva),
          hint: masked.isEmpty
              ? walletPixStatusHint(tipoSalvo, chaveSalva)
              : '${WalletPixValidation.labelForTipo(tipoSalvo ?? '')} · $masked',
          color: primary,
          isDark: isDark,
        ),
        const SizedBox(height: TokensStrip.s4),
        AlunoSegmentedChoice(
          options: walletDetalheSecoes,
          selected: secao,
          isDark: isDark,
          onSelect: onSecao,
        ),
        const SizedBox(height: TokensStrip.s4),
        if (secao == walletDetalheSecaoPix) ...[
          DashboardSectionHeader(title: walletPixSectionTitle()),
          const SizedBox(height: TokensStrip.s2),
          if (mostrarCampo) ...[
            Text(
              'Tipo de chave',
              style: FxSettingsLayout.subhead(color: fxScreenMute(context)),
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
              icon: Icons.pix_rounded,
              hint: WalletPixValidation.hintForTipo(tipoChavePix),
              keyboardType: WalletPixValidation.keyboardForTipo(tipoChavePix),
              inputFormatters: [
                ...WalletPixValidation.formattersForTipo(tipoChavePix),
                LengthLimitingTextInputFormatter(walletChavePixMax),
              ],
              validator: (v) =>
                  WalletPixValidation.validateChave(tipoChavePix, v ?? ''),
              showDivider: false,
            ),
          ] else ...[
            Text(
              '${WalletPixValidation.labelForTipo(tipoSalvo ?? '')} · $masked',
              style: FxSettingsLayout.rowLabel(color: fxScreenInk(context)),
            ),
            const SizedBox(height: TokensStrip.s2),
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
          ],
        ] else ...[
          DashboardSectionHeader(title: walletBancoSectionTitle()),
          const SizedBox(height: TokensStrip.s2),
          AlunoInsetFormField(
            controller: bancoCtrl,
            label: 'Banco',
            icon: Icons.account_balance_outlined,
            hint: 'Ex.: Nubank, Itaú, Bradesco',
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              LengthLimitingTextInputFormatter(walletBancoMax),
            ],
          ),
          AlunoInsetFormField(
            controller: agenciaCtrl,
            label: 'Agência',
            icon: Icons.tag_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(walletAgenciaMax),
            ],
          ),
          AlunoInsetFormField(
            controller: contaCtrl,
            label: 'Conta',
            icon: Icons.numbers_rounded,
            keyboardType: TextInputType.text,
            inputFormatters: WalletPixValidation.formattersForConta(),
            showDivider: false,
          ),
        ],
      ],
    );
  }
}
