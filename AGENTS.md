# Focux App — padrões de engenharia

Regras obrigatórias para implementação, revisão e entrega de código neste repositório.

## Refatoração completa robusta

Toda feature ou revisão relevante deve deixar o código **limpo, escalável e sem duplicação** — não apenas “funcionar”.

### Estrutura de feature

```
lib/features/<feature>/
  constants/   # enums, layout tokens, filtros
  data/        # repositories, stores
  providers/   # Riverpod
  utils/       # funções puras (sem Widget)
  widgets/     # componentes reutilizáveis
  screens/     # telas; >400 linhas → part files ou widgets extraídos
```

### Regras

1. **Zero duplicação** — mídia, formatação, status, avatares: uma única fonte.
2. **Telas grandes** — `screen.dart` + `screen_<área>.part.dart` ou widgets em `widgets/`.
3. **Tokens de layout** — alturas, sticky, padding de scroll em `constants/`.
4. **Utils testáveis** — lógica fora de `build()`; testes unitários para utils novos.
5. **Analyze limpo** — `flutter analyze` na feature alterada sem warnings.

## Git (obrigatório)

Após cada entrega funcional (fix, feature, refactor):

1. `flutter analyze` + testes da feature.
2. **Commit** com mensagem Conventional Commits (`fix:`, `feat:`, `refactor:`).
3. **Push** para `origin` na branch de trabalho.

Não commitar: `.env`, credenciais, alterações locais não relacionadas (ex.: WIP de outras features).

## Checklist antes de concluir

- [ ] Imports mortos removidos
- [ ] Nenhum arquivo de tela monolítico > ~500 linhas sem split
- [ ] Testes da feature passando
- [ ] Commit + push realizados
