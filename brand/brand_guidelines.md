# Focux Personal — Brand Guidelines

> Versão 1.4 · novembro de 2026 · documento interno e confidencial. Novidades: logo v2 e kit em `kit/` (1.1); logo no escuro `#0E93A8` e escala tipográfica do site (1.2); chão escuro petróleo `#0A1A1F` e regra de fundos sem brilhos (1.3); slogan oficial "Quem treinou, quem pagou e quem sumiu." (1.4).
> Versão visual: [`brand_guidelines.html`](brand_guidelines.html) (abre no navegador, sem dependências).

Este guia junta num lugar só o que hoje está espalhado pelo código do app (`lib/core/theme/`), pelo design system do app (`docs/DESIGN-SYSTEM.md`) e pelo site (`client/src/index.css`, `docs/DESIGN-SYSTEM.md` do `focux-website`). Quando o guia e o código discordarem, **o código em produção vence** e este arquivo deve ser corrigido.

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

### Slogan oficial

> **Quem treinou, quem pagou e quem sumiu.**

É a dor do personal dita do jeito dele: retenção, cobrança e frequência numa frase só. Pesquisa de 18/11/2026: nenhum concorrente usa essa frase, nem algo parecido. Os concorrentes falam de ferramenta ("tudo em um só lugar", "fácil, prático") ou de crescimento ("triplicar alunos"); a Focux fala de retenção e cobrança.

| Camada | Texto | Onde |
|---|---|---|
| **Slogan** | Quem treinou, quem pagou e quem sumiu. | Hero do site, bio do Instagram, anúncios, apresentações. No site, "quem sumiu" vai na cor de destaque |
| **Descritor** | App de gestão para personal trainer | Título do site, Google, texto de compartilhamento, logo abaixo do slogan |
| **Subtítulo da App Store** (máx. 30) | Gestão para personal trainer | Lojas de aplicativo |

Bio do Instagram de referência: *Quem treinou, quem pagou e quem sumiu.* / *App de gestão para personal trainer: alunos, treinos e cobrança com PIX.*

O slogan antigo, "Sistema operacional para personal trainer", está aposentado.

### Posicionamento

- **Categoria:** app de gestão para personal trainer.
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

> **Logo v2 (novembro de 2026).** Evolução do logo original: mesmo braço, mesma composição e mesma ideia, com desenho limpo, texto reconstruído e cor unificada com o app. Os arquivos estão em [`kit/`](kit/). O logo anterior saiu do repositório (fica no histórico do Git).

### Construção

O logo tem três partes:

1. **Símbolo:** um braço flexionado (bíceps) segurando um smartphone. É o treino e a gestão do personal na mão, pelo app. Curvas redesenhadas a partir do original, com metade dos segmentos.
2. **Wordmark "FOCUX":** letras geométricas desenhadas sob medida, não digitadas em fonte. Regras de construção, com altura das maiúsculas = 100:
   - traço de 20 em todas as letras, e de 21,4 nas diagonais do X (diagonais parecem mais finas e recebem compensação óptica);
   - canto externo com raio de 30 e canto interno com raio de 12;
   - X com diagonais a 45° exatos;
   - espaços entre letras ajustados no olho: F→O 28 · O→C 35 · C→U 27 · U→X 30.
3. **Assinatura "PERSONAL":** Inter Bold, a mesma fonte do app, convertida em formas, com espaçamento largo e um fio de cada lado. A Inter é livre (licença OFL), então não há restrição de licença.

### Arquivos (`brand/kit/`)

