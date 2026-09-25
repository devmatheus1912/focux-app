import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/referral/data/referral_info.dart';
import 'package:focux_app/features/referral/utils/referral_display.dart';
import 'package:focux_app/l10n/app_localizations.dart';

ReferralInfo _info({
  bool campanhaAtiva = true,
  int concedidas = 0,
  int emAnalise = 0,
  int diasGanhos = 0,
  bool limite = false,
  int? desconto = 20,
}) => ReferralInfo(
  codigo: 'ABCD234567',
  usosTotais: concedidas,
  linkCompartilhamento: 'https://focux.app/cadastro?ref=ABCD234567',
  campanhaAtiva: campanhaAtiva,
  recompensasConcedidas: concedidas,
  recompensasEmAnalise: emAnalise,
  maxRecompensas: campanhaAtiva ? 3 : null,
  diasGanhos: diasGanhos,
  tetoDias: campanhaAtiva ? 90 : null,
  diasPorIndicacao: campanhaAtiva ? 30 : null,
  descontoIndicadoPct: campanhaAtiva ? desconto : null,
  limiteAtingido: limite,
);

void main() {
  final pt = lookupS(const Locale('pt'));
  final en = lookupS(const Locale('en'));

  test('codigo e link', () {
    expect(referralCodigoLabel('ABC12'), 'ABC12');
    expect(referralCodigoLabel('  '), '—');
    expect(referralCodigoLabel(null), '—');
    expect(referralTemLink('https://x'), isTrue);
    expect(referralTemLink('  '), isFalse);
    expect(referralTemLink(null), isFalse);
  });

  test('convite usa o desconto que o servidor mandou', () {
    expect(
      referralInviteText(pt, _info()),
      'Use meu código ABCD234567 e ganhe 20% off na 1ª cobrança do Focux Personal.\n'
      'https://focux.app/cadastro?ref=ABCD234567',
    );
    expect(
      referralInviteText(pt, _info(desconto: 0)),
      'Use meu código ABCD234567 no cadastro do Focux Personal.\n'
      'https://focux.app/cadastro?ref=ABCD234567',
    );
    expect(
      referralInviteText(pt, _info(campanhaAtiva: false)),
      startsWith('Use meu código ABCD234567 no cadastro'),
    );
  });

  test('subtitulo do hub segue a campanha e junta freshness', () {
    expect(referralHubSubtitle(pt, null, null), 'Indique e ganhe');
    expect(
      referralHubSubtitle(pt, _info(), 'Atualizado agora'),
      '30 dias extras por indicação · Atualizado agora',
    );
    expect(
      referralHubSubtitle(pt, _info(campanhaAtiva: false), null),
      'Campanha pausada',
    );
    expect(referralHubSubtitle(en, _info(), null), '30 extra days per referral');
  });

  test('progresso X de N recompensas e Y de M dias', () {
    final info = _info(concedidas: 2, diasGanhos: 60);
    expect(referralRewardsProgress(pt, info), '2 de 3');
    expect(referralDaysProgress(pt, info), '60 de 90 dias');
    final pausada = _info(campanhaAtiva: false, diasGanhos: 30);
    expect(referralRewardsProgress(pt, pausada), isNull);
    expect(referralDaysProgress(pt, pausada), '30');
    expect(referralRewardHeadline(pt, pausada), isNull);
    expect(referralDiscountLine(pt, pausada), isNull);
    expect(referralDiscountLine(pt, _info()), contains('20% off'));
  });

  test('banner prioriza campanha pausada, depois analise, depois limite', () {
    expect(referralBanner(_info()), ReferralBanner.none);
    expect(referralBanner(_info(limite: true)), ReferralBanner.limitReached);
    expect(
      referralBanner(_info(limite: true, emAnalise: 1)),
      ReferralBanner.underReview,
    );
    expect(
      referralBanner(_info(campanhaAtiva: false, limite: true)),
      ReferralBanner.campaignInactive,
    );
    expect(referralBannerText(pt, _info()), isNull);
    expect(
      referralBannerText(pt, _info(emAnalise: 2)),
      startsWith('2 recompensas em análise'),
    );
  });

  test('status de cada indicacao com rotulo e tom', () {
    ReferralIndicacao item(ReferralIndicacaoStatus s, {int dias = 0}) =>
        ReferralIndicacao(id: 1, nomeMascarado: 'Maria L.', status: s, dias: dias);
    expect(
      referralStatusLabel(pt, item(ReferralIndicacaoStatus.rewardGranted, dias: 30)),
      '+30 dias no seu plano',
    );
    expect(
      referralStatusLabel(pt, item(ReferralIndicacaoStatus.pending)),
      'Cadastrou, ainda não assinou',
    );
    for (final s in ReferralIndicacaoStatus.values) {
      expect(referralStatusLabel(pt, item(s)), isNotEmpty);
      expect(referralStatusLabel(en, item(s)), isNotEmpty);
    }
    expect(
      referralStatusTone(ReferralIndicacaoStatus.rewardGranted),
      ReferralTone.positive,
    );
    expect(
      referralStatusTone(ReferralIndicacaoStatus.underReview),
      ReferralTone.warning,
    );
    expect(
      referralStatusTone(ReferralIndicacaoStatus.reversed),
      ReferralTone.negative,
    );
    expect(referralStatusTone(ReferralIndicacaoStatus.trial), ReferralTone.neutral);
  });

  test('como funciona usa os numeros da campanha ou texto generico', () {
    final passos = referralComoFuncionaPassos(pt, _info());
    expect(passos, hasLength(3));
    expect(passos.last.titulo, '3. Você ganha 30 dias');
    expect(passos.last.detalhe, 'Até 3 recompensas, no máximo 90 dias no total.');
    final generico = referralComoFuncionaPassos(pt, _info(campanhaAtiva: false));
    expect(generico.last.titulo, '3. Você ganha dias extras');
  });

  test('parse do painel tolera campos ausentes e status desconhecido', () {
    final info = ReferralInfo.fromJson({
      'codigo': 'X1Y2Z3W4V5',
      'usosTotais': 4,
      'linkCompartilhamento': 'https://x/cadastro?ref=X1Y2Z3W4V5',
      'campanhaAtiva': true,
      'recompensasConcedidas': 3,
      'maxRecompensas': 3,
      'diasGanhos': 90,
      'tetoDias': 90,
      'limiteAtingido': true,
      'indicacoes': [
        {'id': 9, 'nomeMascarado': 'Ana C.', 'status': 'NO_REWARD', 'dias': 0},
        {'id': 10, 'nomeMascarado': 'Bia D.', 'status': 'ALGO_NOVO'},
        'lixo',
      ],
    });
    expect(info.limiteAtingido, isTrue);
    expect(info.indicacoes, hasLength(2));
    expect(info.indicacoes.first.status, ReferralIndicacaoStatus.noReward);
    expect(info.indicacoes.last.status, ReferralIndicacaoStatus.notEligible);
    expect(info.diasPorIndicacao, isNull);

    final vazio = ReferralInfo.fromJson(const {});
    expect(vazio.campanhaAtiva, isFalse);
    expect(vazio.indicacoes, isEmpty);
  });
}
