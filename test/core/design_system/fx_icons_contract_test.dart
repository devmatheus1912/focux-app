import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/fx_icons.dart';

/// Ícone do app é Phosphor, por significado, em `FxIcons`. `Icons.*` ou
/// `CupertinoIcons.*` direto numa tela volta a misturar traços (rounded,
/// outlined) e desenhos de outra família.
void main() {
  test('Icons e CupertinoIcons só em fx_icons.dart', () {
    final uso = RegExp(r'(?<![A-Za-z])(Cupertino)?Icons\.[a-z]');
    final falhas = <String>[];
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final path = file.path.replaceAll(r'\', '/');
      final norm = path.substring(path.indexOf('lib/'));
      if (norm == 'lib/core/theme/fx_icons.dart') continue;
      final linhas = file.readAsLinesSync();
      for (final (i, linha) in linhas.indexed) {
        final codigo = linha.split('//').first;
        if (uso.hasMatch(codigo)) falhas.add('$norm:${i + 1}');
      }
    }
    expect(falhas, isEmpty, reason: 'Use FxIcons (lib/core/theme/fx_icons.dart).');
  });

  test('FxIcons é Phosphor', () {
    expect(FxIcons.fechar.fontFamily, 'PhosphorLight');
    expect(FxIcons.fecharPequeno.fontFamily, 'PhosphorRegular');
    expect(FxIcons.concluidoAtivo.fontFamily, 'PhosphorFill');
  });

  List<(String, String)> linhasDeCodigo() => [
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart')))
      for (final linha in file.readAsLinesSync())
        (file.path.replaceAll(r'\', '/'), linha.split('//').first),
  ];

  test('sem ícone desenhado à mão nem ícone por nome em texto', () {
    final proibido = RegExp(r"\bFxIcon\(|\bfxIcon:|iconeComFundo|fx_icon\.dart");
    final falhas = [
      for (final (arq, codigo) in linhasDeCodigo())
        if (proibido.hasMatch(codigo)) arq,
    ];
    expect(falhas, isEmpty, reason: 'Use FxIcons (IconData), sem nome em texto.');
  });

  /// Fill é só para estado escolhido pelo usuário (aba ativa, selecionado,
  /// favorito, fixado, série feita, nota). Arquivo novo entra aqui com o motivo.
  const permitidosFill = {
    'lib/core/widgets/fx_dock.dart', // aba ativa
    'lib/core/widgets/fx_star_rating.dart', // nota escolhida
    'lib/features/agenda/widgets/agenda_form_sheets.dart', // opção selecionada
    'lib/features/alunos/widgets/aluno_list_card.dart', // seleção em lote
    'lib/features/chat/screens/chat_inbox_screen_widgets.part.dart', // conversa fixada
    'lib/features/checkin/widgets/checkin_execucao_estados.dart', // série feita
    'lib/features/checkin/widgets/sua_semana_rows.dart', // dia feito
    'lib/features/depoimentos/screens/depoimentos_personal_screen.dart', // nota / destaque
    'lib/features/exercicios/screens/exercicio_detail_screen_state.part.dart', // favorito
    'lib/features/exercicios/screens/exercicio_detail_screen_widgets.part.dart', // checklist feito
    'lib/features/exercicios/screens/widgets/exercicio_card.dart', // favorito / selecionado
    'lib/features/exercicios/screens/widgets/template_split_picker.dart', // selecionado
    'lib/features/feed/widgets/feed_post_card.dart', // curtido / fixado
    'lib/features/financeiro/screens/financeiro_mensalidades_tab.dart', // seleção em lote
    'lib/features/financeiro/screens/financeiro_mensalidades_tab_aluno.part.dart', // seleção em lote
    'lib/features/monetizacao/screens/cancel_save_screen.dart', // opção escolhida
    'lib/features/perfil/widgets/identidade_estilo_miniaturas.dart', // estilo escolhido
    'lib/features/perfil/widgets/perfil_lgpd_consent_sheet.dart', // consentimento dado
    'lib/features/treinos/widgets/aplicar_em_alunos_folha.dart', // aluno marcado
    'lib/features/treinos/widgets/exercise_library_row.dart', // favorito
    'lib/features/trilhas/screens/trilhas_screen_cards.part.dart', // marco concluído
  };

  test('ícone cheio (Fill) só em estado escolhido pelo usuário', () {
    final fill = RegExp(r'FxIcons\.\w+Ativ[oa]\b');
    final falhas = <String>{
      for (final (arq, codigo) in linhasDeCodigo())
        if (fill.hasMatch(codigo) &&
            !arq.endsWith('core/theme/fx_icons.dart') &&
            !permitidosFill.any(arq.endsWith))
          arq,
    };
    expect(falhas, isEmpty, reason: 'Fill é estado escolhido; sucesso e decoração usam Light.');
  });

  test('aba ativa da barra inferior usa o par Fill', () {
    expect(FxIcons.inicioAtivo.fontFamily, 'PhosphorFill');
    expect(FxIcons.inicio.fontFamily, 'PhosphorLight');
    expect(FxIcons.inicioAtivo.codePoint, FxIcons.inicio.codePoint);
  });
}