| Versão | Arquivo | Usar em |
|---|---|---|
| Empilhado, fundo claro | `svg/focux-logo-empilhado.svg` | Versão principal: capas, apresentações, impressos |
| Empilhado, fundo escuro | `svg/focux-logo-empilhado-escuro.svg` | Chão escuro `#0A1A1F` (em tamanho pequeno, evite a superfície `#10262C`: o petróleo do logo cai para 4,3:1) |
| Horizontal, fundo claro | `svg/focux-logo-horizontal.svg` | Cabeçalho do site, e-mail, rodapé de PDF, barras |
| Horizontal, fundo escuro | `svg/focux-logo-horizontal-escuro.svg` | Idem, sobre fundo escuro |
| Símbolo | `svg/focux-simbolo.svg` · `svg/focux-simbolo-escuro.svg` | Avatar de rede social, selo, onde o texto não cabe |
| Símbolo pequeno | `svg/focux-simbolo-pequeno.svg` · `svg/focux-simbolo-pequeno-escuro.svg` | **Só até 48 px**: favicon, listas, ícones pequenos |
| Ícone do app | `svg/focux-icone-app.svg` | Braço branco sobre `#0B4F5C`, quadrado cheio (a loja aplica o arredondamento) |
| Uma cor | `svg/uma-cor/*` (preto e branco) | Carimbo, bordado, laser, documentos P&B, sobre foto |
| Notificação Android | `svg/uma-cor/focux-icone-notificacao.svg` | Silhueta branca exigida pelo Android |
| PNGs prontos | `png/ios/`, `png/android/`, `png/android-notificacao/`, `png/favicon/` (com `favicon.ico`), `png/logos/` | Lojas, launcher, site |

O **símbolo pequeno** é o mesmo braço com traço mais grosso, celular preenchido e dedos unidos, para não virar borrão em tamanho pequeno. Acima de 48 px use sempre o símbolo normal.

### Cores do logo

| Parte | Fundo claro | Fundo escuro |
|---|---|---|
| Símbolo, "X", "PERSONAL" e fios | `#0B4F5C` (primário da marca) | `#0E93A8` (petróleo para fundo escuro) |
| "FOCU" | `#1A1A2E` (ink) | `#E8EDF2` (branco suave) |

Logo e app usam **o mesmo petróleo**. No fundo escuro, o mesmo código `#0B4F5C` some (contraste 2,1:1) e parece um azul apagado. Por isso a parte petróleo vira `#0E93A8`: o mesmo tom (matiz 188°), mais saturado e mais claro, com 5,3:1. Consistência de marca é a pessoa perceber a mesma cor, não usar o mesmo código. O "FOCU" usa o branco suave `#E8EDF2`, porque o branco puro briga com o petróleo e o deixa com cara de desbotado.

### Área de proteção

Mantenha ao redor do logo um espaço livre igual à **altura do "X" do wordmark** em todos os lados. Nada de texto, borda ou outro elemento dentro dessa área.

### Tamanho mínimo

| Versão | Digital | Impresso |
|---|---|---|
| Empilhado | 96 px de largura | 25 mm |
| Horizontal | 140 px de largura | 35 mm |
| Símbolo | 48 px de altura (abaixo disso, use o pequeno) | 12 mm |
| Símbolo pequeno | 16 px | 5 mm |

Abaixo do mínimo, "PERSONAL" deixa de ser legível: use o horizontal ou só o símbolo.

### Usos incorretos

- Esticar, achatar ou girar o logo.
- Trocar as cores, ou deixar o "X" da mesma cor do "FOCU".
- Usar a versão clara sobre fundo escuro (o "FOCU" some), ou o contrário.
- Usar `#0B4F5C` no logo sobre fundo escuro: use a versão escura (`#0E93A8`).
- Usar o símbolo pequeno em tamanho grande, ou o símbolo normal abaixo de 48 px.
- Colocar o logo sobre foto movimentada sem uma camada sólida por trás.
- Adicionar sombra, contorno, brilho, gradiente ou efeito 3D.
- Separar o símbolo do wordmark e reposicionar livremente.
- Digitar "FOCUX" em qualquer fonte. O wordmark só existe como desenho.
- Usar o logo anterior (petróleo `#016B7E`) ou o antigo ciano (`#13C2C2` / `#1EC8C8`) em material novo.

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
| Deep | `#051F26` | `brandDeep` | `--fx-deep` / `deep` | Tom mais profundo: ícones e avatares sobre claro |
| Petróleo escuro (logo) | `#0E93A8` | — | — | **Só o logo** sobre fundo escuro. Na interface, o acento no escuro continua `#3D9AAD` |

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

