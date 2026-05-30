import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/planos/paywall/paywall_catalog.dart';
import 'package:focux_app/features/planos/paywall/paywall_vitrine.dart';

void main() {
  test('fromApi parses social proof', () {
    final snapshot = PaywallVitrineSnapshot.fromApi({
      'socialProof': [
        {'value': '100', 'label': 'test'},
      ],
    });
    expect(snapshot.socialProof, [(value: '100', label: 'test')]);
  });

  test('fromApi falls back when empty', () {
    final snapshot = PaywallVitrineSnapshot.fromApi({'socialProof': []});
    expect(snapshot.socialProof, PaywallCatalog.socialProof);
  });
}
