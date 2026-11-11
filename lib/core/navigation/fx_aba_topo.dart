import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Toque na aba do dock. Outra aba: troca. A mesma, fora da tela inicial dela:
/// volta à inicial. A mesma, já na inicial: sobe a lista ao topo.
void fxTocarAba(
  BuildContext context,
  StatefulNavigationShell shell,
  int index, {
  required List<String> raizes,
}) {
  if (index != shell.currentIndex) {
    shell.goBranch(index);
    return;
  }
  final atual = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
  final raiz = index < raizes.length ? raizes[index] : null;
  if (raiz != null && atual == raiz) {
    fxRolarAbaAtivaAoTopo(context);
    return;
  }
  shell.goBranch(index, initialLocation: true);
}

/// Rola ao topo a primeira lista vertical da aba visível (as abas fora da
/// tela ficam com TickerMode desligado no FxLazyIndexedStack). Lista invertida
/// (conversa) vai para a mensagem mais recente, que é o "topo" dela.
void fxRolarAbaAtivaAoTopo(BuildContext context) {
  ScrollableState? alvo;
  void visitar(Element e) {
    if (alvo != null) return;
    if (e is StatefulElement && e.state is ScrollableState) {
      final st = e.state as ScrollableState;
      final vertical = st.position.axis == Axis.vertical;
      final ativa = TickerMode.valuesOf(e).enabled;
      if (vertical && ativa && st.position.maxScrollExtent > 0) {
        alvo = st;
        return;
      }
    }
    e.visitChildren(visitar);
  }

  context.visitChildElements(visitar);
  final pos = alvo?.position;
  if (pos == null || pos.pixels <= pos.minScrollExtent) return;
  pos.animateTo(
    pos.minScrollExtent,
    duration: const Duration(milliseconds: 320),
    curve: Curves.easeOutCubic,
  );
}
