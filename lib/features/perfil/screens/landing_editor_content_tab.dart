import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../utils/landing_default_images.dart';
import '../widgets/landing_editor_widgets.dart';
import 'landing_editor_controller.dart';
import 'landing_editor_quality.dart';
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
  final void Function(int index, {String? titulo, String? descricao}) onUpdateServico;
  final VoidCallback onAddFaq;
  final ValueChanged<int> onRemoveFaq;
  final void Function(int index, {String? pergunta, String? resposta}) onUpdateFaq;
  final VoidCallback onExitReviewFocus;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final focusFaq = c.reviewFocusMode ? c.focusFaqIndices() : null;
    final showHero = !c.reviewFocusMode || c.focusHeroIssue();
    final showSecondarySections = !c.reviewFocusMode;
    final visibleFaqIndices = focusFaq == null
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
                    icon: c.generatingHero
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
                      final accentFix =
                          landingCtaAccentSuggestion(c.primaryCta.text);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: c.primaryCta,
                            decoration: landingEditorFieldDecoration(
                              context,
                              labelText: 'Texto do botão principal',
                              helperText: 'Ex.: Quero começar · Agendar avaliação',
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
                                  c.primaryCta.selection = TextSelection.collapsed(
                                    offset: accentFix.length,
                                  );
                                  onMarkDirty();
                                },
                                icon: const Icon(Icons.spellcheck, size: 18),
                                label: const Text('Corrigir acento em "avaliação"'),
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
                        'Retrato ou foto profissional — aparece em "Sobre você". Se não enviar, usamos uma foto padrão de academia.',
                    imageUrl: c.bioImageUrl,
                    defaultPreviewUrl: landingDefaultBioImageUrl(c.slug),
                    uploading: c.uploadingBio,
                    onUpload: onUploadBio,
                    onPreview: onPreviewLanding,
                    onRemove: c.bioImageUrl != null && c.bioImageUrl!.isNotEmpty
                        ? onRemoveBio
                        : null,
                    onUseDefault: onUseDefaultBio,
                    useDefaultLabel: 'Usar padrão',
                    defaultActiveHint: landingUsesDefaultBioImage(c.bioImageUrl)
                        ? 'Padrão ativo — foto de academia até você enviar a sua.'
                        : null,
                  ),
                ],
              ),
            ),
          ),
        if (showHero) const SizedBox(height: 12),
        if (showHero)
          LandingCollapsibleSection(
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
              defaultActiveHint: landingUsesDefaultHeroImage(c.heroImageUrl)
                  ? 'Padrão ativo — ambiente de academia profissional. Envie sua foto para personalizar.'
                  : null,
              onPreview: onPreviewLanding,
              onRemove: c.heroImageUrl != null && c.heroImageUrl!.isNotEmpty
                  ? onRemoveHero
                  : null,
              onUseDefault: onUseDefaultHero,
              useDefaultLabel: 'Usar padrão',
            ),
          ),
        if (showHero) const SizedBox(height: 12),
        if (showSecondarySections)
          KeyedSubtree(
            key: c.ctasSectionKey,
            child: LandingCollapsibleSection(
              title: 'Outros botões',
              hint: 'Textos extras que aparecem em planos, rodapé e contato.',
              expanded: c.ctasExpanded,
              onExpandedChanged: onCtasExpandedChanged,
              child: Column(
                children: [
                  TextField(
                    controller: c.offerCta,
                    decoration: const InputDecoration(
                      labelText: 'Botão nos planos',
                      helperText: 'Ex.: Escolher plano · Quero esse plano',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: c.finalCta,
                    decoration: const InputDecoration(
                      labelText: 'Botão fixo no rodapé (legado)',
                      helperText: 'A barra fixa usa o mesmo texto do botão principal do hero.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: c.contactCta,
                    decoration: const InputDecoration(
                      labelText: 'Botão na área de contato',
                      helperText: 'Ex.: Falar comigo · Chamar no WhatsApp',
                    ),
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
              hint: 'Formatos que você oferece — online, presencial ou híbrido.',
              expanded: c.servicosExpanded,
              onExpandedChanged: onServicosExpandedChanged,
              onAdd: onAddServico,
              child: Column(
                children: [
                  if (c.servicos.isEmpty)
                    Text(
                      'Nenhum serviço ainda. Toque em Adicionar para incluir.',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  for (var i = 0; i < c.servicos.length; i++) ...[
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Serviço ${i + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => onRemoveServico(i),
                                  tooltip: 'Remover serviço',
                                ),
                              ],
                            ),
                            TextFormField(
                              key: ValueKey('servico-titulo-$i'),
                              initialValue: c.servicos[i].titulo,
                              decoration: InputDecoration(
                                labelText: 'Nome do serviço',
                                helperText: landingPolishPreviewHint(c.servicos[i].titulo),
                                helperMaxLines: 2,
                              ),
                              onChanged: (v) => onUpdateServico(i, titulo: v),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              key: ValueKey('servico-desc-$i'),
                              initialValue: c.servicos[i].descricao,
                              decoration: const InputDecoration(
                                labelText: 'Descrição curta',
                              ),
                              maxLines: 3,
                              onChanged: (v) => onUpdateServico(i, descricao: v),
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
            hint: c.reviewFocusMode
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
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                if (c.reviewFocusMode && hiddenFaqCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      hiddenFaqCount == 1
                          ? '1 pergunta ok — oculta no modo foco.'
                          : '$hiddenFaqCount perguntas ok — ocultas no modo foco.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                for (final i in visibleFaqIndices) ...[
                  KeyedSubtree(
                    key: c.faqKeyFor(i),
                    child: LandingHighlightCard(
                      highlighted: c.highlightedFaqIndex == i ||
                          landingFaqItemHasIssue(faq: faqPayload, index: i),
                      issueHint: landingFaqItemHasIssue(faq: faqPayload, index: i)
                          ? 'Revise o texto desta pergunta'
                          : null,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Pergunta ${i + 1}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => onRemoveFaq(i),
                                tooltip: 'Remover pergunta',
                              ),
                            ],
                          ),
                          TextFormField(
                            key: ValueKey('faq-pergunta-$i'),
                            initialValue: c.faq[i].pergunta,
                            decoration: InputDecoration(
                              labelText: 'Pergunta',
                              helperText: landingPolishPreviewHint(c.faq[i].pergunta),
                              helperMaxLines: 2,
                            ),
                            onChanged: (v) => onUpdateFaq(i, pergunta: v),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: ValueKey('faq-resposta-$i'),
                            initialValue: c.faq[i].resposta,
                            decoration: InputDecoration(
                              labelText: 'Resposta',
                              helperText: landingPolishPreviewHint(c.faq[i].resposta),
                              helperMaxLines: 2,
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
