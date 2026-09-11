import 'package:flutter_test/flutter_test.dart';

import '../support/screen_source_bundle.dart';

/// A23 — contrato §14.2 nas superfícies de input do ALUNO.
void main() {
  test('perfil aluno editar: FxKeyboardDismissScope + viewInsets + onDrag', () {
    final screen = readScreenSourceBundle(
      'lib/features/dashboard/screens/perfil_aluno_editar_screen.dart',
    );
    expect(screen, contains('FxKeyboardDismissScope'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, contains('ScrollViewKeyboardDismissBehavior.onDrag'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('FxFormStickyBar'));
    expect(screen, contains('FxFormPopGuard'));
    expect(screen, contains('onTapOutside'));
  });

  test('anamnese aluno: FxKeyboardDismissScope + viewInsets', () {
    final screen = readScreenSourceBundle(
      'lib/features/anamnese/screens/anamnese_aluno_screen.dart',
    );
    expect(screen, contains('FxKeyboardDismissScope'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('FxFormStickyBar'));
  });

  test('checkin serie sheet: dismiss scope + onTapOutside + unfocus before pop', () {
    final sheet = readScreenSourceBundle(
      'lib/features/checkin/widgets/checkin_serie_detail_widgets.dart',
    );
    expect(sheet, contains('FxKeyboardDismissScope'));
    expect(sheet, contains('FxKeyboardDismissScope.dismiss'));
    expect(sheet, contains('keyboardDismissBehavior'));
    expect(sheet, contains('onTapOutside'));
    expect(sheet, contains('FxHomeSheetSurface'));
  });

  test('financeiro aluno + PIX sheet: viewInsets / form onTapOutside', () {
    final screen = readScreenSourceBundle(
      'lib/features/financeiro/screens/financeiro_aluno_screen.dart',
    );
    expect(screen, contains('viewInsetsOf'));
    final actions = readScreenSourceBundle(
      'lib/features/financeiro/utils/mensalidade_surface_actions.dart',
    );
    expect(actions, contains('mostrarPixMensalidade'));
    expect(actions, contains('FxHomeSheetSurface'));
    expect(actions, contains('FxHomeSheetChrome.dismissAndPop'));
    expect(actions, contains('onTapOutside'));
    expect(actions, contains('FxKeyboardDismissScope.dismiss'));
  });

  test('conversation composer: FxKeyboardDismissScope + onDrag', () {
    final screen = readScreenSourceBundle(
      'lib/features/chat/screens/conversation_screen.dart',
    );
    expect(screen, contains('FxKeyboardDismissScope'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('onTapOutside'));
  });

  test('definir senha aluno: AuthShell + viewInsets + onDrag', () {
    final screen = readScreenSourceBundle(
      'lib/features/auth/screens/definir_senha_aluno_screen.dart',
    );
    expect(screen, contains('AuthShell'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('authScrollPadding'));
    expect(screen, contains('primaryFocus?.unfocus()'));
  });

  test('register aluno: AuthShell + viewInsets + onDrag', () {
    final screen = readScreenSourceBundle(
      'lib/features/auth/screens/register_aluno_screen.dart',
    );
    expect(screen, contains('AuthShell'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('authScrollPadding'));
    expect(screen, contains('onTapOutside'));
  });

  test('activation aluno: unfocus before leave + onDrag', () {
    final screen = readScreenSourceBundle(
      'lib/features/dashboard/screens/aluno_activation_screen.dart',
    );
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, contains('keyboardDismissBehavior'));
  });

  test('depoimento aluno: FxKeyboardDismissScope + onDrag + onTapOutside', () {
    final screen = readScreenSourceBundle(
      'lib/features/depoimentos/screens/depoimento_aluno_screen.dart',
    );
    expect(screen, contains('FxKeyboardDismissScope'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('onTapOutside'));
    expect(screen, contains('FxFormStickyBar'));
  });

  test('habitos aluno: FxKeyboardDismissScope + viewInsets + busca', () {
    final screen = readScreenSourceBundle(
      'lib/features/habitos/screens/habitos_aluno_screen.dart',
    );
    expect(screen, contains('FxKeyboardDismissScope'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('onTapOutside'));
  });

  test('desafios aluno: FxKeyboardDismissScope + viewInsets + busca', () {
    final screen = readScreenSourceBundle(
      'lib/features/desafios/screens/desafios_aluno_screen.dart',
    );
    expect(screen, contains('FxKeyboardDismissScope'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('onTapOutside'));
  });

  test('excluir conta aluno sheet: onTapOutside dismiss', () {
    final src = readScreenSourceBundle(
      'lib/features/dashboard/utils/aluno_delete_account.dart',
    );
    expect(src, contains('showFxFormSheet'));
    expect(src, contains('onTapOutside'));
    expect(src, contains('FxKeyboardDismissScope.dismiss'));
  });
}
