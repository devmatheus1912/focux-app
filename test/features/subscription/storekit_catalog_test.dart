import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/subscription/subscription_products.dart';

void main() {
  test('Products.storekit inclui todos os SKUs de assinatura', () {
    final raw = File('ios/Products.storekit').readAsStringSync();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final productIds = <String>{};

    void collectProductIds(Object? node) {
      if (node is Map<String, dynamic>) {
        final id = node['productID'];
        if (id is String && id.isNotEmpty) {
          productIds.add(id);
        }
        for (final value in node.values) {
          collectProductIds(value);
        }
      } else if (node is List) {
        for (final item in node) {
          collectProductIds(item);
        }
      }
    }

    collectProductIds(decoded);

    for (final expected in SubscriptionProducts.allStoreProductIds) {
      expect(
        productIds,
        contains(expected),
        reason: 'ios/Products.storekit deve definir $expected',
      );
    }
  });
}
