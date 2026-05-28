/// Catálogo de seções da landing pública e modelos completos para o editor.
library;

import '../data/perfil_repository.dart';
import 'landing_editor_sections.dart';

class LandingSectionTemplateInfo {
  const LandingSectionTemplateInfo({
    required this.key,
    required this.title,
    required this.description,
    required this.example,
    required this.iconName,
  });

  final String key;
  final String title;
  final String description;
  final String example;
  final String iconName;
}

const landingSectionTemplateCatalog = [
  LandingSectionTemplateInfo(
    key: 'bio',
    title: 'Sobre você',
    description: 'Foto, história e credenciais — quem você é e por que confiar.',
    example: 'Personal há 8 anos · CREF ativo · Especialista em hipertrofia',
    iconName: 'person',
  ),
  LandingSectionTemplateInfo(
    key: 'servicos',
    title: 'Serviços',
    description: 'Formatos de atendimento: online, presencial ou híbrido.',
    example: 'Consultoria online · Treino presencial · Avaliação física',
    iconName: 'fitness',
  ),
  LandingSectionTemplateInfo(
    key: 'processo',
    title: 'Como funciona',
    description: 'Passo a passo do método — da avaliação ao acompanhamento.',
    example: '1. Avaliação · 2. Plano no app · 3. Ajustes semanais',
    iconName: 'route',
  ),
  LandingSectionTemplateInfo(
    key: 'pacotes',
    title: 'Planos e preços',
    description: 'Planos publicados na vitrine com preço e botão de compra.',
    example: 'Plano mensal · Trimestral · Consultoria avulsa',
    iconName: 'payments',
  ),
  LandingSectionTemplateInfo(
    key: 'depoimentos',
    title: 'Depoimentos',
    description: 'Prova social — resultados e relatos de alunos.',
    example: '"Perdi 6 kg em 90 dias com método claro e suporte diário."',
    iconName: 'reviews',
  ),
  LandingSectionTemplateInfo(
    key: 'galeria',
    title: 'Galeria',
    description: 'Fotos de treinos, bastidores e resultados visuais.',
    example: 'Estúdio · Treinos · Antes e depois (com autorização)',
    iconName: 'photo_library',
  ),
  LandingSectionTemplateInfo(
    key: 'faq',
    title: 'Dúvidas frequentes',
    description: 'Respostas que removem objeções antes do contato.',
    example: 'Preciso treinar todos os dias? · Como funciona a consultoria?',
    iconName: 'help',
  ),
  LandingSectionTemplateInfo(
    key: 'contato',
    title: 'Contato',
    description: 'Chamada final com botão para WhatsApp ou formulário.',
    example: 'Falar comigo · Chamar no WhatsApp · Agendar avaliação',
    iconName: 'chat',
  ),
];

/// Modelo completo aplicável localmente ou via preset de nicho.
class LandingCompleteTemplate {
  const LandingCompleteTemplate({
    required this.id,
    required this.label,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.primaryCta,
    required this.offerCta,
    required this.finalCta,
    required this.contactCta,
    required this.servicos,
    required this.faq,
    required this.sectionOrder,
  });

  final String id;
  final String label;
  final String heroTitle;
  final String heroSubtitle;
  final String primaryCta;
  final String offerCta;
  final String finalCta;
  final String contactCta;
  final List<LandingServiceItem> servicos;
  final List<LandingFaqItem> faq;
  final List<String> sectionOrder;
}

const landingDefaultCompleteTemplate = LandingCompleteTemplate(
  id: 'PADRAO',
  label: 'Modelo padrão Focux',
  heroTitle: 'Treino personalizado com acompanhamento de verdade',
  heroSubtitle:
      'Plano sob medida, ajustes semanais e suporte próximo — online ou presencial.',
  primaryCta: 'Agendar avaliação',
  offerCta: 'Escolher este plano',
  finalCta: 'Quero começar agora',
  contactCta: 'Falar no WhatsApp',
  servicos: [
    LandingServiceItem(
      titulo: 'Consultoria online',
      descricao: 'Treinos no app, vídeos e feedback rápido onde você estiver.',
    ),
    LandingServiceItem(
      titulo: 'Treino presencial',
      descricao: 'Acompanhamento ao vivo com correção de técnica e intensidade.',
    ),
  ],
  faq: [
    LandingFaqItem(
      pergunta: 'Preciso treinar todos os dias?',
      resposta:
          'Não. Montamos a frequência ideal para sua rotina — consistência vale mais que volume.',
    ),
    LandingFaqItem(
      pergunta: 'Como funciona a consultoria?',
      resposta:
          'Avaliação inicial, plano personalizado no app e ajustes conforme sua evolução.',
    ),
    LandingFaqItem(
      pergunta: 'Serve para iniciantes?',
      resposta:
          'Sim. Adaptamos carga, exercícios e progressão ao seu nível atual.',
    ),
  ],
  sectionOrder: landingEditorCanonicalSections,
);
