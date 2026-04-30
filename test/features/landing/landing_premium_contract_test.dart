import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/landing/models/public_personal_data.dart';
import 'package:focux_app/features/perfil/data/perfil_repository.dart';

void main() {
  test('public landing parses FAQ tracking and AI hero fields', () {
    final data = PublicPersonalData.fromJson({
      'nomePersonal': 'Matheus',
      'totalAlunos': 42,
      'anoCriacao': 2024,
      'plano': 'ENTERPRISE',
      'trackingId': 'campanha-instagram-abril',
      'heroPrompt': 'studio premium functional training',
      'heroImageUrl': 'https://cdn.focux.app/landing/matheus.png',
      'faq': [
        {
          'pergunta': 'Preciso treinar todos os dias?',
          'resposta': 'Nao. O plano respeita sua rotina.',
        }
      ],
    });

    expect(data.trackingId, 'campanha-instagram-abril');
    expect(data.heroPrompt, 'studio premium functional training');
    expect(data.heroImageUrl, endsWith('matheus.png'));
    expect(data.faq.single.pergunta, contains('treinar'));
  });

  test('profile landing config parses editable FAQ and AI hero fields', () {
    final perfil = PerfilPersonal.fromJson({
      'id': 1,
      'nome': 'Matheus',
      'email': 'm@focux.app',
      'plano': 'ENTERPRISE',
      'trackingId': 'utm-live',
      'heroPrompt': 'unique hero image',
      'heroImageUrl': 'https://cdn.focux.app/hero.png',
      'faq': [
        {'pergunta': 'Como funciona?', 'resposta': 'Com acompanhamento.'}
      ],
    });

    expect(perfil.trackingId, 'utm-live');
    expect(perfil.heroPrompt, 'unique hero image');
    expect(perfil.heroImageUrl, contains('hero.png'));
    expect(perfil.faq.single.resposta, 'Com acompanhamento.');
  });

  test('landing public surface exposes FAQ and tracked CTA contracts', () {
    final landing = File(
      'lib/features/landing/screens/personal_public_landing_screen.dart',
    ).readAsStringSync();
    final hero = File(
      'lib/features/landing/widgets/hero_section.dart',
    ).readAsStringSync();
    final ofertas = File(
      'lib/features/landing/widgets/ofertas_section.dart',
    ).readAsStringSync();
    final cta = File(
      'lib/features/landing/widgets/cta_final_section.dart',
    ).readAsStringSync();

    expect(landing, contains('FaqSection(data: data'));
    expect(hero, contains('data.heroImageUrl'));
    expect(hero, contains("'src': 'landing'"));
    expect(ofertas, contains("'src': 'landing_offer'"));
    expect(cta, contains("'src': 'landing_cta'"));
  });
}
