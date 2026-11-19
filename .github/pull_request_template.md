## O que muda

<!-- Uma ou duas frases: o que mudou e por quê. -->

## Como foi testado

<!-- Testes automáticos e o que foi conferido à mão. Diga o que não foi verificado. -->

## Checklist

- [ ] `dart analyze --fatal-warnings --fatal-infos lib test` e `flutter test --no-pub` passaram
- [ ] Texto novo em `lib/l10n/app_pt.arb` (e `flutter gen-l10n` rodado)
- [ ] Rota nova registrada em `focux_surfaces_catalog.dart`
- [ ] Só papéis de tipografia do kit e ícones de `FxIcons`
- [ ] Mexe com pagamento, login, equipe ou dado de saúde: tem teste que prova o comportamento
- [ ] Nada de segredo, `.env`, dado real de usuário ou arquivo de ferramenta de IA no diff
- [ ] Linha no `CHANGELOG.md` (seção "Não lançado")
