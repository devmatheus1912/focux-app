import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/legal/focux_legal.dart';
import 'package:focux_app/features/perfil/data/lgpd_consent_repository.dart';
import 'package:focux_app/features/perfil/utils/lgpd_consent_display.dart';
import 'package:focux_app/features/perfil/widgets/perfil_lgpd_consent_sheet.dart';

class _FakeRepo implements LgpdConsentRepository {
  _FakeRepo(this.aceites);

  final Map<String, LgpdConsent> aceites;

  @override
  Future<Map<String, LgpdConsent>> ultimosPorTipo() async => aceites;

  @override
  Future<LgpdConsent?> ultimo() async => null;

  @override
  Future<LgpdConsent> registrar({
    required String tipo,
    String versao = FocuxLegal.consentDocumentVersion,
  }) async => LgpdConsent(tipo: tipo, versao: versao, aceitoEm: '');
}

Future<List<String>> _pump(
  WidgetTester tester, {
  required Map<String, LgpdConsent> aceites,
  required List<String> tipos,
}) async {
  final abertos = <String>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        lgpdConsentRepositoryProvider.overrideWithValue(_FakeRepo(aceites)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PerfilLgpdConsentBody(
            tipos: tipos,
            onAbrirDoc: (t) async => abertos.add(t),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return abertos;
}

void main() {
  testWidgets('status independente por documento', (tester) async {
    await _pump(
      tester,
      tipos: lgpdConsentTiposPersonal,
      aceites: {
        'TERMOS': const LgpdConsent(
          tipo: 'TERMOS',
          versao: FocuxLegal.consentDocumentVersion,
          aceitoEm: '2026-09-10T10:00:00',
        ),
      },
    );

    expect(find.text('1 de 2 aceitos'), findsOneWidget);
    expect(find.textContaining('Aceito em'), findsOneWidget);
    expect(find.text('Ler e aceitar'), findsOneWidget);
    expect(find.textContaining('Só ler'), findsNothing);
  });

  testWidgets('versão antiga pede novo aceite', (tester) async {
    await _pump(
      tester,
      tipos: const ['TERMOS'],
      aceites: {
        'TERMOS': const LgpdConsent(
          tipo: 'TERMOS',
          versao: '2000-01',
          aceitoEm: '2000-01-10T10:00:00',
        ),
      },
    );

    expect(find.text('Nova versão disponível'), findsOneWidget);
    expect(find.text('Ler e aceitar'), findsOneWidget);
  });

  testWidgets('tocar em dados de saúde abre o documento', (tester) async {
    final abertos = await _pump(
      tester,
      tipos: lgpdConsentTiposAluno,
      aceites: const {},
    );

    await tester.tap(find.text('Dados de saúde'));
    await tester.pump();

    expect(abertos, ['SAUDE']);
  });
}