### 4.3 Tema escuro: chão petróleo

O escuro da marca é um **petróleo bem escuro e sólido**, não um quase preto com brilhos. A marca está na cor do chão, igual na tela toda.

| Token | Hex | Site (`index.css`) | Uso |
|---|---|---|---|
| Chão escuro | `#0A1A1F` | `--fx-cinematic` / `bg-night` | Fundo escuro: hero, cartões invertidos, rodapé, páginas legais, splash |
| Superfície | `#10262C` | `--fx-cinematic-surface` | Cartões sobre o chão |
| Borda | `#1B3A42` | — | Bordas e divisores no escuro |
| Text | `#E8EDF2` | — | Texto principal |
| Text mute | `#9AA8B3` | — | Texto secundário |

Elevação no escuro: cada nível é **um tom fixo** mais claro (chão → superfície), nunca uma mancha de luz. Assim o mesmo cartão tem a mesma cor em qualquer ponto da tela.

> **App:** usa o chão petróleo desde 20/11/2026 (`EagleTokens.darkBg/darkCard/darkCardHi/darkLine` e `TokensStrip.cinematic*`): `#0A1A1F`, `#10262C`, superfície alta `#16323A` e borda `#1B3A42`, sem brilhos.

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
| ~70% | Neutros (paper/card no claro, chão/superfície petróleo no escuro) |
| ~20% | Ink / texto |
| ~10% | Azul petróleo (ações, seleção, um destaque por tela) |

O petróleo funciona por escassez. Uma tela com tudo em petróleo perde a hierarquia.

### 4.6 Fundos, gradientes e luz

Regra: **fundo sólido**. Atmosfera, quando existir, é **uma única luz fixa** com função, nunca manchas sobrepostas.

| Pode | Não pode |
|---|---|
| Chão sólido `#0A1A1F` (escuro) ou paper `#F4F6F8` (claro) | Várias manchas de brilho translúcidas sobrepostas ("mesh") |
| **Uma** luz fixa por seção, ligada ao conteúdo (hero do site: `#3D9AAD` a 20% atrás dos celulares) | Degradê animado sem parar, halo pulsando, anéis ou ícones em órbita |
| Degradê linear suave entre dois tons do chão (cartões invertidos: `#10262C → #0A1A1F`) | Brilho, neon ou borda luminosa como decoração |
| Card de marca: a primária sólida, variando só a luminosidade (no máximo 6%) | Camada preta por cima para "consertar" o contraste de um fundo carregado |

Por quê: várias camadas translúcidas sobre o escuro viram uma névoa esverdeada e suja, a elevação dos cartões fica inconsistente e o visual cai no padrão genérico "quase preto + acento neon + bordas brilhando". Diagnóstico completo na auditoria de 18/11/2026 (skill impeccable).

> **App:** fundo sólido desde 20/11/2026 (`FxChao`): chão `#0A1A1F` no escuro e paper `#F4F6F8` no claro, sem brilhos.

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

Plus Jakarta Sans na interface e nos títulos, e JetBrains Mono em dados. Os títulos são fluidos (`clamp()`): crescem com a largura da tela entre o mínimo e o máximo.

