import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/api/api_error.dart';
import '../../../core/money/fx_money.dart';
import '../../../core/money/fx_money_input.dart';
import '../../../core/utils/pt_br_display.dart';
import 'vencimento_atalhos.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/screens/chat_inbox_screen.dart';
import '../data/financeiro_repository.dart';
import 'financeiro_hub_display.dart';
import 'pix_qr_display.dart';
import '../widgets/vencimento_escolha.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../core/theme/fx_icons.dart';

FinanceiroRepository mensalidadeRepo(WidgetRef ref) =>
    FinanceiroRepository(ref.read(apiClientProvider));

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

/// Meses que o aluno já tem (para bloquear na folha de vencimento).
/// Falha de rede não bloqueia nada: o backend recusa mês repetido com 409.
Future<Map<String, MesOcupado>> carregarMesesOcupados(
  WidgetRef ref,
  int alunoId, {
  int? ignorarId,
}) async {
  try {
    final page = await mensalidadeRepo(ref).listarPagina(alunoId: alunoId, size: 50);
    return vencimentoMesesOcupados(page.mensalidades, ignorarId: ignorarId);
  } catch (_) {
    return const {};
  }
}

/// Folha de vencimento (mês e dia numa escolha só).
Future<DateTime?> pickMensalidadeVencimento(
  BuildContext ctx, {
  required DateTime atual,
  Map<String, MesOcupado> ocupados = const {},
}) => showVencimentoSheet(ctx, atual: atual, ocupados: ocupados);

/// "Vence 12/11 · novembro de 2026".
String mensalidadeVencimentoRotulo(DateTime d) =>
    'Vence ${dataCurta(d)} · ${financeiroMesTitulo(d.month, d.year).toLowerCase()}';

/// Texto da confirmação: o personal confere o que vai ser gravado.
String mensalidadeConfirmacaoTexto({
  required String aluno,
  required FxMoney valor,
  required DateTime vencimento,
}) => '$aluno · ${valor.formatCobranca()} · ${mensalidadeVencimentoRotulo(vencimento).toLowerCase()}';

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

