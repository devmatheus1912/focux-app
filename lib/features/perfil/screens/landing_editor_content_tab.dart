import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../utils/landing_default_images.dart';
import '../widgets/landing_editor_widgets.dart';
import 'landing_editor_controller.dart';
import 'landing_editor_quality.dart';
import 'landing_editor_sections.dart';
import 'landing_editor_shared_widgets.dart';

class LandingEditorContentTab extends StatelessWidget {
  const LandingEditorContentTab({
    super.key,
    required this.controller,
    required this.onGenerateHero,
    required this.onUploadHero,
    required this.onUploadBio,
    required this.onRemoveHero,
    required this.onRemoveBio,
    required this.onUseDefaultHero,
    required this.onUseDefaultBio,
    required this.onMarkDirty,
    required this.onHeroExpandedChanged,
    required this.onCoverExpandedChanged,
    required this.onPreviewLanding,
    required this.onCtasExpandedChanged,
    required this.onServicosExpandedChanged,
    required this.onFaqExpandedChanged,
    required this.onAddServico,
    required this.onRemoveServico,
    required this.onUpdateServico,
    required this.onAddFaq,
    required this.onRemoveFaq,
    required this.onUpdateFaq,
    required this.onExitReviewFocus,
    required this.onJumpToSection,
  });

  final LandingEditorController controller;
  final VoidCallback onGenerateHero;
  final VoidCallback onUploadHero;
  final VoidCallback onUploadBio;
  final VoidCallback onRemoveHero;
  final VoidCallback onRemoveBio;
  final VoidCallback onUseDefaultHero;
  final VoidCallback onUseDefaultBio;
  final VoidCallback onMarkDirty;
  final ValueChanged<bool> onHeroExpandedChanged;
  final ValueChanged<bool> onCoverExpandedChanged;
  final VoidCallback onPreviewLanding;
  final ValueChanged<bool> onCtasExpandedChanged;
  final ValueChanged<bool> onServicosExpandedChanged;
  final ValueChanged<bool> onFaqExpandedChanged;
  final VoidCallback onAddServico;
  final ValueChanged<int> onRemoveServico;
  final void Function(int index, {String? titulo, String? descricao})
  onUpdateServico;
  final VoidCallback onAddFaq;
  final ValueChanged<int> onRemoveFaq;
  final void Function(int index, {String? pergunta, String? resposta})
  onUpdateFaq;
  final VoidCallback onExitReviewFocus;
  final ValueChanged<LandingEditorContentSection> onJumpToSection;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final focusFaq = c.reviewFocusMode ? c.focusFaqIndices() : null;
    final showHero = !c.reviewFocusMode || c.focusHeroIssue();
    final showSecondarySections = !c.reviewFocusMode;
    final visibleFaqIndices =
        focusFaq == null
            ? List<int>.generate(c.faq.length, (i) => i)
            : (focusFaq.toList()..sort());
    final hiddenFaqCount = c.faq.length - visibleFaqIndices.length;
    final faqPayload = c.faqPayload();

