import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/perfil/data/white_label_repository.dart';
import 'package:focux_app/features/perfil/utils/white_label_display.dart';

void main() {
  test('verify domain só com host salvo igual ao draft e não verificado', () {
    expect(
      whiteLabelCanVerifyDomain(
        domainDraft: '',
        dominioSalvo: null,
        dominioVerificado: false,
      ),
      isFalse,
    );
    expect(
      whiteLabelCanVerifyDomain(
        domainDraft: 'treino.studio.com',
        dominioSalvo: null,
        dominioVerificado: false,
      ),
      isFalse,
    );
    expect(
      whiteLabelCanVerifyDomain(
        domainDraft: 'treino.studio.com',
        dominioSalvo: 'treino.studio.com',
        dominioVerificado: true,
      ),
      isFalse,
    );
    expect(
      whiteLabelCanVerifyDomain(
        domainDraft: 'treino.novo.com',
        dominioSalvo: 'treino.studio.com',
        dominioVerificado: false,
      ),
      isFalse,
    );
    expect(
      whiteLabelCanVerifyDomain(
        domainDraft: 'treino.studio.com',
        dominioSalvo: 'treino.studio.com',
        dominioVerificado: false,
      ),
      isTrue,
    );
  });

  test('dns steps limpam numeracao do BE', () {
    expect(
      whiteLabelDnsSteps(
        '1) CNAME treino.x.com → cname.focux.app\n'
        '2) TXT _focux.treino.x.com → focux-verify-abc\n'
        '3) Clique em Verificar domínio após propagar DNS (até 24h).',
      ),
      [
        'CNAME treino.x.com → cname.focux.app',
        'TXT _focux.treino.x.com → focux-verify-abc',
        'Clique em Verificar domínio após propagar DNS (até 24h).',
      ],
    );
    expect(
      whiteLabelCnameHint('treino.x.com', verificacaoToken: 'tok-1'),
      contains('cname.focux.app'),
    );
    expect(
      whiteLabelCnameHint('treino.x.com', verificacaoToken: 'tok-1'),
      contains('tok-1'),
    );
    expect(
      whiteLabelCnameHint(''),
      'CNAME → cname.focux.app · depois TXT _focux.',
    );
    expect(
      whiteLabelDnsStepShort('a' * 100, maxChars: 20).endsWith('…'),
      isTrue,
    );
    expect(whiteLabelLandingCaption('CAPTURA'), contains('captura'));
    expect(whiteLabelChecklistValue(true), 'Pronto');
  });

  test('checklist deep-link e gate SITE', () {
    expect(whiteLabelChecklistRoute('entrevista'), '/perfil/landing-editor');
    expect(whiteLabelChecklistRoute('gerado'), '/perfil/landing-editor');
    expect(whiteLabelChecklistRoute('publicado'), '/perfil/landing-editor');
    expect(whiteLabelChecklistRoute('cta'), '/perfil/editar');
    expect(whiteLabelChecklistRoute('captura'), isNull);
    expect(whiteLabelChecklistRoute('dominio'), isNull);
    expect(whiteLabelChecklistRoute('app'), isNull);
    expect(whiteLabelNeedsLandingCompleta('SITE'), isTrue);
    expect(whiteLabelNeedsLandingCompleta('CAPTURA'), isFalse);
    expect(whiteLabelNeedsLandingCompleta('site'), isTrue);
  });

  test('domínio próprio fica em breve até o BE liberar', () {
    expect(whiteLabelDominioEmBreveCaption, contains('Em breve'));
    expect(WhiteLabelConfig.fromJson({}).dominioDisponivel, isFalse);
    expect(
      WhiteLabelConfig.fromJson({'dominioDisponivel': true}).dominioDisponivel,
      isTrue,
    );
  });
}
