import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/convites/utils/convite_display.dart';

void main() {
  final now = DateTime(2026, 8, 31, 12);

  test('conviteRemainingLabel', () {
    expect(conviteRemainingLabel(null, now), '24h');
    expect(conviteRemainingLabel(now.subtract(const Duration(minutes: 1)), now),
        'Expirado');
    expect(
      conviteRemainingLabel(now.add(const Duration(hours: 2, minutes: 5)), now),
      '2h 5min',
    );
    expect(
      conviteRemainingLabel(now.add(const Duration(minutes: 12)), now),
      '12min',
    );
  });

  test('conviteAindaValido', () {
    expect(conviteAindaValido(null, now), isFalse);
    expect(conviteAindaValido(now.add(const Duration(minutes: 1)), now), isTrue);
    expect(
      conviteAindaValido(now.subtract(const Duration(seconds: 1)), now),
      isFalse,
    );
  });

  test('conviteCountLabel', () {
    expect(conviteCountLabel(ativo: false), 'Nenhum convite ativo');
    expect(conviteCountLabel(ativo: true), '1 convite ativo');
  });

  test('conviteShareMessage inclui o nome', () {
    expect(
      conviteShareMessage(personalNome: 'Ana', shareLink: 'https://x'),
      contains('Sou Ana'),
    );
    expect(
      conviteShareMessage(personalNome: '  ', shareLink: 'https://x'),
      contains('seu personal'),
    );
  });
}
