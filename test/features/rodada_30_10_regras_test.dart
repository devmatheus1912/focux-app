import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/aluno360_ferramentas_grupos.dart';
import 'package:focux_app/features/feed/utils/feed_display.dart';
import 'package:focux_app/features/ia/utils/progressao_copy.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';
import 'package:focux_app/features/subscription/widgets/fx_upgrade_sales_sheet.dart';

void main() {
  group('composição corporal', () {
    test('massa magra em % dentro da faixa não pede conferência', () {
      expect(composicaoSuspeita(bf: '15%', massaMagra: '45%'), isFalse);
      expect(aluno360ComposicaoValor(bf: '15%', massaMagra: '45%'), 'OK');
    });

    test('valor impossível pede conferência', () {
      expect(composicaoSuspeita(bf: '818%', massaMagra: '45%'), isTrue);
      expect(composicaoSuspeita(bf: '15%', massaMagra: '120%'), isTrue);
      expect(
        aluno360ComposicaoValor(bf: '818%', massaMagra: '45%'),
        'Confira o valor',
      );
    });

    test('bordas da faixa', () {
      expect(composicaoSuspeita(massaMagra: '20'), isFalse);
      expect(composicaoSuspeita(massaMagra: '95'), isFalse);
      expect(composicaoSuspeita(massaMagra: '19,9'), isTrue);
    });
  });

  group('ajustar cargas', () {
    test('objetivo parte do aluno', () {
      expect(progressaoObjetivoDoAluno('Ganho de força'), ProgressaoObjetivo.forca);
      expect(
        progressaoObjetivoDoAluno('Resistência'),
        ProgressaoObjetivo.resistencia,
      );
      expect(progressaoObjetivoDoAluno(null), ProgressaoObjetivo.hipertrofia);
    });
  });

  group('preço no bloqueio', () {
    test('com teste, sem teste e sem rede', () {
      expect(
        upgradeLinhaDePreco(
          plan: SubscriptionPlan.PRO,
          precoMensal: 99.9,
          teste: true,
        ),
        '30 dias grátis, depois R\$ 99,90/mês',
      );
      expect(
        upgradeLinhaDePreco(
          plan: SubscriptionPlan.PRO,
          precoMensal: 99.9,
          teste: false,
        ),
        'Pro · R\$ 99,90/mês',
      );
      expect(
        upgradeLinhaDePreco(
          plan: SubscriptionPlan.PRO,
          precoMensal: null,
          teste: false,
        ),
        'Plano Pro',
      );
    });

    test('teste grátis só do Free para o Pro', () {
      expect(
        upgradeTemTeste(
          plan: SubscriptionPlan.PRO,
          atual: SubscriptionPlan.FREE,
          elegivel: true,
        ),
        isTrue,
      );
      expect(
        upgradeTemTeste(
          plan: SubscriptionPlan.ENTERPRISE,
          atual: SubscriptionPlan.PRO,
          elegivel: true,
        ),
        isFalse,
      );
    });
  });

  test('feed só mostra filtros quando ajudam', () {
    expect(feedMostraFiltros(total: 1, query: '', filtrando: false), isFalse);
    expect(feedMostraFiltros(total: 5, query: '', filtrando: false), isTrue);
    expect(feedMostraFiltros(total: 1, query: 'a', filtrando: false), isTrue);
    expect(feedMostraFiltros(total: 0, query: '', filtrando: true), isTrue);
  });
}