| Papel | Tamanho / peso / entrelinha / tracking | Classe | Exemplo |
|---|---|---|---|
| Display (hero) | 51–70 px / 600 / 1.02 / −0.04em | `clamp(3.2rem, 5.5vw, 4.4rem)` | Quem treinou, quem pagou e quem sumiu. |
| Título de seção | 30–51 px / 600 / 1.08 / −0.035em | `clamp(1.9rem, 4.5vw, 3.2rem)` | Cobrança sem constrangimento. |
| Título de bloco | 26–39 px / 600 / 1.05 / −0.045em | `clamp(1.65rem, 2.8vw, 2.45rem)` | O aluno sabe o que fazer hoje. |
| Título de card | 20 px / 600 / 1.25 | `text-xl` | Execução com vídeo no bolso. |
| Corpo destaque | 18 px / 400 / 1.55 | `text-lg` | Quem treinou, quem pagou e quem sumiu… |
| Corpo | 15–16 px / 400 / 1.6 | `text-base` / `text-[15px]` | O aluno paga por QR ou copia e cola. |
| Secundário | 13–14 px / 400 / 1.5 | `text-sm` / `text-[13px]` | Cobrado pela App Store ou Google Play |
| Rótulo | 12 px / 600 / +0.08em, caixa alta | `text-xs uppercase` | PLANO MAIS ESCOLHIDO |
| Mínimo | 11 px / 500, opacidade ≥ 70% | `text-[11px]` | Preço de referência |
| Dado (mono) | 13 px / 500, tabular | `font-mono` | R$ 59,90 · 30 dias · 92% |

Para ver cada tamanho renderizado com a frase de exemplo, abra a versão HTML do guia.

Títulos com peso 600, `tracking-tight` e `text-wrap: balance`. Texto secundário com opacidade mínima de 70% e tamanho mínimo de 11 px.

### Logo

O wordmark "FOCUX" é desenho próprio (ver seção 3) e "PERSONAL" usa Inter Bold. Nunca recrie o logo digitando texto.

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
- **Card escuro:** elevação por superfície (`#10262C` → `#16323A`), não por sombra preta.
- **Profundidade colorida** (destaques raros): sombra na cor do elemento, 40% e 16% de opacidade.

### Vidro (blur)

Só onde tem função: uma barra que flutua sobre conteúdo que rola (barra de navegação, cabeçalho fixo), para manter o contexto visível por baixo. Preenchimento branco 9%, borda branca 14%, blur de 16 a 28. **Nunca como decoração** de cartões ou listas.

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

"sistema operacional" (slogan antigo, aposentado), "tudo em um só lugar", "destrói", "moderno", "escale", "revolucionário", "disruptivo", "o futuro do fitness", "game changer", "potencialize", depoimentos e números inventados.

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
| Hoje | Tela inicial do personal com o que pede ação | Sempre com inicial maiúscula. Nunca "Comando" ou "Centro de Comando": esse nome não existe no app |
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
| `#E8EDF2` | `#0A1A1F` (chão) | 15,10 | AAA |
| `#E8EDF2` | `#10262C` (superfície) | 13,35 | AAA |
| `#9AA8B3` | `#0A1A1F` | 7,31 | AAA |
| `#9AA8B3` | `#10262C` | 6,46 | AA |
| `#3D9AAD` | `#0A1A1F` | 5,44 | AA |
| `#3D9AAD` | `#10262C` | 4,81 | AA |
| `#0E93A8` (logo no escuro) | `#0A1A1F` | 4,88 | AA |
| `#0E93A8` (logo no escuro) | `#10262C` | 4,31 | Só texto grande e ícones |
| `#3D9AAD` | `#FFFFFF` | 3,27 | Só texto grande e ícones |
| `#6B7280` | `#F4F6F8` | 4,46 | Abaixo de AA; usar ≥ 14 px bold ou trocar por `#4B5563` |
| `#C73A3A` | `#FFFFFF` | 5,13 | AA |
| `#1B8C54` | `#FFFFFF` | 4,26 | Só texto grande e ícones |
| `#B5760A` | `#FFFFFF` | 3,78 | Só texto grande e ícones |
| `#0B4F5C` | `#0A1A1F` | 1,94 | **Não usar** (petróleo some no escuro: na UI use `#3D9AAD`, no logo `#0E93A8`) |

### Regras

