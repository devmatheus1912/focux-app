import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/money/fx_money.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/financeiro_repository.dart';
import 'financeiro_hub_display.dart';

FinanceiroRepository mensalidadeRepo(WidgetRef ref) =>
    FinanceiroRepository(ref.read(apiClientProvider));

Future<String?> pickMensalidadeMesReferencia(
  BuildContext ctx, {
  required String atual,
}) async {
  final now = DateTime.now();
  final initial = DateTime.tryParse(atual) ?? DateTime(now.year, now.month, 1);
  final picked = await showDatePicker(
    context: ctx,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime(now.year + 5),
    helpText: 'Selecione o mês de referência',
    fieldLabelText: 'Mês/Ano',
    initialEntryMode: DatePickerEntryMode.calendarOnly,
    selectableDayPredicate: (day) => day.day == 1,
  );
  if (picked == null) return null;
  final mes = picked.month.toString().padLeft(2, '0');
  return '${picked.year}-$mes-01';
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
}) async {
  PixData? pix;
  var carregando = true;
  String? erro;

  await showFxHomeSheet<void>(
    context,
    builder:
        (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) {
            if (carregando && pix == null && erro == null) {
              mensalidadeRepo(ref)
                  .gerarPix(id)
                  .then((p) {
                    setDialogState(() {
                      pix = p;
                      carregando = false;
                    });
                  })
                  .catchError((e) {
                    setDialogState(() {
                      erro = friendlyError(e);
                      carregando = false;
                    });
                  });
            }

            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final primary = Theme.of(ctx).colorScheme.primary;
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
                    const SizedBox(height: 80, child: FxLoading())
                  else if (erro != null)
                    Text(
                      erro!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: EagleTokens.bad,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else ...[
                    Image.memory(
                      base64Decode(pix!.qrCodeBase64),
                      width: 200,
                      height: 200,
                    ),
                    const SizedBox(height: TokensStrip.s4),
                    TextButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiar codigo PIX'),
                      onPressed: () async {
                        await copySensitiveToClipboard(pix!.pixCopiaECola);
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
                    onPressed: () => Navigator.of(ctx).pop(),
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
    if (context.mounted) {
      FeedbackHelper.showSuccess(context, msg);
    }
  } catch (e) {
    if (context.mounted) {
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }
}

Future<void> registrarContatoMensalidade({
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
  if (!context.mounted || tipo == null) return;
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
      ),
    );
    if (confirm != true) return;
    try {
      await mensalidadeRepo(ref).registrarContato(m.id, tipo, obsCtrl.text.trim());
      if (context.mounted) {
        FeedbackHelper.showSuccess(context, 'Contato registrado!');
      }
    } catch (e) {
      if (context.mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
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
                        subtitle: 'Atualize valor, mês e status.',
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
                                setModalState(() => mesReferencia = picked);
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
