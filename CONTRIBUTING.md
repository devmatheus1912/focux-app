# Como contribuir

Regras para mudar o app do Focux Personal. O app está nas lojas com usuários reais.

## Branches

| Branch | Uso |
|---|---|
| `develop` | Todo o trabalho do dia a dia. O CI roda em cada push |
| `main` | Só o que está publicado nas lojas. Não recebe commit direto |
| `hotfix/<nome>` | Correção urgente de produção, saída da `main` |

**Lançamento:** mescle a `develop` na `main` quando um lote de mudanças estiver pronto e siga [`docs/RELEASE.md`](docs/RELEASE.md).

**Hotfix:** crie `hotfix/<nome>` a partir da `main`, corrija com teste, mescle na `main` e depois de volta na `develop`.

**Dependabot:** as atualizações de versão abrem PR contra a `develop` (`target-branch` em `.github/dependabot.yml`); os alertas de segurança abrem contra a `main` e seguem o fluxo de hotfix.

## Antes de enviar

1. `dart analyze --fatal-warnings --fatal-infos lib test`
2. `flutter test --no-pub` (cerca de 7 minutos; os testes não rodam no CI)
3. Mudança que mexe com pagamento, login, equipe ou dado de saúde precisa de teste que prove o comportamento e de uma revisão de segurança focada.
4. Confira `git status`: nada de `.env`, segredo, dado real ou arquivo de ferramenta de IA (`.claude/`, `.cursor/`, `graphify-out/`, `.serena/`, `.impeccable/`, `PRODUCT.md`, `DESIGN.md`).

Atalho: `tool/verify.ps1` roda a análise, os testes e a busca de arquivos Dart órfãos.

## Regras do código

- Arquitetura e testes de contrato: [`docs/ARQUITETURA.md`](docs/ARQUITETURA.md).
- Visual (tipografia, ícones, cor, componentes): [`docs/DESIGN-SYSTEM.md`](docs/DESIGN-SYSTEM.md).
- Texto novo vai para `lib/l10n/app_pt.arb`, depois `flutter gen-l10n`. Não use `dart fix` (ele acrescenta `intl: any`).
- Rota nova entra em `lib/core/design_system/focux_surfaces_catalog.dart`.
- Feature nova nasce de uma spec aprovada (ver [`docs/PRODUTO.md`](docs/PRODUTO.md#como-uma-feature-nasce)).

## Commits

Mensagem em português, curta: um título que diz o que mudou e duas ou três linhas com o porquê. Exemplo:

```text
Login com Google sem texto técnico para o usuário

O erro 10 e o 503 do backend apareciam crus na tela. Agora o usuário lê
"Não deu para entrar com Google. Use e-mail e senha."
```

## Changelog

Toda mudança que vai para as lojas ganha uma linha no [`CHANGELOG.md`](CHANGELOG.md), na seção "Não lançado", escrita para quem usa o app.