/// Devolve `true` se o código foi copiado ou o pagamento avisado — sinal para
/// quem abriu recarregar a lista.
Future<bool> mostrarPixMensalidade({
  required BuildContext context,
  required WidgetRef ref,
  required Mensalidade mensalidade,
  bool asAluno = false,
}) async {
  final id = mensalidade.id;
  PixData? pix;
  var carregando = true;
  String? erro;
  var precisaCarteira = false;
  var avisando = false;
  var avisado = false;
  var copiado = false;
  var loadToken = 0;
  var loadStarted = false;

  Future<void> carregar(void Function(void Function()) setDialogState) async {
    final token = ++loadToken;
    setDialogState(() {
      carregando = true;
      erro = null;
      precisaCarteira = false;
    });
    try {
      final repo = mensalidadeRepo(ref);
      final p = asAluno ? await repo.gerarPixAluno(id) : await repo.gerarPix(id);
      if (token != loadToken) return;
      if (!pixQrHasRenderablePayload(
        pixCopiaECola: p.pixCopiaECola,
        qrCodeBase64: p.qrCodeBase64,
      )) {
        setDialogState(() {
          erro = pixSemCodigoErro;
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
      setDialogState(() {
        erro = friendlyError(e);
        precisaCarteira =
            !asAluno && ApiError.from(e)?.codigo == pixChaveAusenteCodigo;
        carregando = false;
      });
    }
  }

  Future<void> avisarPagamento(
    BuildContext ctx,
    void Function(void Function()) setDialogState,
  ) async {
    setDialogState(() => avisando = true);
    try {
      await mensalidadeRepo(ref).avisarPagamentoPix(id);
      setDialogState(() {
        avisando = false;
        avisado = true;
      });
      if (ctx.mounted) FeedbackHelper.showSuccess(ctx, pixAvisoEnviadoMensagem);
    } catch (e) {
      setDialogState(() => avisando = false);
      if (ctx.mounted) FeedbackHelper.showError(ctx, friendlyError(e));
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
            final s = S.of(ctx);
            final mute =
                isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
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
                    leading: Icon(FxIcons.pix, color: primary, size: 18),
                  ),
                  SizedBox(height: TokensStrip.s3),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            mensalidade.valor.formatCobranca(),
                            textAlign: TextAlign.center,
                            style: FocuxHubTypography.metric(
                              color: Theme.of(ctx).colorScheme.onSurface,
                              fontSize: 28,
                            ),
                          ),
                          const SizedBox(height: TokensStrip.s1),
                          Text(
                            pixVencimentoLinha(
                              s,
                              mesReferencia: mensalidade.mesReferencia,
                              vencimento: mensalidade.vencimento,
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: mute,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
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
                                  if (precisaCarteira)
                                    FxLiquidPrimaryButton(
                                      label: 'Abrir carteira',
                                      onPressed: () {
                                        FxHomeSheetChrome.dismissAndPop(ctx);
                                        context.push('/perfil/wallet');
                                      },
                                    )
                                  else
                                    FxTonalButton(label: 'Tentar de novo', onPressed: () => carregar(setDialogState), compact: true),
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
                            FxLiquidPrimaryButton(
                              icon: FxIcons.copiar,
                              label: s.pixCopiarCodigo,
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
                                copiado = true;
                                if (ctx.mounted) {
                                  FeedbackHelper.showSuccess(
                                    ctx,
                                    'Código PIX copiado. Some em 1 min.',
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: TokensStrip.s2),
                            Text(
                              pixDestinoHint(asAluno: asAluno),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: mute,
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                            if (asAluno && !avisado) ...[
                              const SizedBox(height: TokensStrip.s3),
                              FxLiquidSecondaryButton(
                                label:
                                    avisando
                                        ? 'Avisando…'
                                        : pixAvisarPagamentoLabel,
                                onPressed:
                                    avisando
                                        ? null
                                        : () => avisarPagamento(
                                          ctx,
                                          setDialogState,
                                        ),
                              ),
                            ],
                          ],
                          const SizedBox(height: 12),
                          FxTonalButton(label: 'Fechar', onPressed: () => FxHomeSheetChrome.dismissAndPop(ctx), compact: true),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
  );
  return copiado || avisado;
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
  // Status não se edita: vem da regra de atraso. Paga se corrige com
  // "Desfazer pagamento"; cancelada não volta.
  final valorCtrl = TextEditingController(text: fxMoneyCampoTexto(m.valor));
  var vencimento =
      DateTime.tryParse(m.vencimento ?? '') ??
      DateTime.tryParse(m.mesReferencia) ??
      DateTime.now();
  final ocupados = await carregarMesesOcupados(ref, m.alunoId, ignorarId: m.id);
  var salvando = false;
  final formKey = GlobalKey<FormState>();
  if (!context.mounted) {
    valorCtrl.dispose();
    return null;
  }

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
                        subtitle: 'Valor e vencimento.',
                        leading: Icon(FxIcons.editar, color: primary, size: 18),
                      ),
                      SizedBox(height: TokensStrip.s3),
                      FxSettingsGroup(
                        children: [
                          AlunoInsetFormField(
                            controller: valorCtrl,
                            label: 'Valor',
                            hint: 'R\$ 0,00',
                            icon: FxIcons.dinheiro,
                            rotuloVisivel: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: const [FxMoneyInputFormatter()],
                            validator: fxMoneyValidar,
                          ),
                          FxSettingsTile(
                            icon: FxIcons.calendario,
                            label: 'Vencimento',
                            value: mensalidadeVencimentoRotulo(vencimento),
                            picker: true,
                            showDivider: false,
                            onTap: () async {
                              final picked = await pickMensalidadeVencimento(
                                ctx,
                                atual: vencimento,
                                ocupados: ocupados,
                              );
                              if (picked != null) {
                                setModalState(() => vencimento = picked);
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
                                  if (!formKey.currentState!.validate()) return;
                                  final valor = fxMoneyDoCampo(valorCtrl.text)!;
                                  HapticFeedback.mediumImpact();
                                  final ok = await showFxConfirmSheet(
                                    ctx,
                                    title: financeiroSalvarMensalidadeConfirmTitle(),
                                    message: mensalidadeConfirmacaoTexto(
                                      aluno: m.alunoNome,
                                      valor: valor,
                                      vencimento: vencimento,
                                    ),
                                    icon: FxIcons.pagamento,
                                    confirmLabel: financeiroSalvarMensalidadeTileLabel(),
                                  );
                                  if (!ok) return;
                                  setModalState(() => salvando = true);
                                  try {
                                    final updated = await mensalidadeRepo(ref).editarMensalidade(
                                      m.id,
                                      valor: valor,
                                      vencimento: vencimentoIso(vencimento),
                                    );
                                    if (ctx.mounted) Navigator.of(ctx).pop(updated);
                                  } catch (e) {
                                    setModalState(() => salvando = false);
                                    if (ctx.mounted) {
                                      FeedbackHelper.showError(ctx, friendlyError(e));
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
