import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/money/fx_money.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/safe_external_launch.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/screens/chat_inbox_screen.dart';
import '../data/financeiro_repository.dart';
import 'financeiro_hub_display.dart';
import 'pix_qr_display.dart';

FinanceiroRepository mensalidadeRepo(WidgetRef ref) =>
    FinanceiroRepository(ref.read(apiClientProvider));

bool _mensagemIndicaCarteiraSemChave(String msg) {
  final lower = msg.toLowerCase();
  if (lower.contains('informe a chave') || lower.contains('sem chave')) {
    return true;
  }
  if (lower.contains('cadastre') && lower.contains('pix')) return true;
  return lower.contains('chave') &&
      (lower.contains('pix') ||
          lower.contains('carteira') ||
          lower.contains('wallet'));
}

/// Conta Mercado Pago do collector sem chave PIX (não é carteira Focux).
bool _mensagemIndicaMpSemChavePix(String msg) {
  final lower = msg.toLowerCase();
  return lower.contains('without key') ||
      lower.contains('13253') ||
      lower.contains('chave pix ativa') ||
      (lower.contains('mercado pago') && lower.contains('chave pix'));
}

const _mpPixKeyHelpUrl =
    'https://www.mercadopago.com.br/ajuda/cadastrar-chave-pix_11801';

