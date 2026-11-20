# Design system do app

Regras visuais do app, protegidas por testes de contrato em `test/core/design_system/`. A identidade da marca (logo, cores, voz, slogan) está no [guia de marca](../brand/brand_guidelines.md). Quando este documento e o código discordarem, vale o código e o documento é corrigido.

## Onde mora

| Peça | Arquivo |
|---|---|
| Tipografia | `FocuxHubTypography` (`lib/core/theme/focux_hub_typography.dart`) |
| Espaçamento e escala | `TokensStrip` (`lib/core/theme/tokens_strip.dart`) |
| Cores e cromo | `ShellChrome`, `BrandPalette`, `BrandStyle`, `BrandTint` (`lib/core/theme/`) |
| Ícones | `FxIcons` (`lib/core/theme/fx_icons.dart`) |
| Componentes | `lib/core/widgets/` (prefixo `Fx`) |

## Tipografia

Oito papéis, cada um com tamanho e peso fixos. A cor é de quem chama.

| Papel | Tamanho / peso | Uso |
|---|---|---|
| destaque | 32 / 700 | Número ou título de destaque |
| `pageTitle` | 22 / 700 | Título da página |
| `sectionTitle` | 17 / 600 | Título de seção e da barra do topo |
| `cardTitle` | 15 / 600 | Título de cartão |
| `body` | 15 / 400 | Texto corrido |
| `bodyMuted` | 13 / 400 | Texto secundário |
| `rotulo`, `chip`, `eyebrow` | 12 / 600 | Rótulos |
| `minimo` | 11 / 500 | Menor texto permitido |
| `numeroTela` | 40 / 700 | Teclado numérico, contador da série, anel |

- `TokensStrip.escala` = {11, 12, 13, 15, 17, 22, 32, 40}.
- Pesos: 400, 600 e 700 (500 só no mínimo). Nada de `fontSize` literal nem w800, w900 ou `bold` fora do kit (`tipografia_contract_test`). Exceções: PDF, `features/qa` e o emoji de reação do chat.
- Fonte: Inter.

## Ícones

- Só por `FxIcons` (Phosphor, fontes MIT em `assets/fonts/phosphor`), nomeados pelo significado. `Icons.*` e `CupertinoIcons.*` fora desse arquivo quebram `fx_icons_contract_test`.
- **Light** é o padrão. **Fill** (`*Ativo`/`*Ativa`) só para estado escolhido pelo usuário: aba ativa, selecionado, favorito, fixado, série feita. **Regular** (`*Pequeno`) para 16 pt ou menos.
- Barra inferior: `FxDockItem(icon, iconAtivo)`, 24 pt.
- Ícone com fundo só em `FxIconBadge` (marca a 12%, raio 12).
- Ícone novo: acrescente o conceito em `FxIcons`, com `const`.

## Cor e fundo

- Sem marca própria do personal, o app usa o teal Focux. Com marca própria, toda a interface respeita o `BrandStyle` do personal.
- **Bloco de marca:** `FxStripCard(marca: true)` faz o degradê da cor da marca, um por tela, no cartão principal (`bloco_de_marca_contract_test`). Texto dentro dele usa `fxPaletaSobreMarca`, nunca branco fixo, com contraste AA (`bloco_de_marca_contraste_test`).
- Verde, âmbar e vermelho só para status.
- **Fundo por página:** toda página pinta o próprio fundo (`FxFundoDaPagina`, via `pageTransitionsTheme`). Página transparente deixa a tela de baixo aparecer no gesto de voltar do iPhone (`fundo_opaco_transicao_test`).
- Anéis: `FxAnel`; cores de anel por `fxCoresDeAnel`, contraste 3:1 em qualquer marca.

## Componentes e padrões

- **Nenhuma ação é só texto** (`sem_acao_so_texto_contract_test`): principal `FxLiquidPrimaryButton`; secundária `FxTonalButton`; "ver mais" `FxActionLink` ou `FxLinkRow`; só ícone é `IconButton` com `tooltip`.
- Botão principal sem ação fica apagado e o leitor de tela diz "desativado".
- **Folhas:** `FxSheetFrame`, `showFxGroupedActionSheet`, `FxSheetSearchField`, `FxQuickChips` (`sheets_kit_contract_test`). Confirmação por `showFxConfirmSheet`, com dois botões da mesma largura.
- **Estados:** `FxEmptyState`, `FxErrorState`, `FxTelaCarregando`.
- **Horário:** `showFxHorario` (24 h); `showTimePicker` não é usado fora dele.
- **Teclado:** `FxShellInsetOwner` cuida do inset nas abas. Rodapé dentro do corpo não soma `viewInsetsOf(context).bottom`; só o rodapé em `bottomNavigationBar` (`FxFormStickyBar`) soma (`rodape_teclado_contract_test`).
- **Avisos com ação:** todo `SnackBar` com `action` declara `persist` (`feedback_helper_persist_test`).
- **Ajuda:** cada tela tem `FxHelpIconButton` com uma folha `*_help_sheet.dart`.
- **Segundo toque na aba:** `fxTocarAba` volta à aba inicial ou sobe a lista ao topo.

## Pendências da marca no app

- Fundo claro ainda usa o mesh (`#E4EFF1 → #F4F6F8 → #EDF2F4`) com brilhos; o guia pede paper `#F4F6F8` sólido.