    return ListView(
      controller: c.conteudoScroll,
      padding: const EdgeInsets.all(TokensStrip.s4),
      children: [
        if (c.reviewFocusMode)
          LandingReviewFocusBanner(
            pendingCount: c.contentReviewCount(),
            onExit: onExitReviewFocus,
          ),
        if (c.reviewFocusMode) const SizedBox(height: 12),
        if (!c.reviewFocusMode) ...[
          LandingContentSectionJumpBar(
            onJump: onJumpToSection,
            hiddenSections: {
              if (!showHero) ...[
                LandingEditorContentSection.abertura,
                LandingEditorContentSection.capa,
              ],
              if (!showSecondarySections) ...[
                LandingEditorContentSection.botoes,
                LandingEditorContentSection.servicos,
              ],
            },
          ),
          const SizedBox(height: 14),
        ],
        if (showHero)
          KeyedSubtree(
            key: c.heroSectionKey,
            child: LandingCollapsibleSection(
              title: 'Abertura da página',
              hint: 'Primeira impressão — título, texto e botão principal.',
              expanded: c.heroExpanded,
              onExpandedChanged: onHeroExpandedChanged,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: c.generatingHero ? null : onGenerateHero,
                    icon:
                        c.generatingHero
                            ? const FxLoading(size: 16, strokeWidth: 2)
                            : const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Sugerir textos com IA'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: c.heroTitle,
                    decoration: landingEditorFieldDecoration(
                      context,
                      labelText: 'Título principal',
                      helperText: 'Aparece em destaque no topo da página.',
                      maxLength: 180,
                    ),
                    maxLength: 180,
                    scrollPadding: const EdgeInsets.only(bottom: 120),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: c.heroSubtitle,
                    decoration: landingEditorFieldDecoration(
                      context,
                      labelText: 'Texto de apoio',
                      helperText: 'Explique em uma frase como você ajuda.',
                    ),
                    maxLines: 3,
                    scrollPadding: const EdgeInsets.only(bottom: 120),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final accentFix = landingCtaAccentSuggestion(
                        c.primaryCta.text,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: c.primaryCta,
                            decoration: landingEditorFieldDecoration(
                              context,
                              labelText: 'Texto do botão principal',
                              helperText:
                                  'Ex.: Quero começar · Agendar avaliação',
                            ),
                            scrollPadding: const EdgeInsets.only(bottom: 120),
                            textInputAction: TextInputAction.done,
                          ),
                          if (accentFix != null) ...[
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () {
                                  c.primaryCta.text = accentFix;
                                  c
                                      .primaryCta
                                      .selection = TextSelection.collapsed(
                                    offset: accentFix.length,
                                  );
                                  onMarkDirty();
                                },
                                icon: const Icon(Icons.spellcheck, size: 18),
                                label: const Text(
                                  'Corrigir acento em "avaliação"',
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  LandingEditorImageUploadCard(
                    title: 'Foto na seção sobre',
                    hint:
                        'Mostra quem você é em "Quem vai te acompanhar". Por padrão usamos sua foto de perfil — envie outra aqui só para a landing, sem alterar o perfil.',
                    imageUrl: c.bioImageUrl,
                    defaultPreviewUrl: landingBioEditorPreviewUrl(
                      c.logoUrl,
                      c.slug,
                    ),
                    uploading: c.uploadingBio,
                    onUpload: onUploadBio,
                    onPreview: onPreviewLanding,
                    onRemove:
                        c.bioImageUrl != null && c.bioImageUrl!.isNotEmpty
                            ? onRemoveBio
                            : null,
                    onUseDefault: onUseDefaultBio,
                    useDefaultLabel: 'Usar foto do perfil',
                    defaultActiveHint:
                        landingUsesDefaultBioImage(c.bioImageUrl)
                            ? (c.logoUrl != null && c.logoUrl!.isNotEmpty
                                ? 'Usando sua foto de perfil. Envie outra aqui só para a landing.'
                                : 'Sem foto de perfil — adicione no perfil ou envie uma foto aqui.')
                            : null,
                  ),
                ],
              ),
            ),
          ),
        if (showHero) const SizedBox(height: 12),
        if (showHero)
          KeyedSubtree(
            key: c.coverSectionKey,
            child: LandingCollapsibleSection(
              title: 'Foto de capa',
              hint:
                  'Opcional — aparece como fundo do topo com gradiente da sua cor de marca.',
              badgeLabel: 'Opcional',
              expanded: c.coverExpanded,
              onExpandedChanged: onCoverExpandedChanged,
              child: LandingEditorImageUploadCard(
                compact: true,
                imageUrl: c.heroImageUrl,
                defaultPreviewUrl: landingDefaultHeroImageUrl(c.slug),
                uploading: c.uploadingHero,
                onUpload: onUploadHero,
                optional: true,
                emptyHint:
                    'Sem capa personalizada — usamos foto premium de academia no topo.',
                defaultActiveHint:
                    landingUsesDefaultHeroImage(c.heroImageUrl)
                        ? 'Padrão ativo — ambiente de academia profissional. Envie sua foto para personalizar.'
                        : null,
                onPreview: onPreviewLanding,
                onRemove:
                    c.heroImageUrl != null && c.heroImageUrl!.isNotEmpty
                        ? onRemoveHero
                        : null,
                onUseDefault: onUseDefaultHero,
                useDefaultLabel: 'Usar padrão',
              ),
            ),
          ),
        if (showHero) const SizedBox(height: 12),
        if (showSecondarySections)
          KeyedSubtree(
            key: c.ctasSectionKey,
            child: LandingCollapsibleSection(
              title: 'Outros botões',
              hint: 'Textos dos botões em planos e na área de contato.',
              expanded: c.ctasExpanded,
              onExpandedChanged: onCtasExpandedChanged,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LandingStickyCtaInfoBanner(),
                  const SizedBox(height: 12),
                  TextField(
                    controller: c.offerCta,
                    decoration: landingEditorFieldDecoration(
                      context,
                      labelText: 'Botão nos planos',
                      helperText: 'Ex.: Escolher plano · Quero esse plano',
                    ),
                    scrollPadding: const EdgeInsets.only(bottom: 120),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: c.contactCta,
                    decoration: landingEditorFieldDecoration(
                      context,
                      labelText: 'Botão na área de contato',
                      helperText: 'Ex.: Falar comigo · Chamar no WhatsApp',
                    ),
                    scrollPadding: const EdgeInsets.only(bottom: 120),
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
          ),
        if (showSecondarySections) const SizedBox(height: 12),
        if (showSecondarySections)
          KeyedSubtree(
            key: c.servicosSectionKey,
            child: LandingCollapsibleSection(
              title: 'Serviços',
              hint:
                  'Formatos que você oferece — online, presencial ou híbrido.',
              expanded: c.servicosExpanded,
              onExpandedChanged: onServicosExpandedChanged,
              onAdd: onAddServico,
              child: Column(
                children: [
                  if (c.servicos.isEmpty)
                    Text(
                      'Nenhum serviço ainda. Toque em Adicionar para incluir.',
                      style: landingEditorMutedStyle(context),
                    ),
                  for (var i = 0; i < c.servicos.length; i++) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: fxListCardDecoration(context),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Serviço ${i + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                landingEditorDeleteIconButton(
                                  onPressed: () => onRemoveServico(i),
                                  tooltip: 'Remover serviço',
                                ),
                              ],
                            ),
                            TextFormField(
                              key: ValueKey('servico-titulo-$i'),
                              initialValue: c.servicos[i].titulo,
                              decoration: landingEditorFieldDecoration(
                                context,
                                labelText: 'Nome do serviço',
                                helperText: landingPolishPreviewHint(
                                  c.servicos[i].titulo,
                                ),
                              ),
                              onChanged: (v) => onUpdateServico(i, titulo: v),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              key: ValueKey('servico-desc-$i'),
                              initialValue: c.servicos[i].descricao,
                              decoration: landingEditorFieldDecoration(
                                context,
                                labelText: 'Descrição curta',
                              ),
                              maxLines: 3,
                              onChanged:
                                  (v) => onUpdateServico(i, descricao: v),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (showSecondarySections) const SizedBox(height: 12),
        KeyedSubtree(
          key: c.faqSectionKey,
          child: LandingCollapsibleSection(
            title: 'Dúvidas frequentes',
            hint:
                c.reviewFocusMode
                    ? 'Mostrando só perguntas que precisam de revisão.'
                    : 'Respostas que removem objeções antes do cliente chamar.',
            expanded: c.faqExpanded,
            onExpandedChanged: onFaqExpandedChanged,
            onAdd: c.reviewFocusMode ? null : onAddFaq,
            child: Column(
              children: [
                if (c.faq.isEmpty)
                  Text(
                    'Nenhuma pergunta ainda. Ex.: "Preciso treinar todos os dias?"',
                    style: landingEditorMutedStyle(context),
                  ),
                if (c.reviewFocusMode && hiddenFaqCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      hiddenFaqCount == 1
                          ? '1 pergunta ok — oculta no modo foco.'
                          : '$hiddenFaqCount perguntas ok — ocultas no modo foco.',
                      style: landingEditorMutedStyle(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                for (final i in visibleFaqIndices) ...[
                  KeyedSubtree(
                    key: c.faqKeyFor(i),
                    child: LandingHighlightCard(
                      highlighted:
                          c.highlightedFaqIndex == i ||
                          landingFaqItemHasIssue(faq: faqPayload, index: i),
                      issueHint:
                          landingFaqItemHasIssue(faq: faqPayload, index: i)
                              ? 'Revise o texto desta pergunta'
                              : null,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Pergunta ${i + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              landingEditorDeleteIconButton(
                                onPressed: () => onRemoveFaq(i),
                                tooltip: 'Remover pergunta',
                              ),
                            ],
                          ),
                          TextFormField(
                            key: ValueKey('faq-pergunta-$i'),
                            initialValue: c.faq[i].pergunta,
                            decoration: landingEditorFieldDecoration(
                              context,
                              labelText: 'Pergunta',
                              helperText: landingPolishPreviewHint(
                                c.faq[i].pergunta,
                              ),
                            ),
                            onChanged: (v) => onUpdateFaq(i, pergunta: v),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: ValueKey('faq-resposta-$i'),
                            initialValue: c.faq[i].resposta,
                            decoration: landingEditorFieldDecoration(
                              context,
                              labelText: 'Resposta',
                              helperText: landingPolishPreviewHint(
                                c.faq[i].resposta,
                              ),
                            ),
                            maxLines: 3,
                            onChanged: (v) => onUpdateFaq(i, resposta: v),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}
