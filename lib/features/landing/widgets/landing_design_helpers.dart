import 'package:flutter/material.dart';

import '../models/public_personal_data.dart';

class LandingHeroPill {
  final String value;
  final String label;

  const LandingHeroPill({required this.value, required this.label});
}

class LandingProofItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const LandingProofItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class LandingDesign {
  const LandingDesign._();

  static String firstName(PublicPersonalData data) {
    final name = data.nomePersonal.trim();
    if (name.isEmpty) return 'Personal';
    return name.split(RegExp(r'\s+')).first;
  }

  static String? clean(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static String? primarySpecialty(PublicPersonalData data) {
    final specialties = clean(data.especialidades);
    if (specialties == null) return null;
    for (final item in specialties.split(',')) {
      final cleanItem = item.trim();
      if (cleanItem.isNotEmpty) return cleanItem;
    }
    return null;
  }

  static String heroHeadline(PublicPersonalData data) {
    final customTitle = clean(data.heroTitle);
    if (customTitle != null) return customTitle;
    final slogan = clean(data.slogan);
    final specialty = primarySpecialty(data) ?? 'treino';
    if (slogan != null && !_isGenericSlogan(slogan)) return slogan;
    return 'Plano de $specialty com acompanhamento profissional.';
  }

  static String heroSupport(PublicPersonalData data) {
    final customSubtitle = clean(data.heroSubtitle);
    if (customSubtitle != null) return _withPeriod(customSubtitle);
    final description = clean(data.descricaoProfissional);
    if (description != null) return _withPeriod(description);
    final name = firstName(data);
    return '$name organiza treino, progresso e comunicacao em uma experiencia clara do primeiro contato ao ajuste final.';
  }

  static String heroCta(PublicPersonalData data) {
    final custom = clean(data.primaryCta);
    if (custom != null) return custom;
    return 'Quero treinar com ${firstName(data)}';
  }

  static String offerCta(
    PublicPersonalData data,
    PublicLandingPackageItem item,
  ) {
    final custom = clean(data.offerCta);
    if (custom != null) return custom;
    return clean(item.cta) ?? 'Quero esse plano';
  }

  static String finalCta(PublicPersonalData data) {
    return clean(data.finalCta) ?? 'Quero comecar agora';
  }

  static String contactCta(PublicPersonalData data) {
    return clean(data.contactCta) ?? 'Copiar';
  }

  static int featuredIndex(int? index, int length) {
    if (length <= 0) return 0;
    final value = index ?? 0;
    if (value < 0) return 0;
    if (value >= length) return length - 1;
    return value;
  }

  static List<T> prioritize<T>(List<T> items, int? featuredIndex) {
    if (items.length < 2) return items;
    final index = LandingDesign.featuredIndex(featuredIndex, items.length);
    if (index == 0) return items;
    final result = [...items];
    final featured = result.removeAt(index);
    return [featured, ...result];
  }

  static bool _isGenericSlogan(String slogan) {
    final normalized = _plain(slogan.toLowerCase());
    return normalized.contains('transformando vida') ||
        normalized.contains('transformando vidas') ||
        normalized.contains('atraves de movimento') ||
        normalized.contains('atraves do movimento') ||
        normalized == 'treine com dados. evolua com inteligencia.';
  }

  static String _plain(String value) {
    return value
        .replaceAll('\u00e1', 'a')
        .replaceAll('\u00e0', 'a')
        .replaceAll('\u00e2', 'a')
        .replaceAll('\u00e3', 'a')
        .replaceAll('\u00e9', 'e')
        .replaceAll('\u00ea', 'e')
        .replaceAll('\u00ed', 'i')
        .replaceAll('\u00f3', 'o')
        .replaceAll('\u00f4', 'o')
        .replaceAll('\u00f5', 'o')
        .replaceAll('\u00fa', 'u')
        .replaceAll('\u00e7', 'c');
  }

  static String aboutCopy(PublicPersonalData data) {
    final description = clean(data.descricaoProfissional);
    if (description != null) return _withPeriod(description);
    final specialty = primarySpecialty(data) ?? 'treinamento personalizado';
    return 'A proposta combina $specialty, app, check-ins e ajustes claros para o aluno saber o que fazer em cada etapa.';
  }

  static bool showStudentCount(PublicPersonalData data) {
    return data.totalAlunos >= 10;
  }

  static int yearsExperience(PublicPersonalData data) {
    final now = DateTime.now().year;
    if (data.anoCriacao < 1980 || data.anoCriacao >= now) return 0;
    return (now - data.anoCriacao).clamp(0, 80);
  }

  static bool hasValidCref(PublicPersonalData data) {
    final cref = clean(data.cref);
    if (cref == null) return false;
    final normalized = cref.toLowerCase();
    if (normalized.contains('123456')) return false;
    if (normalized.contains('000000')) return false;
    if (normalized.contains('teste')) return false;
    if (normalized.contains('placeholder')) return false;
    return true;
  }

  static String? validCref(PublicPersonalData data) {
    return hasValidCref(data) ? clean(data.cref) : null;
  }

  static List<LandingHeroPill> heroPills(PublicPersonalData data) {
    final items = <LandingHeroPill>[];
    if (showStudentCount(data)) {
      items.add(
        LandingHeroPill(value: '${data.totalAlunos}+', label: 'alunos'),
      );
    } else {
      items.add(const LandingHeroPill(value: 'Vagas', label: 'limitadas'));
    }

    final years = yearsExperience(data);
    if (years >= 2) {
      items.add(LandingHeroPill(value: '$years+', label: 'anos'));
    } else if (hasValidCref(data)) {
      items.add(const LandingHeroPill(value: 'CREF', label: 'ativo'));
    } else {
      items.add(const LandingHeroPill(value: 'App', label: 'incluido'));
    }

    final specialty = primarySpecialty(data);
    if (specialty != null) {
      items.add(LandingHeroPill(value: specialty, label: 'foco'));
    } else {
      items.add(const LandingHeroPill(value: 'Plano', label: 'individual'));
    }
    return items;
  }

  static List<LandingProofItem> proofItems(PublicPersonalData data) {
    final items = <LandingProofItem>[];
    if (showStudentCount(data)) {
      items.add(
        LandingProofItem(
          icon: Icons.people_outline,
          title: '${data.totalAlunos}+ alunos',
          subtitle: 'historico de acompanhamento',
        ),
      );
    } else {
      items.add(
        const LandingProofItem(
          icon: Icons.groups_2_outlined,
          title: 'Acompanhamento proximo',
          subtitle: 'menos volume, mais atencao individual',
        ),
      );
    }

    if (hasValidCref(data)) {
      items.add(
        const LandingProofItem(
          icon: Icons.verified_outlined,
          title: 'CREF verificado',
          subtitle: 'credencial profissional em destaque',
        ),
      );
    } else {
      items.add(
        const LandingProofItem(
          icon: Icons.fact_check_outlined,
          title: 'Metodo documentado',
          subtitle: 'treino, check-in e progresso registrados',
        ),
      );
    }

    final years = yearsExperience(data);
    if (years >= 2) {
      items.add(
        LandingProofItem(
          icon: Icons.workspace_premium_outlined,
          title: '$years+ anos',
          subtitle: 'experiencia aplicada em rotina real',
        ),
      );
    } else {
      items.add(
        const LandingProofItem(
          icon: Icons.show_chart_outlined,
          title: 'Evolucao acompanhada',
          subtitle: 'ajustes por carga, frequencia e resposta',
        ),
      );
    }
    return items;
  }

  static String? firstImageUrl(PublicPersonalData data) {
    final hero = clean(data.heroImageUrl);
    if (hero != null && !_isAiGeneratedHeroUrl(hero)) return hero;
    for (final photo in data.fotos) {
      final url = clean(photo);
      if (url != null && !_isAiGeneratedHeroUrl(url)) return url;
    }
    return null;
  }

  static String? bioImageUrl(PublicPersonalData data) {
    final bio = clean(data.bioImageUrl);
    if (bio != null && !_isAiGeneratedHeroUrl(bio)) return bio;
    return null;
  }

  static List<PublicLandingServiceItem> services(PublicPersonalData data) {
    final real =
        data.servicos
            .where((item) => clean(item.titulo) != null)
            .map(
              (item) => PublicLandingServiceItem(
                titulo: clean(item.titulo)!,
                descricao:
                    clean(item.descricao) ??
                    'Orientacao clara, rotina estruturada e ajustes conforme progresso.',
              ),
            )
            .toList();
    if (real.isNotEmpty) return real;
    return const [
      PublicLandingServiceItem(
        titulo: 'Consultoria individual',
        descricao:
            'Plano criado para objetivo, rotina, nivel atual e disponibilidade real.',
      ),
      PublicLandingServiceItem(
        titulo: 'Acompanhamento no app',
        descricao:
            'Treinos, progresso, check-ins e mensagens em um unico lugar.',
      ),
      PublicLandingServiceItem(
        titulo: 'Ajustes de performance',
        descricao: 'Carga, volume e frequencia revisados com criterio.',
      ),
    ];
  }

  static List<PublicLandingPackageItem> packages(PublicPersonalData data) {
    final real =
        data.pacotes
            .where((item) => clean(item.nome) != null)
            .map(
              (item) => PublicLandingPackageItem(
                nome: clean(item.nome)!,
                descricao:
                    clean(item.descricao) ??
                    'Rotina estruturada, suporte e ajustes de progresso.',
                preco: clean(item.preco) ?? '',
                cta: clean(item.cta) ?? 'Quero esse acompanhamento',
              ),
            )
            .toList();
    if (real.isNotEmpty) return real;
    return const [
      PublicLandingPackageItem(
        nome: 'Acompanhamento personalizado',
        descricao: 'Rotina com treino estruturado, check-ins e suporte direto.',
        preco: '',
        cta: 'Quero uma avaliacao',
      ),
    ];
  }

  static String formatPrice(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'Sob consulta';
    if (value.toLowerCase().contains('sob')) return value;
    if (value.contains('R\$')) {
      return value.contains('/') ? value : '$value/mes';
    }
    final simpleNumber = RegExp(r'^\d+([,.]\d{1,2})?$').hasMatch(value);
    if (simpleNumber) return 'R\$ $value/mes';
    return value;
  }

  static List<String> packageBenefits(PublicLandingPackageItem item) {
    final description = clean(item.descricao) ?? '';
    final benefits = <String>[
      'Treino por fase e prioridade',
      'Ajustes por rotina e resposta do aluno',
      'Contato e acompanhamento no app',
    ];
    if (description.toLowerCase().contains('presencial')) {
      benefits[0] = 'Atendimento presencial com direcao tecnica';
    }
    if (description.toLowerCase().contains('online')) {
      benefits[0] = 'Rotina online com execucao guiada';
    }
    return benefits;
  }

  static List<PublicLandingFaqItem> faq(PublicPersonalData data) {
    final real =
        data.faq
            .where(
              (item) =>
                  clean(item.pergunta) != null && clean(item.resposta) != null,
            )
            .map(
              (item) => PublicLandingFaqItem(
                pergunta: clean(item.pergunta)!,
                resposta: clean(item.resposta)!,
              ),
            )
            .toList();
    final defaults = [
      PublicLandingFaqItem(
        pergunta: 'Como funciona o acompanhamento?',
        resposta:
            'Voce recebe uma rotina estruturada, registra treinos no app e passa por ajustes conforme progresso, agenda e resposta do corpo.',
      ),
      PublicLandingFaqItem(
        pergunta: 'Preciso ja estar treinando?',
        resposta:
            'Nao. O plano parte do seu nivel atual e evolui com seguranca, sem modelo pronto.',
      ),
      PublicLandingFaqItem(
        pergunta: 'O contato acontece por onde?',
        resposta:
            'O app centraliza treino, check-ins, historico e mensagens para manter o acompanhamento organizado.',
      ),
    ];
    final result = [...real];
    for (final item in defaults) {
      final exists = result.any(
        (realItem) =>
            realItem.pergunta.toLowerCase() == item.pergunta.toLowerCase(),
      );
      if (!exists) result.add(item);
    }
    return result.take(6).toList();
  }

  static String _withPeriod(String text) {
    if (text.endsWith('.') || text.endsWith('!') || text.endsWith('?')) {
      return text;
    }
    return '$text.';
  }

  static bool _isAiGeneratedHeroUrl(String url) {
    return url.trim().toLowerCase().contains('image.pollinations.ai/prompt/');
  }
}