Widget _pixQrVisual({
  required String pixCopiaECola,
  required Uint8List? qrBytes,
  required bool isDark,
}) {
  final copia = pixCopiaECola.trim();
  if (copia.isNotEmpty) {
    return Center(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: QrImageView(
          data: copia,
          size: 200,
          backgroundColor: Colors.white,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Colors.black,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
  if (qrBytes != null) {
    return Image.memory(
      qrBytes,
      width: 200,
      height: 200,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
  return Text(
    'PIX gerado. Use o botão abaixo para copiar o código.',
    textAlign: TextAlign.center,
    style: TextStyle(
      color: isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary,
      fontSize: 13,
      height: 1.35,
    ),
  );
}

Future<String?> pickMensalidadeMesReferencia(
  BuildContext ctx, {
  required String atual,
}) async {
  final ops = financeiroMesReferenciaOpcoes(atual: atual);
  final selected = financeiroMesReferenciaKey(atual);
  final picked = await showFxInsetPickerSheet<String>(
    ctx,
    title: 'Mês de referência',
    selected: selected,
    items: [
      for (final o in ops)
        FxInsetPickerSheetItem(value: o.key, label: o.label),
    ],
  );
  if (picked == null) return null;
  return financeiroMesReferenciaIso(picked);
}

Future<String?> pickMensalidadeVencimento(
  BuildContext ctx, {
  required String mesReferencia,
  required String atual,
}) async {
  final ops = financeiroVencimentoOpcoes(
    mesReferencia: mesReferencia,
    atual: atual,
  );
  final picked = await showFxInsetPickerSheet<String>(
    ctx,
    title: 'Vencimento',
    selected: atual.trim(),
    items: [
      for (final o in ops)
        FxInsetPickerSheetItem(value: o.iso, label: o.label),
    ],
  );
  if (picked == null) return null;
  return picked;
}

Future<Mensalidade?> confirmarPagarMensalidade({
  required BuildContext context,
  required WidgetRef ref,
  required Mensalidade m,
}) async {
  final ok = await showFxConfirmSheet(
    context,
    title: 'Marcar como paga?',
    subtitle: m.alunoNome,
    message: 'Confirme só se o valor já entrou. O status passa a pago.',
    confirmLabel: 'Marcar paga',
  );
  if (!ok || !context.mounted) return null;
  try {
    final updated = await mensalidadeRepo(ref).pagar(m.id);
    if (context.mounted) {
      FeedbackHelper.showSuccess(context, 'Mensalidade marcada como paga.');
    }
    return updated;
  } catch (e) {
    if (context.mounted) {
      FeedbackHelper.showError(context, friendlyError(e));
    }
    return null;
  }
}

Future<void> mostrarPixMensalidade({
  required BuildContext context,
  required WidgetRef ref,
  required int id,
  bool asAluno = false,
}) async {
  PixData? pix;
  var carregando = true;
  String? erro;
  var precisaCarteira = false;
  var precisaMpPix = false;
  var loadToken = 0;
  var loadStarted = false;

  Future<void> carregar(void Function(void Function()) setDialogState) async {
    final token = ++loadToken;
    setDialogState(() {
      carregando = true;
      erro = null;
      precisaCarteira = false;
      precisaMpPix = false;
    });
    try {
      // BE gera via Mercado Pago; carteira do personal não bloqueia a emissão.
      final repo = mensalidadeRepo(ref);
      final p = asAluno ? await repo.gerarPixAluno(id) : await repo.gerarPix(id);
      if (token != loadToken) return;
      if (!pixQrHasRenderablePayload(
        pixCopiaECola: p.pixCopiaECola,
        qrCodeBase64: p.qrCodeBase64,
      )) {
        setDialogState(() {
          erro =
              'Mercado Pago não retornou QR/código PIX. Confira o token MP e o e-mail do aluno.';
          carregando = false;
        });
        return;
      }
      setDialogState(() {
        pix = p;
        carregando = false;
      });
    } catch (e) {
      if (token != loadToken) return;
      final msg = friendlyError(e);
      final mpPix = _mensagemIndicaMpSemChavePix(msg);
      setDialogState(() {
        erro = msg;
        precisaMpPix = mpPix;
        precisaCarteira =
            !asAluno && !mpPix && _mensagemIndicaCarteiraSemChave(msg);
        carregando = false;
      });
    }
  }

  await showFxHomeSheet<void>(
    context,
    builder:
        (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) {
            // Start once — calling carregar from every rebuild + loadToken
            // cancelled the in-flight PIX forever ("Gerando…" stuck).
            if (!loadStarted) {
              loadStarted = true;
              unawaited(carregar(setDialogState));
            }

            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final primary = Theme.of(ctx).colorScheme.primary;
            final qrBytes =
                !carregando && erro == null && pix != null
                    ? decodePixQrBase64(pix!.qrCodeBase64)
                    : null;
            return FxHomeSheetSurface(
              isDark: isDark,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FxHomeSheetHandle(isDark: isDark),
                  SizedBox(height: TokensStrip.s4),
                  FxHomeSheetHeader(
                    isDark: isDark,
                    title: 'PIX - Escaneie ou copie',
                    leading: FxIcon(name: 'pix', color: primary, size: 18),
                  ),
                  SizedBox(height: TokensStrip.s4),
                  if (carregando)
                    SizedBox(
                      height: 96,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const FxLoading(),
                          const SizedBox(height: TokensStrip.s2),
                          Text(
                            'Gerando PIX…',
                            style: TextStyle(
                              color:
                                  isDark
                                      ? EagleTokens.darkInkMute
                                      : TokensStrip.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (erro != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          Text(
                            erro!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: EagleTokens.bad,
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: TokensStrip.s3),
                          if (precisaMpPix)
                            FxLiquidPrimaryButton(
                              label: 'Como ativar PIX no MP',
                              onPressed: () async {
                                await launchSafeHttpUrl(_mpPixKeyHelpUrl);
                              },
                            )
                          else if (precisaCarteira)
                            FxLiquidPrimaryButton(
                              label: 'Abrir carteira',
                              onPressed: () {
                                FxHomeSheetChrome.dismissAndPop(ctx);
                                context.push('/perfil/wallet');
                              },
                            )
                          else
                            TextButton(
                              onPressed: () => carregar(setDialogState),
                              child: const Text('Tentar de novo'),
                            ),
                        ],
                      ),
                    )
                  else ...[
                    _pixQrVisual(
                      pixCopiaECola: pix?.pixCopiaECola ?? '',
                      qrBytes: qrBytes,
                      isDark: isDark,
                    ),
                    const SizedBox(height: TokensStrip.s4),
                    TextButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiar codigo PIX'),
                      onPressed: () async {
                        final code = pix?.pixCopiaECola.trim() ?? '';
                        if (code.isEmpty) {
                          FeedbackHelper.showError(
                            ctx,
                            'Código PIX indisponível. Tente gerar de novo.',
                          );
                          return;
                        }
                        await copySensitiveToClipboard(code);
                        if (ctx.mounted) {
                          FeedbackHelper.showSuccess(
                            ctx,
                            'Código PIX copiado. Some em 1 min.',
                          );
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => FxHomeSheetChrome.dismissAndPop(ctx),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            );
          },
        ),
  );
}

Future<void> cobrarMensalidadeViaChat({
  required BuildContext context,
  required WidgetRef ref,
  required Mensalidade m,
}) async {
  AnalyticsService.instance.track(
    ProductEvents.financeiroCobrarViaChat,
    props: {
      'feature': 'financeiro',
      'mensalidade_id': m.id,
      'aluno_id': m.alunoId,
    },
  );
  try {
    final msg = await mensalidadeRepo(ref).cobrarViaChat(m.id);
    ref.invalidate(chatInboxHomeProvider);
    if (context.mounted) {
      FeedbackHelper.showSuccess(context, msg);
      final open = await showFxConfirmSheet(
        context,
        title: 'Abrir chat?',
        message: 'A cobrança foi enviada. Quer ver a conversa agora?',
        confirmLabel: 'Abrir chat',
        cancelLabel: 'Depois',
      );
      if (open && context.mounted) {
        context.push('/alunos/${m.alunoId}/chat', extra: m.alunoNome);
      }
    }
  } catch (e) {
    if (context.mounted) {
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }
}

Future<bool> registrarContatoMensalidade({
  required BuildContext context,
  required WidgetRef ref,
  required Mensalidade m,
}) async {
  const tipos = ['WHATSAPP', 'LIGACAO', 'EMAIL', 'PRESENCIAL', 'OUTRO'];
  final tipo = await showFxInsetPickerSheet<String>(
    context,
    title: 'Tipo de contato',
    items: [
      for (final t in tipos)
        FxInsetPickerSheetItem(
          value: t,
          label: financeiroContatoTipoLabel(t),
        ),
    ],
  );
  if (!context.mounted || tipo == null) return false;
  final obsCtrl = TextEditingController();
  try {
    final confirm = await showFxFormSheet(
      context,
      title: 'Registrar contato',
      subtitle: financeiroContatoTipoLabel(tipo),
      confirmLabel: 'Registrar',
      child: TextField(
        controller: obsCtrl,
        decoration: InputDecoration(
          labelText: 'Observação (opcional)',
          border: FxInputDeco.outlineBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        maxLines: 2,
        onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
      ),
    );
    if (confirm != true) return false;
    try {
      await mensalidadeRepo(ref).registrarContato(m.id, tipo, obsCtrl.text.trim());
      if (context.mounted) {
        FeedbackHelper.showSuccess(context, 'Contato registrado!');
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
      return false;
    }
  } finally {
    obsCtrl.dispose();
  }
}

Future<Mensalidade?> showEditarMensalidadeSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Mensalidade m,
}) async {
  const statuses = ['PENDENTE', 'PAGO', 'ATRASADO'];
  final valorCtrl = TextEditingController(text: m.valor.wire);
  var mesReferencia = m.mesReferencia;
  var vencimento =
      (m.vencimento != null && m.vencimento!.trim().isNotEmpty)
          ? m.vencimento!.trim()
          : m.mesReferencia;
  var selectedStatus = m.status;
  var salvando = false;
  final formKey = GlobalKey<FormState>();

  try {
    return await showFxHomeSheet<Mensalidade>(
      context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final primary = Theme.of(ctx).colorScheme.primary;
        return FxHomeSheetSurface(
          isDark: isDark,
          maxHeight:
              MediaQuery.sizeOf(ctx).height * FxHomeSheetChrome.maxHeightFactor,
          child: StatefulBuilder(
            builder:
                (ctx, setModalState) => Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FxHomeSheetHandle(isDark: isDark),
                      SizedBox(height: TokensStrip.s4),
                      FxHomeSheetHeader(
                        isDark: isDark,
                        title: 'Editar mensalidade',
                        subtitle: 'Valor, mês, vencimento e status.',
                        leading: Icon(
                          Icons.edit_outlined,
                          color: primary,
                          size: 18,
                        ),
                      ),
                      SizedBox(height: TokensStrip.s3),
                      FxSettingsGroup(
                        children: [
                          AlunoInsetFormField(
                            controller: valorCtrl,
                            label: 'Valor (R\$)',
                            hint: '0,00',
                            icon: Icons.attach_money,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Informe o valor';
                              }
                              final parsed = double.tryParse(
                                v.trim().replaceAll(',', '.'),
                              );
                              if (parsed == null || parsed <= 0) {
                                return 'Valor inválido';
                              }
                              return null;
                            },
                          ),
                          FxSettingsTile(
                            fxIcon: 'calendar',
                            label: 'Mês de referência',
                            value: financeiroMesPickerValue(mesReferencia),
                            onTap: () async {
                              final picked = await pickMensalidadeMesReferencia(
                                ctx,
                                atual: mesReferencia,
                              );
                              if (picked != null) {
                                setModalState(() {
                                  vencimento = financeiroVencimentoAposTrocaDeMes(
                                    mesAntigo: mesReferencia,
                                    mesNovo: picked,
                                    vencimentoAtual: vencimento,
                                  );
                                  mesReferencia = picked;
                                });
                              }
                            },
                          ),
                          FxSettingsTile(
                            fxIcon: 'calendar',
                            label: 'Vencimento',
                            value: financeiroVencimentoPickerValue(vencimento),
                            onTap: () async {
                              final picked = await pickMensalidadeVencimento(
                                ctx,
                                mesReferencia: mesReferencia,
                                atual: vencimento,
                              );
                              if (picked != null) {
                                setModalState(() => vencimento = picked);
                              }
                            },
                          ),
                          FxSettingsTile(
                            fxIcon:
                                selectedStatus == 'ATRASADO'
                                    ? 'alert-triangle'
                                    : selectedStatus == 'PAGO'
                                    ? 'circle-check'
                                    : 'coin',
                            label: 'Status',
                            value: financeiroMensalidadeStatusLabel(
                              selectedStatus,
                            ),
                            showDivider: false,
                            onTap: () async {
                              final picked = await showFxInsetPickerSheet<String>(
                                ctx,
                                title: 'Status',
                                selected: selectedStatus,
                                items: [
                                  for (final s in statuses)
                                    FxInsetPickerSheetItem(
                                      value: s,
                                      label: financeiroMensalidadeStatusLabel(s),
                                    ),
                                ],
                              );
                              if (picked != null) {
                                setModalState(() => selectedStatus = picked);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: TokensStrip.s3),
                      FxLiquidPrimaryButton(
                        label: financeiroSalvarMensalidadeTileLabel(),
                        loading: salvando,
                        loadingLabel: 'Salvando…',
                        onPressed:
                            salvando
                                ? null
                                : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      if (mesReferencia.trim().isEmpty) {
                                        FeedbackHelper.showError(
                                          ctx,
                                          'Selecione o mês de referência',
                                        );
                                        return;
                                      }
                                      HapticFeedback.mediumImpact();
                                      final ok = await showFxConfirmSheet(
                                        ctx,
                                        title:
                                            financeiroSalvarMensalidadeConfirmTitle(),
                                        message:
                                            financeiroSalvarMensalidadeConfirmMessage(),
                                        icon: Icons.payments_outlined,
                                        confirmLabel:
                                            financeiroSalvarMensalidadeTileLabel(),
                                      );
                                      if (!ok) return;
                                      setModalState(() => salvando = true);
                                      try {
                                        final valor = FxMoney.fromInput(
                                          valorCtrl.text,
                                        );
                                        final updated = await mensalidadeRepo(
                                          ref,
                                        ).editarMensalidade(
                                          m.id,
                                          valor: valor,
                                          mesReferencia: mesReferencia.trim(),
                                          vencimento: vencimento.trim(),
                                          status: selectedStatus,
                                        );
                                        if (ctx.mounted) {
                                          Navigator.of(ctx).pop(updated);
                                        }
                                      } catch (e) {
                                        setModalState(() => salvando = false);
                                        if (ctx.mounted) {
                                          FeedbackHelper.showError(
                                            ctx,
                                            friendlyError(e),
                                          );
                                        }
                                      }
                                    },
                      ),
                    ],
                  ),
                ),
          ),
        );
      },
    );
  } finally {
    valorCtrl.dispose();
  }
}
