# Focux Personal — Brand Guidelines

> Versão 1.0 · novembro de 2026 · documento interno e confidencial.
> Versão visual: [`brand/brand_guidelines.html`](brand/brand_guidelines.html) (abre no navegador, sem dependências).

Este guia junta num lugar só o que hoje está espalhado pelo código do app (`lib/core/theme/`), pelo site (`client/src/index.css`, `design-system/`) e por `brand/styleguide.txt`. Quando o guia e o código discordarem, **o código em produção vence** e este arquivo deve ser corrigido.

---

## Sumário

1. [Essência da marca](#1-essência-da-marca)
2. [Nome e grafia](#2-nome-e-grafia)
3. [Logo](#3-logo)
4. [Cores](#4-cores)
5. [Tipografia](#5-tipografia)
6. [Iconografia](#6-iconografia)
7. [Forma: espaçamento, raios, sombras e superfícies](#7-forma-espaçamento-raios-sombras-e-superfícies)
8. [Movimento](#8-movimento)
9. [Imagens e capturas de tela](#9-imagens-e-capturas-de-tela)
10. [Voz e tom](#10-voz-e-tom)
11. [Vocabulário do produto](#11-vocabulário-do-produto)
12. [Marca do personal (white-label)](#12-marca-do-personal-white-label)
13. [Acessibilidade](#13-acessibilidade)
14. [Aplicações](#14-aplicações)
15. [Dados institucionais](#15-dados-institucionais)
16. [Fontes da verdade e governança](#16-fontes-da-verdade-e-governança)
17. [Pendências encontradas na auditoria](#17-pendências-encontradas-na-auditoria)

---

## 1. Essência da marca

### O que é

**Focux Personal** é o aplicativo para personal trainers operarem a assessoria com clareza: alunos, treinos, cobrança e marca no mesmo lugar, fora do improviso do WhatsApp e da planilha.

### Para quem

| Público | O que busca |
|---|---|
| **Personal autônomo** | Parar de perder aluno e mensalidade no meio das conversas |
| **Assessoria online** | Escala de acompanhamento sem perder o contato individual |
| **Studio** | Operação organizada e marca própria diante do aluno |
| **Aluno** (usuário secundário) | Saber o que treinar hoje, registrar a execução e falar com o personal |

### Promessa

> Quem treinou, quem pagou e quem sumiu aparecem numa tela só.

### Posicionamento

- **Categoria:** sistema operacional para personal trainer.
- **Inimigo:** o improviso. WhatsApp, planilha, print e cobrança constrangedora.
- **Valor real:** retenção, tempo recuperado, cobrança organizada (PIX) e marca própria. Treino bonito é consequência, não o argumento principal.
- **Prova:** capturas reais do app, números reais da oferta, nunca depoimento inventado.

### Personalidade

| Somos | Não somos |
|---|---|
| Profissionais e calmos | Corporativos e frios |
| Concretos (números, telas, ações) | Vagos ("revolucionário", "o futuro") |
| Do lado do personal | Substitutos do personal |
| Sóbrios, editoriais | Gamer, neon, "fitness agressivo" |
| Honestos sobre limites e preços | Inflados de promessa |

---

## 2. Nome e grafia

| Situação | Forma correta |
|---|---|
| Nome completo da marca | **Focux Personal** |
| Forma curta (depois da primeira menção) | **Focux** |
| Logo (wordmark) | FOCUX / PERSONAL (caixa alta só no logo) |
| Domínio | focuxpersonal.com |

**Não usar:** "FOCUX" em caixa alta no texto corrido, "Focus", "FocuX", "Focux App", "focux personal" em minúsculas em títulos.

---

## 3. Logo

### Construção

O logo é composto por:

1. **Símbolo** — um braço flexionado (bíceps) segurando um smartphone. Traduz a proposta: o treino e a gestão do personal na mão, pelo app.
2. **Wordmark** — "FOCU" em grafite e o **"X" em azul petróleo**, em sans geométrica de cantos arredondados.
3. **Assinatura** — "PERSONAL" em azul petróleo, caixa alta, com espaçamento largo e um fio horizontal de cada lado.

### Versões oficiais

| Versão | Arquivo | Usar em |
|---|---|---|
| Fundo claro | `brand/Logo-oficial-ParaFundoClaro.png` → `assets/images/logo_oficial_fundo_claro.png` | Fundos brancos ou `#F4F6F8` |
| Fundo escuro | `brand/Logo-oficial-ParaFundoEscuro.png` → `assets/images/logo_oficial_fundo_escuro.png` | Fundos `#0B0E14`, `#121820` ou petróleo profundo |
| Splash | `assets/images/logo_splash*.png` (cópia da variante escura) | Splash nativo sobre `#0B0E14` |
| Ícone / launcher | `assets/images/logo_icon_*.png` (cópia da variante clara) | Ícone do app sobre fundo branco |
| Site | `client/public/focux-logo.png`, `focux-logo-light.png`, `favicon.png`, `email-logo.png` | Site, favicon e e-mails |

No app, o widget `FocuxOfficialLogo` escolhe a versão pelo brilho do tema (`light` → fundo claro; `dark` / `AuthShell forceDark` → fundo escuro). Os arquivos são a fonte da verdade: **não alterar pixels** e não redesenhar.

### Cores do logo

| Parte | Cor no arquivo | Observação |
|---|---|---|
| Símbolo, "X", "PERSONAL" | `#016B7E` (petróleo do logo) | Um pouco mais luminoso que o primário de interface `#0B4F5C`. Não "corrigir" o logo para o primário. |
| "FOCU" (fundo claro) | `#252A2E` (grafite) | — |
| "FOCU" (fundo escuro) | `#FDFDFD` (branco) | — |

### Área de proteção

Mantenha ao redor do logo um espaço livre igual à **altura do "X" do wordmark** em todos os lados. Nada de texto, borda ou outro elemento dentro dessa área.

### Tamanho mínimo

| Versão | Digital | Impresso |
|---|---|---|
| Logo completo (símbolo + wordmark) | 96 px de largura | 25 mm |
| Só o símbolo (ícone) | 24 px | 8 mm |

Abaixo do mínimo, a assinatura "PERSONAL" deixa de ser legível: use só o símbolo.

### Usos incorretos

- Esticar, achatar ou girar o logo.
- Trocar as cores do wordmark ou deixar o "X" da mesma cor do "FOCU".
- Aplicar a versão de fundo claro sobre fundo escuro (o "FOCU" grafite some), ou o contrário.
- Colocar o logo sobre foto movimentada sem uma camada sólida por trás.
- Adicionar sombra, contorno, brilho, gradiente ou efeito 3D.
- Separar o símbolo do wordmark e reposicionar livremente.
- Recriar o wordmark com outra fonte.
- Usar o logo antigo ciano (`#13C2C2` / `#1EC8C8`), já aposentado.

---

## 4. Cores

A marca é **azul petróleo** com neutros frios e um escuro **cinematográfico**. Os tokens abaixo existem no app (`EagleTokens`, `TokensStrip`) e no site (`--fx-*` em `index.css`).

### 4.1 Azul petróleo (marca)

| Token | Hex | App | Site | Uso |
|---|---|---|---|---|
| Primary | `#0B4F5C` | `EagleTokens.brand` | `--fx-primary` / `petrol` | CTA, botões, seleção, foco |
| Ink / hover | `#083D47` | `brandInk` | `--fx-hover` | Hover/pressed do CTA, H2 no claro |
| Mid | `#0A6B7A` | `brandSecondary` | `--fx-mid` / `petrol-mid` | Links, títulos de seção |
| Glow / accent | `#3D9AAD` | `brandAccent` | `--fx-glow` / `glow` | Acento no escuro, brilho interno |
| Soft | `#D5E8EC` | `brandSoft` | `--fx-soft` / `soft` | Chip selecionado, fundos de destaque |
| Softer | `#EBF4F6` | `brandSofter` | — | Tooltip, lavagem leve |
| Deep | `#051F26` | `brandDeep` | `--fx-deep` / `deep` | Mesh e gradientes profundos |

### 4.2 Neutros — tema claro

| Token | Hex | Uso |
|---|---|---|
| Paper | `#F4F6F8` | Fundo de página |
| Card | `#FFFFFF` | Cartões e superfícies |
| Card hi | `#EEF2F5` | Preenchimento neutro de card |
| Ink | `#1A1A2E` | Texto principal |
| Ink soft | `#2E3840` | Texto de apoio forte |
| Ink gray | `#4B5563` | Texto secundário no app |
| Ink mute | `#6B7280` | Texto terciário (ver contraste) |
| Line | `#E5E7EB` | Bordas e divisores |
| Line soft | `#ECF0F2` | Divisores leves |

### 4.3 Neutros — tema escuro (cinematic)

| Token | Hex | Uso |
|---|---|---|
| Cinematic bg | `#0B0E14` | Fundo escuro, splash, hero do site |
| Surface | `#121820` | Cartões |
| Elevated | `#1A2330` | Cartão elevado, sheets |
| Line | `#1E2830` | Bordas |
| Text | `#E8EDF2` | Texto principal |
| Text mute | `#9AA8B3` | Texto secundário |

### 4.4 Semânticas

| Papel | Claro | Fundo suave | Escuro |
|---|---|---|---|
| Sucesso / bom | `#1B8C54` | `#E2F4EB` | `#6FE296` |
| Atenção | `#B5760A` | `#FFF3DD` | `#E2B46F` |
| Erro / risco | `#C73A3A` | `#FCE8E8` | `#FF8B8B` |
| Erro em texto pequeno | `#B42318` | — | — |
| Premium (ouro) | `#E5B84C` · texto `#9A6B12` | `#FFF8E6` | — |

Regras de semântica usadas no produto:

- **Aderência:** ≥ 75% bom · 50–74% atenção · < 50% risco.
- **Scores 0–100:** ≥ 80 bom · 60–79 atenção · < 60 risco.

Verde, âmbar e vermelho **não são cores de marca**: só comunicam estado. Nunca use vermelho como decoração.

### 4.5 Proporção

| Fatia | Cor |
|---|---|
| ~70% | Neutros (paper/card no claro, cinematic/surface no escuro) |
| ~20% | Ink / texto |
| ~10% | Azul petróleo (ações, seleção, um destaque por tela) |

O petróleo funciona por escassez. Uma tela com tudo em petróleo perde a hierarquia.

### 4.6 Gradientes

- **Hero mesh escuro** (auth, splash, hero do site): `#0B0E14 → #0A2A32 → #121820`.
- **Mesh claro:** `#E4EFF1 → #F4F6F8 → #EDF2F4`.
- **Card de marca:** a primária sólida, levemente escurecida, variando só a luminosidade (no máximo 6%). Sem segunda cor e sem brilho.
- Brilho ("circuit glow") só como sombra interna com `#3D9AAD` a 35%. **Nunca neon externo.**

---

## 5. Tipografia

### App (Flutter)

Família única: **Inter** (fontes locais em `assets/google_fonts/`, pesos 400, 500, 600 e 700). Números usam dígitos tabulares.

| Papel | Tamanho / peso / entrelinha | Uso |
|---|---|---|
| Número de tela | 40 / 700 | Teclado numérico, contador, anel |
| Destaque | 32 / 700 / 1.1 · tracking −0.2 | Número herói, total do mês |
| Título da página | 22 / 700 / 1.2 · tracking −0.2 | Topo da tela, saudação |
| Título de seção | 17 / 600 / 1.25 · tracking −0.2 | Blocos, folhas, barra do topo |
| Título de linha | 15 / 600 / 1.3 | Título de card e de item de lista |
| Corpo | 15 / 400 / 1.45 | Texto corrido |
| Secundário | 13 / 400 / 1.4 | Apoio, metadados |
| Rótulo | 12 / 600 / 1.2 | Chips, eyebrows, rótulos |
| Mínimo | 11 / 500 / 1.2 | Legendas; único lugar do peso 500 |

Regras: só esses tamanhos existem (contrato de tipografia em `FocuxHubTypography`); nenhuma tela usa `fontSize` literal; três pesos (400, 600, 700) mais o 500 no mínimo.

### Site

| Papel | Fonte |
|---|---|
| Interface e títulos | **Plus Jakarta Sans** |
| Dados, números técnicos | **JetBrains Mono** |

Títulos com peso 600, `tracking-tight` e `text-wrap: balance`. Texto secundário com opacidade mínima de 70% e tamanho mínimo de 11 px.

### Materiais avulsos (apresentações, posts, PDFs)

Use **Inter** quando o material conversar com o app (prints, tutoriais) e **Plus Jakarta Sans** quando conversar com o site (marketing). Não misture as duas no mesmo título.

---

## 6. Iconografia

- Biblioteca: **Phosphor** (MIT), via `FxIcons`. Nenhuma tela usa `Icons.*` do Material direto.
- **Light**: padrão de toda a interface.
- **Fill**: estado ativo (concluído, favorito, fixado, tocando).
- **Regular**: ícones de 16 pt ou menos, para o traço não sumir.
- Ícones são nomeados pelo **significado** (`adicionarPessoa`, `alerta`), não pelo desenho.
- **Nada de emoji como ícone de interface.**
- Cor do ícone segue o texto ao lado; petróleo só em ícone de ação ou de estado selecionado.

---

## 7. Forma: espaçamento, raios, sombras e superfícies

### Espaçamento (grade de 8 pt)

| Token | 4 | 8 | 12 | 16 | 24 | 32 | 48 | 64 | 80 |
|---|---|---|---|---|---|---|---|---|---|
| Nome | s1 | s2 | s3 | s4 | s5 | s6 | s7 | s8 | s9 |

Site: container com gutter de 20 px (mobile), 32 px (≥ 640 px), 48 px (≥ 1024 px) e largura máxima de 1360 px.

### Raios

| Elemento | Raio |
|---|---|
| Inputs | 8 px |
| Cards | 12 px |
| Folhas, cards grandes | 16–24 px |
| Botões e chips | pílula (999 px) |

### Botões

- Altura mínima de **48 px**.
- Forma de pílula, sem elevação.
- Primário: fundo `#0B4F5C`, texto branco, hover `#083D47`.
- Um único botão primário por tela.

### Sombras

- **Card claro:** `0 2px 8px rgba(0,0,0,.07)`.
- **Card escuro:** elevação por superfície (`#121820` → `#1A2330`), não por sombra preta.
- **Profundidade colorida** (destaques raros): sombra na cor do elemento, 40% e 16% de opacidade.

### Liquid Glass

Superfícies de vidro no escuro: preenchimento branco 9%, borda branca 14%, blur de 16 / 22 / 28. Use em barras e cartões flutuantes sobre mesh, não em listas inteiras.

---

## 8. Movimento

| Item | Valor |
|---|---|
| Duração de UI | 150–300 ms |
| Curva padrão | ease-out (`Curves.easeOutCubic` no app) |
| Curva premium (site) | `cubic-bezier(0.23, 1, 0.32, 1)` |
| Transição de página (app) | Fade + deslize vertical de 2,8% |
| Rolagem do site | GSAP + ScrollTrigger; Lenis só no desktop |

Regras:

- Animar só `transform` e `opacity`.
- Respeitar `prefers-reduced-motion` (site) e a redução de movimento do sistema (app).
- Sem animação decorativa infinita. O movimento explica uma mudança; não enfeita.

---

## 9. Imagens e capturas de tela

- A principal imagem da marca é **o próprio app**: capturas reais do build publicado (Hoje, Alunos, aderência, evolução, biblioteca, ficha, financeiro, marca, página de vendas, app do aluno).
- Mostre só o que o build publicado entrega. Recurso escondido ou "em breve" não aparece.
- Capturas sem dados pessoais reais: use alunos fictícios plausíveis.
- Fotos de pessoas: treino real, luz natural ou de academia, sem pose de banco de imagem, sem filtros saturados. Recomendação: personal e aluno juntos, com o celular como ferramenta, não como protagonista.
- Mockups de aparelho: um modelo neutro, sem reflexo exagerado.
- Selos da App Store e do Google Play só com link real para a loja.

---

## 10. Voz e tom

### Princípios

1. **Concreto antes de bonito.** "Quem treinou, quem pagou e quem sumiu" em vez de "gestão completa".
2. **Dor → resultado.** Do WhatsApp e da planilha para uma tela só.
3. **Negócio, não só treino.** Retenção, PIX, tempo, marca e risco.
4. **Honesto.** Preço é de referência e a assinatura é pela loja; white-label é marca dentro do app; a IA sugere e o personal decide.
5. **Do lado do personal.** Falamos com "você". A IA e o app ajudam; nunca substituem o profissional.

### Tom por contexto

| Contexto | Tom | Exemplo |
|---|---|---|
| Site / marketing | Direto, confiante, sem exagero | "Cobrança sem constrangimento." |
| App — personal | Objetivo, operacional | "3 alunos pedem atenção hoje." |
| App — aluno | Simples, encorajador, sem infantilizar | "Treino de hoje: Inferiores A." |
| Erros | Diz o que houve e como resolver, sem pedir desculpas em excesso | "Não foi possível salvar. Verifique a conexão e tente de novo." |
| Cobrança | Neutro, respeitoso | "Mensalidade de novembro em aberto." |
| Suporte e legal | Claro, formal sem juridiquês desnecessário | — |

### Faça e não faça

| Faça | Não faça |
|---|---|
| "Cobre com PIX direto na sua chave." | "Revolucione sua gestão financeira!" |
| "Veja quem está em risco de sair." | "IA de última geração que destrói a concorrência." |
| "30 dias grátis no plano mensal." | "Teste grátis ilimitado!*" |
| "Sua marca dentro do app do aluno." | "Seu próprio app na App Store." |
| Frases curtas, voz ativa | Travessões, "não é X, é Y", trios forçados |

### Palavras proibidas ou evitadas

"sistema operacional" fora do slogan oficial, "destrói", "moderno", "escale", "revolucionário", "disruptivo", "o futuro do fitness", "game changer", "potencialize", depoimentos e números inventados.

### Regras de escrita

- **Só português do Brasil** em todo texto de produto.
- Valores em real: `R$ 59,90`. Datas: `18/11/2026` ou "18 de novembro".
- Sem caixa alta para ênfase; use peso ou cor.
- Sem emoji em interface e em títulos do site.
- Marketing passa pelo **Humanizer** (`focux-website/.cursor/skills/humanizer/`) antes de publicar.

---

## 11. Vocabulário do produto

| Termo | Significado | Grafia |
|---|---|---|
| Hoje | Tela inicial do personal com o que pede ação | Sempre com inicial maiúscula |
| Índice Focux | Indicador de saúde da operação na tela Hoje | — |
| IA Focux | A inteligência artificial do app | Nunca "o robô" ou "o ChatGPT" |
| Aluno | Cliente do personal | Não "cliente" nem "usuário" no app |
| Personal | O profissional | "personal" em texto corrido; "Personal" como perfil |
| Ficha / treino | Programação do aluno | — |
| Check-in | Registro de execução com carga e RPE | Com hífen |
| Aderência | % da ficha cumprida no período | — |
| Interessados | Leads e captação | Não "leads" na interface |
| Marca própria | White-label in-app (Enterprise) | Não "app próprio" |
| Indique e ganhe | Programa de indicação | — |

### Planos (referência; o preço oficial é o da loja)

| Plano | Mensal | Destaque |
|---|---|---|
| Free | R$ 0 | Até 3 alunos |
| Pro | R$ 59,90 | Até 50 alunos, PIX, IA Focux (200 usos/mês), 30 dias grátis no mensal |
| Enterprise | R$ 119,90 | Ilimitado, marca própria, página de vendas, IA Focux (600 usos/mês) |

Anual: equivale a 2 meses grátis. Fonte da verdade dos números: `OFERTA` em `focux-website/client/src/lib/data.ts`.

---

## 12. Marca do personal (white-label)

No plano Enterprise o personal aplica logo, paleta e nome dentro do Focux e pode ocultar a marca Focux para o aluno.

- A cor salva pelo personal **não é alterada**; só a cor aplicada é ajustada para contraste.
- Tons suaves, profundos e de acento são derivados da primária (`BrandPalette`).
- O card de marca escurece a cor até o texto branco passar em AA (4,5:1).
- A secundária só vira acento se tiver 3:1 com o fundo; senão cai para o acento da primária.
- Cores legadas ciano (`#13C2C2`, `#1EC8C8`, `#007D8A`, `#0097A7`) são remapeadas para o petróleo.
- Comunicação: dizer "marca própria dentro do app". Nunca prometer app separado nas lojas.

---

## 13. Acessibilidade

### Contrastes verificados (WCAG 2.1)

| Texto | Fundo | Razão | Resultado |
|---|---|---|---|
| Branco | `#0B4F5C` | 9,18 | AAA |
| `#0B4F5C` | `#F4F6F8` | 8,48 | AAA |
| `#0A6B7A` | `#FFFFFF` | 6,18 | AA |
| `#1A1A2E` | `#F4F6F8` | 15,75 | AAA |
| `#E8EDF2` | `#0B0E14` | 16,40 | AAA |
| `#9AA8B3` | `#0B0E14` | 7,93 | AAA |
| `#3D9AAD` | `#0B0E14` | 5,91 | AA |
| `#3D9AAD` | `#FFFFFF` | 3,27 | Só texto grande e ícones |
| `#6B7280` | `#F4F6F8` | 4,46 | Abaixo de AA; usar ≥ 14 px bold ou trocar por `#4B5563` |
| `#C73A3A` | `#FFFFFF` | 5,13 | AA |
| `#1B8C54` | `#FFFFFF` | 4,26 | Só texto grande e ícones |
| `#B5760A` | `#FFFFFF` | 3,78 | Só texto grande e ícones |
| `#0B4F5C` | `#0B0E14` | 2,10 | **Não usar** (petróleo some no escuro; use `#3D9AAD`) |

### Regras

- Texto ≥ 4,5:1; texto grande e ícones ≥ 3:1.
- Foco visível: contorno de 2 px em `#0B4F5C`, afastado 2 px.
- Alvos de toque de pelo menos 48 px.
- Labels em formulários (placeholder não é label).
- `lang="pt-BR"` e texto alternativo em imagens de conteúdo.
- Estado nunca só por cor: acompanhe com ícone ou texto.

---

## 14. Aplicações

| Peça | Fundo | Logo | Observação |
|---|---|---|---|
| Ícone do app | Branco | Símbolo, versão clara | Sem texto |
| Splash | `#0B0E14` | Versão escura | Centralizado |
| Site | `#F4F6F8` (hero e cartões invertidos em `#0B0E14`) | Conforme o fundo | Só tema claro |
| E-mail transacional | Branco | `email-logo.png` | Uma ação por e-mail |
| Redes sociais | Paper, cinematic ou petróleo profundo | Conforme o fundo | Captura real do app como imagem principal |
| Apresentação | `#0B0E14` (capa) e `#F4F6F8` (conteúdo) | Conforme o fundo | Petróleo só em destaques |
| Uniforme / impresso | Branco, preto ou grafite | Versão de contraste | Tamanho mínimo de 25 mm |

---

## 15. Dados institucionais

| Campo | Valor |
|---|---|
| Nome fantasia | Focux Personal |
| Razão social | MATHEUS OLIVEIRA DOS SANTOS DESENVOLVIMENTO DE SOFTWARE LTDA |
| CNPJ | 67.019.279/0001-26 |
| Cidade | Curitiba, PR |
| Site | https://focuxpersonal.com |
| E-mail | contato@focuxpersonal.com |
| Páginas obrigatórias | `/privacidade`, `/termos`, `/suporte`, `/empresa`, `/excluir-conta` |

---

## 16. Fontes da verdade e governança

| Assunto | Arquivo |
|---|---|
| Tokens do app | `focux-app/lib/core/theme/design_tokens.dart`, `tokens_strip.dart` |
| Tipografia do app | `focux-app/lib/core/theme/focux_hub_typography.dart` |
| Ícones | `focux-app/lib/core/theme/fx_icons.dart` |
| White-label | `focux-app/lib/core/theme/brand_palette.dart` |
| Logos | `focux-app/brand/` (cópia do Google Drive "Focux Personal") |
| Tokens do site | `focux-website/client/src/index.css` |
| Oferta e planos | `focux-website/client/src/lib/data.ts` |
| Copy do site | `focux-website/client/src/lib/landing.ts` + Humanizer |

Mudanças de cor, logo ou tipografia são **decisão de produto** dos sócios. Fluxo: alterar os tokens no código → atualizar este guia e o HTML → avisar no changelog.

---

## 17. Pendências encontradas na auditoria

1. ~~`MASTER.md` do site desatualizado~~ **Resolvido:** fonte e CTA corrigidos e apontando para este guia.
2. ~~`brand/styleguide.txt` incompleto~~ **Resolvido:** virou resumo técnico com ponteiro para este guia.
3. **Petróleo do logo (`#016B7E`) ≠ primário de UI (`#0B4F5C`).** É aceitável, mas precisa ser intencional. Não recolorir o logo nem usar `#016B7E` em interface.
4. **`#6B7280` sobre `#F4F6F8` dá 4,46:1**, logo abaixo de AA. Em texto pequeno, preferir `#4B5563`.
5. **Não há logo vetorial (SVG/PDF) no repositório**, só PNG 1254 px. Para impressão e materiais grandes, vale produzir o vetor a partir do original.
