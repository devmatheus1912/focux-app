import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/brand_style.dart';
import 'package:focux_app/features/perfil/widgets/identidade_estilo_miniaturas.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: Padding(
  padding: const EdgeInsets.all(16),
  child: child,
)));

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('mostra os três estilos e marca o escolhido', (tester) async {
    await tester.pumpWidget(
      _app(
        IdentidadeEstiloMiniaturas(
          selecionado: BrandStyle.cinematografico,
          primaria: const Color(0xFF0B4F5C),
          onSelecionar: (_) {},
        ),
      ),
    );
    expect(find.text('Clássico'), findsOneWidget);
    expect(find.text('Cinematográfico'), findsOneWidget);
    expect(find.text('Minimalista'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('tocar numa miniatura escolhe o estilo', (tester) async {
    BrandStyle? escolhido;
    await tester.pumpWidget(
      _app(
        IdentidadeEstiloMiniaturas(
          selecionado: BrandStyle.classico,
          primaria: const Color(0xFF0B4F5C),
          onSelecionar: (e) => escolhido = e,
        ),
      ),
    );
    await tester.tap(find.text('Minimalista'));
    expect(escolhido, BrandStyle.minimalista);
  });

  testWidgets('sem permissão (sem white-label) as miniaturas não respondem', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const IdentidadeEstiloMiniaturas(
          selecionado: BrandStyle.classico,
          primaria: Color(0xFF0B4F5C),
          onSelecionar: null,
        ),
      ),
    );
    await tester.tap(find.text('Minimalista'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('leitor de tela lê o estilo e se está selecionado', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        IdentidadeEstiloMiniaturas(
          selecionado: BrandStyle.classico,
          primaria: const Color(0xFF0B4F5C),
          onSelecionar: (_) {},
        ),
      ),
    );
    expect(find.bySemanticsLabel('Estilo Clássico'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('aguenta cor clara e letra grande sem estourar', (tester) async {
    tester.view.physicalSize = const Size(1080, 1800);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: _app(
          IdentidadeEstiloMiniaturas(
            selecionado: BrandStyle.cinematografico,
            primaria: const Color(0xFFFACC15),
            onSelecionar: (_) {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
