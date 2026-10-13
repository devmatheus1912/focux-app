import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_cached_network_image.dart';

void main() {
  test('URL assinada usa a URL sem assinatura como chave de cache', () {
    const base = 'https://media.example.com/priv/p1/chat/a.jpg';
    expect(mediaCacheKey('$base?Expires=1&Signature=abc&Key-Pair-Id=K'), base);
  });

  test('URL comum mantém a query', () {
    const url = 'https://res.cloudinary.com/demo/image/upload/a.jpg?_v=3';
    expect(mediaCacheKey(url), url);
    expect(
      mediaCacheKey('https://x.example.com/a.jpg'),
      'https://x.example.com/a.jpg',
    );
  });
}
