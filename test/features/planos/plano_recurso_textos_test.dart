import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/planos/data/plano_recurso.dart';
import 'package:focux_app/features/planos/data/plano_recurso_textos.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';
import 'package:focux_app/features/subscription/plan_entitlements.dart';

/// Palavras que não entram no texto de venda nem no nome do recurso
/// (SPEC-upgrade-personal, 14/11).
const _proibidas = [
  'touchpoint',
  'crm',
  'lead',
  'pipeline',
  'prospect',
  'funil',
  'landing',
  'checkout',
  'vitrine',
  'analytics',
  'ocr',
  'white label',
  'habit coaching',
  'upgrade',
  'operacional',
];

void main() {
  test('todo recurso pago tem nome, frase e 3 benefícios próprios', () {
    for (final e in PlanoRecursoKeys.matrix.entries) {
      if (e.value == SubscriptionPlan.FREE) continue;
      final texto = PlanoRecursoTextos.porRecurso[e.key];
      expect(texto, isNotNull, reason: 'sem texto para ${e.key}');
      expect(texto!.beneficios, hasLength(3), reason: e.key);
      expect(texto.nome.trim(), isNotEmpty);
      expect(texto.frase.trim(), isNotEmpty);
    }
    expect(PlanoRecursoTextos.de('alunos')?.beneficios, hasLength(3));
  });

  test('nenhuma palavra proibida no texto de venda', () {
    final textos = [
      ...PlanoRecursoTextos.porRecurso.values,
      PlanoRecursoTextos.de('alunos')!,
    ];
    for (final t in textos) {
      final tudo = [t.nome, t.frase, ...t.beneficios].join(' ').toLowerCase();
      for (final p in _proibidas) {
        expect(
          RegExp('\\b$p').hasMatch(tudo),
          isFalse,
          reason: '"$p" em ${t.nome}',
        );
      }
    }
  });

  test('capability legada acha o mesmo nome', () {
    expect(PlanoRecursoTextos.nome('habitCoaching', fallback: '?'), 'Hábitos');
    expect(PlanoRecursoTextos.nome('comunidadeGrupos', fallback: '?'), 'Desafios');
    expect(PlanoRecursoTextos.nome('iaCopiloto', fallback: '?'), 'IA Focux');
    expect(PlanoRecursoTextos.nome('desconhecida', fallback: 'X'), 'X');
  });

  test('a venda usa a frase e os benefícios do recurso', () {
    final offer = PlanEntitlements.lockedOffer(
      featureName: 'Marca própria',
      capability: 'whiteLabel',
    );
    expect(offer.headline, 'O app do aluno com a sua marca');
    expect(offer.targetPlan, SubscriptionPlan.ENTERPRISE);
    expect(PlanEntitlements.salesBenefits('whiteLabel'), hasLength(3));
  });

  test('toda capability literal do app tem nome no mapa único', () {
    final literal = RegExp(r"capability: '([A-Za-z]+)'");
    final faltam = <String>{};
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      for (final m in literal.allMatches(f.readAsStringSync())) {
        final cap = m.group(1)!;
        if (PlanoRecursoTextos.de(cap) == null) faltam.add('$cap (${f.path})');
      }
    }
    expect(faltam, isEmpty);
  });
}