- Texto ≥ 4,5:1; texto grande e ícones ≥ 3:1.
- Foco visível: contorno de 2 px em `#0B4F5C`, afastado 2 px.
- Alvos de toque de pelo menos 48 px.
- Labels em formulários (placeholder não é label).
- `lang="pt-BR"` e texto alternativo em imagens de conteúdo.
- Estado nunca só por cor: acompanhe com ícone ou texto.

---

## 14. Aplicações

| Peça | Fundo | Arquivo | Observação |
|---|---|---|---|
| Ícone do app (iOS/Android) | `#0B4F5C` | `png/ios/`, `png/android/` | Braço branco; sem texto |
| Notificação Android | Transparente | `png/android-notificacao/` | Silhueta branca |
| Splash | `#0A1A1F` | `svg/focux-simbolo-escuro.svg` ou empilhado escuro | Centralizado, fundo sólido |
| Site: cabeçalho | `#F4F6F8` | `svg/focux-logo-horizontal.svg` | Hero e cartões invertidos usam a versão escura |
| Favicon | — | `png/favicon/favicon.ico` + PNGs | Símbolo pequeno |
| E-mail transacional | Branco | `png/logos/logo-horizontal-1600.png` | Uma ação por e-mail |
| Redes sociais (avatar) | `#0B4F5C` | Ícone do app ou símbolo branco | Funciona em recorte redondo |
| Apresentação | `#0A1A1F` capa · `#F4F6F8` conteúdo | Empilhado escuro / claro | Petróleo só em destaques; fundo sólido |
| Uniforme / bordado / impresso | Branco, preto ou grafite | `svg/uma-cor/` | Mínimo de 25 mm (empilhado) |

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
| Logos e ícones | `focux-app/brand/kit/` (logo v2) |
| Tokens do site | `focux-website/client/src/index.css` |
| Oferta e planos | `focux-website/client/src/lib/data.ts` |
| Copy do site | `focux-website/client/src/lib/landing.ts` + Humanizer |

Mudanças de cor, logo ou tipografia são **decisão de produto** dos sócios. Fluxo: alterar os tokens no código → atualizar este guia e o HTML → avisar no changelog.

---

## 17. Pendências encontradas na auditoria

1. ~~Regras de design do site desatualizadas~~ **Resolvido:** fonte e CTA corrigidos; viraram `docs/DESIGN-SYSTEM.md` do site e apontam para este guia.
2. ~~`brand/styleguide.txt` incompleto~~ **Resolvido:** o resumo saiu do repositório em 19/11/2026; este guia é a única referência.
3. ~~Petróleo do logo (`#016B7E`) diferente do primário de UI (`#0B4F5C`)~~ **Resolvido no logo v2:** um petróleo só, `#0B4F5C`.
4. **`#6B7280` sobre `#F4F6F8` dá 4,46:1**, logo abaixo de AA. Em texto pequeno, prefira `#4B5563`.
5. ~~Sem logo vetorial~~ **Resolvido no logo v2:** kit completo em SVG e PNG em `kit/`.
6. ~~Trocar os arquivos em uso pelo logo v2~~ **Resolvido em 20/11/2026** no app (`assets/images/`, ícones nativos, notificação, splash, web) e no site (`client/public/`, favicon, e-mail, og:image). Falta trocar nas redes sociais e nos diretórios externos.
7. **Busca de marca no INPI** e busca reversa de imagem antes do lançamento.
8. ~~Fundo escuro do site com manchas de brilho e efeitos animados~~ **Resolvido em 18/11/2026:** chão petróleo `#0A1A1F`, uma luz fixa no hero, sem pulso, órbitas ou degradê animado (site e páginas legais).
9. ~~Migrar o fundo escuro do app~~ **Resolvido em 20/11/2026:** chão petróleo nos tokens e fundo escuro sem brilhos. Fundo claro em paper `#F4F6F8` sólido no mesmo dia.
