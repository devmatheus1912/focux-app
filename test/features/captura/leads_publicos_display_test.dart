import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/captura/utils/leads_publicos_display.dart';

void main() {
  test('leadPublicoNome não fica vazio', () {
    expect(leadPublicoNome('ana silva'), 'Ana Silva');
    expect(leadPublicoNome('  '), 'Lead');
    expect(leadPublicoNome(null), 'Lead');
  });

  test('leadPublicoSubtitle junta contato', () {
    expect(
      leadPublicoSubtitle(
        telefone: '11999999999',
        email: 'a@b.com',
        objetivo: 'Emagrecer',
      ),
      '(11) 99999-9999 · a@b.com · Emagrecer',
    );
    expect(leadPublicoSubtitle(), 'Sem contato extra');
  });

  test('sticky e filtro ativo', () {
    expect(leadPublicoStickyLabel(), 'Abrir página pública');
    expect(
      leadPublicoHasActiveFilter(query: '', chip: LeadPublicoChip.todos),
      isFalse,
    );
    expect(
      leadPublicoHasActiveFilter(query: 'ana', chip: LeadPublicoChip.todos),
      isTrue,
    );
    expect(
      leadPublicoHasActiveFilter(query: '', chip: LeadPublicoChip.novos),
      isTrue,
    );
  });

  test('leadPublico status e criar aluno', () {
    expect(leadPublicoValue(true), 'Convertido');
    expect(leadPublicoValue(false), 'Novo');
    expect(leadPublicoFxIcon(true), 'circle-check');
    expect(leadPublicoFxIcon(false), 'users');
    expect(leadPublicoPodeCriarAluno('a@b.com'), isTrue);
    expect(leadPublicoPodeCriarAluno('  '), isFalse);
    expect(leadPublicoPodeCriarAluno(null), isFalse);
  });

  test('leadPublicoCountLabel e chips', () {
    expect(leadPublicoCountLabel(0), 'Nenhum lead');
    expect(leadPublicoCountLabel(1), '1 lead');
    expect(leadPublicoCountLabel(2), '2 leads');
    expect(leadPublicoChipLabel(LeadPublicoChip.todos), 'Todos');
    expect(leadPublicoChipLabel(LeadPublicoChip.novos), 'Novos');
    expect(leadPublicoChipLabel(LeadPublicoChip.convertidos), 'Convertidos');
    expect(leadPublicoConvertidoParam(LeadPublicoChip.todos), isNull);
    expect(leadPublicoConvertidoParam(LeadPublicoChip.novos), isFalse);
    expect(leadPublicoConvertidoParam(LeadPublicoChip.convertidos), isTrue);
  });
}
