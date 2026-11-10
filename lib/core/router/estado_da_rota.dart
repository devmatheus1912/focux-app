import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Último estado lido por rota, para a tela que está saindo.
final Expando<GoRouterState> _ultimoEstado = Expando<GoRouterState>(
  'estadoDaRota',
);

/// Única porta para o estado do go_router no app.
///
/// `GoRouterState.of` (go_router 18) entra em laço infinito quando a rota já
/// saiu do registro (o pop completa no início da animação) e o widget
/// reconstrói dentro de um `ShellRoute`: sobe para o navigator do shell, e
/// `Navigator.maybeOf` devolve o próprio navigator para sempre (FLUTTER-4,
/// FLUTTER-5). Rota saindo não chama o go_router: devolve o último estado
/// guardado dela, e a tela mantém o layout até o fim da animação.
///
/// `null` quando não há estado (fora de rota do go_router, ou rota saindo sem
/// leitura anterior).
GoRouterState? estadoDaRota(BuildContext context) {
  final rota = ModalRoute.of(context);
  if (rota != null && !rota.isActive) return _ultimoEstado[rota];
  try {
    // A porta: o resto do app não chama GoRouterState.of direto.
    final estado = GoRouterState.of(context);
    if (rota != null) _ultimoEstado[rota] = estado;
    return estado;
  } on GoError {
    return null;
  }
}

/// Endereço da rota deste [context]; vazio quando não há estado.
Uri uriDaRota(BuildContext context) => estadoDaRota(context)?.uri ?? Uri();
