import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/br_phone.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../data/lead_repository.dart';
import '../utils/interessados_display.dart';
import '../utils/lead_display.dart';

/// "Novo interessado" (ou editar dados): nome, WhatsApp, origem em chips e
/// objetivo. Salva com a folha aberta. Devolve o lead salvo.
Future<Lead?> showInteressadoSheet(
  BuildContext context, {
  required LeadRepository repo,
  Lead? lead,
}) async {
  final nomeCtrl = TextEditingController(text: lead?.nome ?? '');
  final telCtrl = TextEditingController(
    text: lead?.telefone == null ? '' : BrPhone.formatDisplay(lead!.telefone),
  );
  final objetivoCtrl = TextEditingController(text: lead?.objetivo ?? '');
  var origem = lead?.origem;
  final mudou = ValueNotifier(0);
  nomeCtrl.addListener(() => mudou.value++);
  Lead? salvo;
  try {
    await showFxFormSheet(
      context,
      title: lead == null ? 'Novo interessado' : 'Editar dados',
      subtitle:
          lead == null
              ? 'Quem te chamou no Instagram, no WhatsApp ou por indicação.'
              : null,
      icon: FxIcons.adicionarPessoa,
      confirmLabel: 'Salvar',
      ouvir: mudou,
      podeConfirmar: () => nomeCtrl.text.trim().isNotEmpty,
      aoConfirmar: () async {
        try {
          final tel = BrPhone.digitsOnly(telCtrl.text);
          if (lead == null) {
            salvo = await repo.criar(
              nome: nomeCtrl.text.trim(),
              telefone: tel.isEmpty ? null : tel,
              origem: origem,
              objetivo: objetivoCtrl.text.trim(),
            );
          } else {
            salvo = await repo.atualizar(lead.id, {
              'nome': nomeCtrl.text.trim(),
              'telefone': tel,
              if (origem != null) 'origem': origem,
              'objetivo': objetivoCtrl.text.trim(),
            });
          }
          HapticFeedback.mediumImpact();
          return null;
        } catch (e) {
          return friendlyError(e);
        }
      },
      child: StatefulBuilder(
        builder: (ctx, setSheet) {
          final chrome = ShellChrome.of(ctx);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AlunoInsetFormField(
                controller: nomeCtrl,
                label: 'Nome',
                icon: FxIcons.pessoa,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(leadNomeMax),
                ],
              ),
              AlunoInsetFormField(
                controller: telCtrl,
                label: 'WhatsApp',
                hint: '(11) 98765-4321',
                icon: FxIcons.telefone,
                keyboardType: TextInputType.phone,
                inputFormatters: [BrPhone.formatter()],
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: TokensStrip.s3,
                  bottom: TokensStrip.s2,
                ),
                child: Text(
                  'Como chegou',
                  style: FocuxHubTypography.chip(chrome.mute),
                ),
              ),
              Wrap(
                spacing: TokensStrip.s2,
                runSpacing: TokensStrip.s2,
                children: [
                  for (final o in leadOrigemValues)
                    FxToggleChip(
                      label: o,
                      selected: origem == o,
                      isDark: chrome.isDark,
                      filledWhenSelected: true,
                      onTap:
                          () => setSheet(() => origem = origem == o ? null : o),
                    ),
                ],
              ),
              const SizedBox(height: TokensStrip.s2),
              AlunoInsetFormField(
                controller: objetivoCtrl,
                label: 'Objetivo (opcional)',
                hint: 'Hipertrofia, emagrecer…',
                icon: FxIcons.alvo,
                showDivider: false,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(leadObjetivoMax),
                ],
              ),
            ],
          );
        },
      ),
    );
  } finally {
    nomeCtrl.dispose();
    telCtrl.dispose();
    objetivoCtrl.dispose();
    mudou.dispose();
  }
  return salvo;
}

/// "Conversou com Thales?": anota o contato (WhatsApp ou Ligação) e, se a
/// pessoa estava em "Para responder", passa para "Em conversa".
Future<bool> showConversouSheet(
  BuildContext context, {
  required LeadRepository repo,
  required Lead lead,
  required String tipo,
}) async {
  final notaCtrl = TextEditingController();
  final primeiroNome = lead.nome.trim().split(' ').first;
  var anotou = false;
  try {
    await showFxFormSheet(
      context,
      title: 'Conversou com $primeiroNome?',
      subtitle: 'Anote para lembrar depois. Fica no histórico.',
      icon: FxIcons.chat,
      confirmLabel: 'Sim, anotar',
      cancelLabel: 'Agora não',
      aoConfirmar: () async {
        try {
          await repo.adicionarInteracao(lead.id, tipo, notaCtrl.text.trim());
          final proxima = interessadoEtapaDepoisDoContato(lead.status);
          if (proxima != null) {
            await repo.atualizar(lead.id, {'status': proxima});
          }
          anotou = true;
          return null;
        } catch (e) {
          return friendlyError(e);
        }
      },
      child: AlunoInsetFormField(
        controller: notaCtrl,
        label: 'O que combinaram (opcional)',
        icon: FxIcons.notas,
        maxLines: 3,
        showDivider: false,
        inputFormatters: [LengthLimitingTextInputFormatter(leadObservacoesMax)],
      ),
    );
  } finally {
    notaCtrl.dispose();
  }
  return anotou;
}

/// Abre o WhatsApp ou o discador. Devolve se abriu.
Future<bool> abrirContatoInteressado(Lead lead, String tipo) async {
  final tel = lead.telefone;
  if (tel == null || tel.trim().isEmpty) return false;
  final uri =
      tipo == 'WHATSAPP'
          ? BrPhone.whatsAppUri(tel)
          : Uri.parse('tel:${BrPhone.digitsOnly(tel)}');
  if (uri == null || !await canLaunchUrl(uri)) return false;
  return launchUrl(
    uri,
    mode:
        tipo == 'WHATSAPP'
            ? LaunchMode.externalApplication
            : LaunchMode.platformDefault,
  );
}
