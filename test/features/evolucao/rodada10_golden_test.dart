@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/brand_palette.dart';
import 'package:focux_app/features/dashboard/widgets/perfil_conquistas_linha.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/data/meta_corporal.dart';
import 'package:focux_app/features/evolucao/utils/evolucao_series.dart';
import 'package:focux_app/features/evolucao/widgets/evolucao_medidas_aba.dart';
import 'package:focux_app/features/evolucao/widgets/evolucao_recordes_aba.dart';
import 'package:focux_app/features/evolucao/widgets/registrar_carga_folha.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../support/tolerant_golden_comparator.dart';

RecordePessoal _r(int id, String data, double kg, {int? reps = 10}) => RecordePessoal(
  id: id,
  exercicioId: 7,
  exercicioNome: 'Abdominal bicicleta',
  data: data,
  cargaKg: kg,
  repeticoes: reps,
);

final _recordes = [
  _r(3, '2026-11-11', 20),
  _r(2, '2026-11-11', 10),
  _r(1, '2026-10-28', 15, reps: 12),
];

PontoGordura _p(String data, double valor) =>
    (data: data, valor: valor, avaliacaoId: null, conferido: false);

Widget _app(Widget filho) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(useMaterial3: true),
  locale: const Locale('pt'),
  supportedLocales: S.supportedLocales,
  localizationsDelegates: S.localizationsDelegates,
  home: Scaffold(body: filho),
);

Conquista _conquista(String chave, String exercicio, ConquistaTipo tipo) => Conquista(
  chave: chave,
  tipo: tipo,
  titulo: '20 kg',
  detalhe: 'detalhe',
  data: DateTime(2026, 11, 11),
  valor: '20 kg',
  exercicio: exercicio,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
  });

  void tela(WidgetTester tester, Size tamanho) {
    tester.view.physicalSize = tamanho * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  Widget abrir(Future<void> Function(BuildContext) acao) => Builder(
    builder: (context) => TextButton(onPressed: () => acao(context), child: const Text('abrir')),
  );

  testWidgets('folha de registros da Força', (tester) async {
    tela(tester, const Size(390, 760));
    final progresso = progressoDosRecordes(_recordes).single;
    await tester.pumpWidget(
      _app(
        abrir(
          (c) => abrirRegistrosDoExercicio(
            c,
            progresso,
            onEditar: (_) {},
            onExcluir: (_) {},
            onRegistrar: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await expectFocuxGolden(find.byType(MaterialApp), 'goldens/forca_registros.png');
  });

  testWidgets('folha Registrar carga', (tester) async {
    tela(tester, const Size(390, 800));
    await tester.pumpWidget(
      _app(
        abrir(
          (c) => abrirRegistrarCarga(
            c,
            recordes: _recordes,
            exercicioInicial: (id: 7, nome: 'Abdominal bicicleta'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Aumentar kg'));
    await tester.pumpAndSettle();
    await expectFocuxGolden(find.byType(MaterialApp), 'goldens/forca_registrar_carga.png');
  });

  testWidgets('selos do perfil sobre três marcas, legenda longa', (tester) async {
    tela(tester, const Size(390, 420));
    final conquistas = [
      _conquista('a', 'Abdominal bicicleta', ConquistaTipo.recorde),
      _conquista('b', 'Supino', ConquistaTipo.meta),
      _conquista('c', 'Agachamento livre com barra', ConquistaTipo.mantido),
    ];
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            for (final marca in const [
              Color(0xFF0B4F5C),
              Color(0xFFC73A3A),
              Color(0xFFB8E0D2),
            ])
              Container(
                color: BrandPalette.cardDeMarca(marca, dark: false).fundo,
                padding: const EdgeInsets.all(16),
                child: PerfilConquistasLinha(
                  conquistas: conquistas,
                  onAbrir: (_) {},
                  onVerTodas: () {},
                  marca: marca,
                ),
              ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectFocuxGolden(find.byType(MaterialApp), 'goldens/perfil_selos_marcas.png');
  });

  testWidgets('Corpo com massa magra e "Mesmo valor de"', (tester) async {
    tela(tester, const Size(390, 1100));
    await tester.pumpWidget(
      _app(
        EvolucaoMedidasAba(
          medidas: [
            MedidaCorporal(id: 1, data: '2026-10-30', peso: 105, cintura: 30),
            MedidaCorporal(id: 2, data: '2026-11-12', peso: 110, cintura: 40),
          ],
          gordura: [_p('2026-10-30', 20), _p('2026-11-04', 15), _p('2026-11-14', 20)],
          massa: [_p('2026-10-30', 80), _p('2026-11-04', 85), _p('2026-11-14', 80)],
          vazioSubtitulo: '',
          onAtualizar: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectFocuxGolden(find.byType(EvolucaoMedidasAba), 'goldens/corpo_com_massa.png');
  });
}
