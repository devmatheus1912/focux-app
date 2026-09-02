# Focux Personal — Referência oficial de design e engenharia

**Padrão de excelência do aplicativo (visual, UX, arquitetura, segurança, dados, ops).**
**Versão:** 2.0 · **Data:** 2026-09-02 · **Plataforma de referência:** iOS (HIG) com paridade Android.

> **Este arquivo é a única referência canônica.** Ele **substitui e aposenta**:
> - `PERFIL_DESIGN_REFERENCE.md` (v1 — escopo `/perfil`, fold inset)
> - `FOCUX_80_PILARES.md` (v1 — constituição dos 80 pilares)
>
> Todo o conteúdo normativo dos dois foi absorvido aqui. Não consultar os arquivos antigos: onde houver divergência, **este documento vence**.

---

## Índice

**Parte 0 — Como usar**
- [0.1 Regra de ouro](#01-regra-de-ouro)
- [0.2 O que mudou da v1 para a v2](#02-o-que-mudou-da-v1-para-a-v2)
- [0.3 Ordem de precedência](#03-ordem-de-precedência)
- [0.4 Migração: pendências ao aposentar os arquivos v1](#04-migração-pendências-ao-aposentar-os-arquivos-v1)

**Parte I — A pele (invariante em todo o app)**
- [1. Princípio raiz: pele constante, anatomia variável](#1-princípio-raiz-pele-constante-anatomia-variável)
- [2. Assinatura visual Focux](#2-assinatura-visual-focux)
- [3. Contrato de camadas: o que copiar e o que nunca copiar](#3-contrato-de-camadas-o-que-copiar-e-o-que-nunca-copiar)
- [4. Tokens canônicos](#4-tokens-canônicos)
- [5. Tipografia: papéis fixos](#5-tipografia-papéis-fixos)
- [6. Cor, contraste e semântica](#6-cor-contraste-e-semântica)
- [7. Motion, haptics e entrada](#7-motion-haptics-e-entrada)
- [8. Locale: aplicativo Brasil-first](#8-locale-aplicativo-brasil-first)

**Parte II — A anatomia (varia por função)**
- [9. Taxonomia de superfícies](#9-taxonomia-de-superfícies)
  - [S1 Hub operacional](#s1--hub-operacional) · [S2 Hub de ajustes](#s2--hub-de-ajustes--conta) · [S3 Detalhe de entidade](#s3--detalhe-de-entidade) · [S4 Coleção](#s4--coleção--lista) · [S5 Formulário de página](#s5--formulário-de-página) · [S6 Conversão](#s6--conversão-autenticação-plano-pagamento) · [S7 Sheet](#s7--sheet-overlay-modal) · [S8 Execução](#s8--execução--foco-total) · [S9 Wizard](#s9--wizard--onboarding)
- [10. Componente por intenção (matriz normativa)](#10-componente-por-intenção-matriz-normativa)
- [11. Orçamento de destaque](#11-orçamento-de-destaque)
- [12. Densidade e revelação progressiva](#12-densidade-e-revelação-progressiva)
- [13. Estados obrigatórios](#13-estados-obrigatórios)
- [14. Navegação, sheets, teclado e layout estável](#14-navegação-sheets-teclado-e-layout-estável)
- [15. Acessibilidade e ergonomia](#15-acessibilidade-e-ergonomia)

**Parte III — Regras que não podem ser esquecidas**
- [16. Rota, job, SSOT e tipos](#16-rota-job-ssot-e-tipos)
- [17. IA, monetização e mutação](#17-ia-monetização-e-mutação)
- [18. Tenant, auth e cache](#18-tenant-auth-e-cache)
- [19. Superfície, erro e PII](#19-superfície-erro-e-pii)
- [20. Segurança, privacidade e hardening](#20-segurança-privacidade-e-hardening)
- [21. Desempenho](#21-desempenho)

**Parte IV — Backend**
- [22. Backend: proposta por tela e auditoria de legado](#22-backend-proposta-por-tela-e-auditoria-de-legado)
  - [22.5 Auditoria de legado (varredura por domínio)](#225-auditoria-de-legado-varredura-por-domínio-não-por-tela)
- [23. Contrato de dados por tipo de superfície](#23-contrato-de-dados-por-tipo-de-superfície)
- [24. Superfície Hoje: contrato vigente de referência](#24-superfície-hoje-contrato-vigente-de-referência)

**Parte V — Os 80 pilares**
- [25. Regra de evidência](#25-regra-de-evidência)
- [26. Tabelas dos 80 pilares](#26-tabelas-dos-80-pilares)
- [27. Pilares estruturais 81–92](#27-pilares-estruturais-8192)

**Parte VI — Execução**
- [28. Playbook de implementação em massa](#28-playbook-de-implementação-em-massa)
- [29. O que pode aplicar sozinho vs. o que só propor](#29-o-que-pode-aplicar-sozinho-vs-o-que-só-propor)
- [30. Limpeza de mortos](#30-limpeza-de-mortos)
- [31. Anti-padrões](#31-anti-padrões)
- [32. Gates verificáveis](#32-gates-verificáveis)
- [33. Scorecard e checklist de ship](#33-scorecard-e-checklist-de-ship)
- [34. Catálogo de componentes](#34-catálogo-de-componentes)
- [35. Padrões de detalhe](#35-padrões-de-detalhe)

**Apêndices**
- [A. Registro de auditoria: hub Perfil](#a-registro-de-auditoria-hub-perfil)
- [B. Mortos: não reintroduzir](#b-mortos-não-reintroduzir)

---

## 0.1 Regra de ouro

> **A pele é constante. A anatomia é função do job da tela.**

Duas telas do Focux devem ser reconhecíveis como do mesmo produto em 200 ms (pele) e distinguíveis como jobs diferentes em 1 s (anatomia). Se toda tela parece a mesma tela, a pele venceu a anatomia — e isso é defeito, não consistência.

Corolário operacional: **antes de editar qualquer tela, classifique-a** em um dos nove tipos da [taxonomia](#9-taxonomia-de-superfícies). Sem classificação declarada, não se abre PR.

Uma tela linda com regra, contrato ou tenant errados é pior do que não mexer.

---

## 0.2 O que mudou da v1 para a v2

A v1 (`PERFIL_DESIGN_REFERENCE.md`) era excelente para o que se propunha — o fold inset de `/perfil` — mas foi lida como especificação global. O resultado previsível: o padrão *inset-grouped* (lista de linhas com chevron) virou a estrutura de telas que não são ajustes, e o app passou a "parecer um perfil" em todo lugar. As correções normativas abaixo são o núcleo desta versão.

| # | Regra v1 | Problema | Regra v2 |
|---|---|---|---|
| 1 | "O Perfil define a **pele** do Personal. Telas futuras copiam **este** padrão." | "Padrão" foi lido como *estrutura*, não como *pele*. | Telas futuras copiam a **pele** (§1–§8). A **estrutura** vem da taxonomia (§9). *Inset-grouped* é a estrutura padrão **apenas de S2**. |
| 2 | Picker inset → "Navegação / ação \| `FxSettingsTile` (chevron)" | A palavra "ação" autorizou `Entrar`, `Salvar`, `Assinar` como linha com chevron. Viola HIG e os pilares 4 e 19. | **Chevron ⟺ push de rota.** Ação transacional é botão. Ver [regra do chevron](#regra-do-chevron-normativa). |
| 3 | Sticky: "Chip `Completar`/`Hoje`" · Não copiar: "CTA full-width do Planos" | A proibição de CTA full-width era escopada a S1/S2 e virou global — telas de login e formulário perderam o botão primário. | CTA full-width é **proibido** em S1/S2 e **obrigatório** em S5/S6/S9. Ver §11. |
| 4 | Layout: "Não copiar: Cards KPI, accordion, pills no hero" | Escopado a S2, aplicado em todo lugar — hubs e detalhes perderam métricas e agrupamento. | Cards KPI são **corretos** em S1/S3. Proibidos em S2. |
| 5 | Sem taxonomia de superfície | Login, wizard, execução de treino e formulário não tinham arquétipo — caíram no default inset. | §9 define nove arquétipos, cada um com esqueleto, componentes e proibições. |
| 6 | Sem orçamento de destaque | "Densidade comparável à Home" é subjetivo; virou muro de chips/badges. | §11 e §12 dão limites contáveis (1 P0, ≤2 P1, ≤3 sinais/linha, agregação a partir de 3 repetições). |
| 7 | Backend: "na dúvida, propor" | Correto, mas passivo — sem proposta, nada era proposto. | §22 torna a auditoria de backend **obrigatória e entregável** em toda tela tocada, com template e severidade. |

Nada foi relaxado: todas as regras de negócio, segurança, tenant, LGPD, cache e performance da v1 continuam vigentes, íntegras, em §16–§21.

---

## 0.3 Ordem de precedência

Em caso de conflito, decidir nesta ordem:

1. **Segurança, tenant, LGPD, auth, pagamento** (§20, pilares 52–68) — nunca cede a estética.
2. **Regra de negócio e contrato de dados** (§16–§18) — nunca cede a estética.
3. **Acessibilidade e alvo de toque** (§15, pilares 33/38) — nunca cede a densidade.
4. **Anatomia da superfície** (§9–§12) — vence a preferência pessoal e vence "como a outra tela faz".
5. **Pele** (§1–§8) — vence variação criativa local.
6. **Preferência estética** — último critério.

---

## 0.4 Migração: pendências ao aposentar os arquivos v1

Ao adotar este arquivo, os ponteiros para os documentos antigos ficam órfãos. **Tarefas de migração** (executar no primeiro lote da implementação em massa, em PR próprio de documentação):

| Onde | Referência atual | Ação |
|---|---|---|
| `lib/core/security/focux_security.dart` | `'../docs/PERFIL_DESIGN_REFERENCE.md'` em `coreSources` | Apontar para `../docs/FOCUX_DESIGN_REFERENCE.md` |
| `lib/core/theme/fx_settings_layout.dart` (dartdoc) | `D:/Focux Personal/docs/PERFIL_DESIGN_REFERENCE.md` | Idem, e ajustar o texto para "estrutura padrão de S2" |
| `test/core/design_system/security_pillar_contract_test.dart` | Asserção do nome do arquivo | Atualizar no mesmo commit |
| `test/core/security/platform_hardening_test.dart` | Idem | Atualizar no mesmo commit |
| Regra Cursor `focux-10-10` | Cita os dois arquivos | Substituída pelo skill `/ruflo` + rule `focux-design` (ambos apontam só para este) |
| `docs/` | `PERFIL_DESIGN_REFERENCE.md`, `FOCUX_80_PILARES.md` | Apagar após o commit acima (pilar 72 — não deixar "por precaução") |

Enquanto a atualização não acontecer, **não apagar os arquivos v1**: o gate `security_pillar_contract_test` referencia o nome e quebra o CI.

---

# Parte I — A pele (invariante em todo o app)

## 1. Princípio raiz: pele constante, anatomia variável

| Camada | Definição | Varia por tela? | Fonte |
|---|---|---|---|
| **Pele** | Cor, tipografia, raio, blur, glow, sombra, mesh, motion, ícone, microcopy, locale | **Não.** Idêntica em 100% do app | §2–§8 |
| **Anatomia** | Esqueleto de layout, componentes estruturais, tratamento da ação primária, densidade | **Sim.** Determinada pelo tipo de superfície | §9–§12 |
| **Conteúdo** | Dados, regras, contratos | Sim, por domínio | §16–§24 |

O erro da v1 foi tratar a anatomia de `/perfil` como parte da pele. Ela não é: é a anatomia correta de **um** dos nove tipos.

## 2. Assinatura visual Focux

Uma tela só é "Focux" se **todos** estes sete itens estiverem presentes. Este é o teste de marca — e ele não menciona lista, chevron ou grupo inset em nenhum ponto.

1. **Fundo mesh cinematográfico** — `CinematicMeshBackground` + `MeshScope` (via `FxShellScaffold(useMesh: true)` ou herdado do shell). Nunca fundo chapado; nunca preto puro estilo ChatGPT.
2. **Superfície glass** — `ShellChrome.of(context).panel(...)`, `FxGlassSurface`, `fxStripCardDecoration` ou `fxListCardDecoration`. Fill translúcido, borda 1px tingida na marca, luz interna no topo.
3. **Teal da marca como único acento** — `TokensStrip.primary` (`#13C2C2`) ou a cor do personal via `BrandPalette.softened(...)`. Zero `#007AFF`, zero poço colorido, zero paleta paralela.
4. **Profundidade com glow tingido** — `TokensStrip.coloredDepthGlow` / `interactiveGlow` / `elevation(level, dark:)`. Sombra neutra sozinha não é a marca.
5. **Geometria de raio** — 8 input · 12 card · 20 grupo/painel · 50 pill (botão). Nunca raio arbitrário.
6. **Entrada coreografada** — `FxPremiumEntrance` na tela, `FxStaggerItem` nos blocos, respeitando `TokensStrip.prefersReducedMotion`.
7. **Ícone outline + microcopy PT-BR curta** — `FxIcon` (22 em linha, 18 em botão de chrome), voz de ação, sem jargão interno.

Se os sete estão lá, a tela é Focux **mesmo sendo** um formulário, um timer em tela cheia ou um paywall.

## 3. Contrato de camadas: o que copiar e o que nunca copiar

| Camada | Fonte canônica | Copiar sempre | Nunca copiar |
|---|---|---|---|
| Identidade | §2 deste arquivo | Mesh, glass, teal da marca, `ShellChrome` | Tema preto ChatGPT, CTA branco invertido, hero invertido no Financeiro |
| Tipografia | `FocuxHubTypography` | `pageTitle` / `sectionTitle` / `cardTitle` / `bodyMuted` / `metric` / `kpi` | Escala Dynamic Type 17pt como família própria; `Inter 17` ad-hoc; `pageTitle` 22 solto |
| Cor | Marca do personal | Ícone leading `BrandPalette.softened`; texto `chrome.ink`; muted `chrome.mute`; destrutivo `EagleTokens.bad` | Poços coloridos, azul iOS `#007AFF`, gradiente decorativo sem função |
| Estrutura | **Taxonomia §9 — nunca outra tela** | O esqueleto do tipo da tela | O esqueleto de um tipo diferente (em especial: inset-grouped fora de S2) |
| Ação primária | §10 + §11 | 1 P0 no tratamento previsto pelo tipo | Chevron para transação; dois primários; nenhum primário |
| Sticky | §9 por tipo | S1/S2: chip overlay · S3: barra com botão · S5/S6/S9: footer full-width | Full-width em S1/S2; chip como submit de formulário |
| Locale | §8 | PT-BR na superfície, `Locale('pt')`, formatos BR | Traduzir `app_en`/`app_es`; ligar seletor de idioma |

## 4. Tokens canônicos

Zero número mágico solto na árvore de widgets (pilar 16). Se um valor não está aqui nem em `TokensStrip`/`FxSettingsLayout`/`DashboardLayout`, ele não entra no diff.

### 4.1 Espaço, raio, blur — `lib/core/theme/tokens_strip.dart`

| Papel | Token | Valor |
|---|---|---|
| Grid 8pt | `s1`…`s9` | 4 · 8 · 12 · 16 · 24 · 32 · 48 · 64 · 80 |
| Raio input / campo | `rInput` | 8 |
| Raio card | `rCard` | 12 |
| Raio grupo / painel | `FxSettingsLayout.groupRadius` | 20 |
| Raio botão pill | `rButton` | 50 |
| Blur | `blurLight` / `blurMedium` / `blurHeavy` | 16 · 22 · 28 |
| Camadas de elevação | `layerBase`…`layerModal` | 0 · 4 · 8 · 16 · 24 |
| Anel de foco | `focusRingWidth` | 2 |

### 4.2 Layout inset (S2, e grupos de campo em S5) — `lib/core/theme/fx_settings_layout.dart`

| Papel | Token | Valor |
|---|---|---|
| Inset da página | `pageInset` | `s4` (16) |
| Gap entre grupos | `groupGap` | `s5` (24) |
| Padding horizontal do grupo | `groupPadH` | `s4` (16) |
| Header → grupo | `headerToGroup` | `s2` (8) |
| Grupo → footer | `footerAfterGroup` | `s2` (8) |
| Altura mínima de linha | `rowMinHeight` | 52 |
| Ícone leading | `iconSize` | 22 |
| Slot de prefixo em campo/picker | `insetPrefixWidth` | 48 |
| Chevron | `chevronSize` | 17 |
| Divisor | `dividerThickness` | 0.5 |
| Avatar do hero | `avatarSize` | `s9` (80) |

### 4.3 Toque

| Papel | Token | Valor |
|---|---|---|
| Alvo mínimo | `DashboardLayout.touchTarget` / `FxHelpChrome.touchTarget` | 48 |
| Controle de execução (S8) | — | ≥ 64 |

## 5. Tipografia: papéis fixos

Fonte única: `FocuxHubTypography` (`lib/core/theme/focux_hub_typography.dart`), sobre `AppTypography` (Outfit / JetBrains Mono). Papel é definido por **função semântica**, não por tamanho desejado.

| Papel | API | Onde |
|---|---|---|
| Título de página | `pageTitle` | Título de S1/S3/S4 quando há hero textual |
| Título de app bar | `TokensStrip.h2` (via `FxShellAppBar`) | Toda app bar — não estilizar à mão |
| Título de seção / nome de entidade | `sectionTitle` | Header de S3, nome no hero de S2, título de bloco |
| Título de linha / card | `cardTitle` | Linha de S2, título de `FxSatelliteListTile`, título de card |
| Corpo | `body` | Texto de leitura |
| Corpo secundário | `bodyMuted` | Subtítulo, caption, footer de grupo, freshness |
| Eyebrow | `eyebrow` | Rótulo acima de bloco (uso parcimonioso) |
| Métrica | `metric` (+ `fontSize: TokensStrip.fontBodySm` quando em linha) | Score, percentual, valor em linha |
| KPI | `kpi` | Número dominante de card de métrica em S1/S3 |
| Chip | `chip` | Texto de `FxToggleChip` e chips de status |

Regras: **um** `pageTitle` por tela, no máximo. Número sempre com unidade ou contexto no mesmo bloco visual (pilar 40). Nunca `TextStyle` inline com `fontSize` literal.

## 6. Cor, contraste e semântica

| Uso | Fonte | Regra |
|---|---|---|
| Texto principal | `ShellChrome.of(context).ink` / `fxScreenInk(context)` | Nunca `Colors.black`/`white` diretos |
| Texto secundário | `chrome.mute` / `fxScreenMute(context)` | Contraste ≥ 4.5:1 (pilar 17) |
| Linha / divisor | `chrome.line` | 0.5 de espessura |
| Acento e ícone leading | `BrandPalette.softened(colorScheme.primary)` | Cor do personal (white-label, pilar 8) — nunca hardcoded |
| Destrutivo | `EagleTokens.bad` | Só em ação destrutiva real; sempre com confirmação |
| Sucesso / aviso / erro / info | `TokensStrip.badgeSuccess` / `badgeWarning` / `badgeError` / `badgeInfo` (+ `*Bg`) | Badge de status apenas; não pintar superfície inteira |
| Bloqueio de plano | `FxPlanLockBadge` / `FxPlanLockTrailing` | Ink a 55% de alpha + cadeado + tier |

Dark/light: toda cor passa por `ShellChrome` (pilar 18). Toda tela é verificada nos dois temas antes do ship. Zero cor literal fora de `tokens_strip.dart` / `brand_palette.dart` / `design_tokens.dart`.

## 7. Motion, haptics e entrada

| Situação | API | Regra |
|---|---|---|
| Entrada de tela | `FxPremiumEntrance` | Uma vez por tela, na raiz do body |
| Entrada de blocos | `FxStaggerItem` | Escalonado; nunca em item de `ListView.builder` longo |
| Transição de rota | `FxPremiumPageTransitionsBuilder` / `fxTransitionPage` | Não escrever transição custom por tela |
| Botão primário | `FxLiquidPrimaryButton` / `FxSpringButton` | Glow e spring já embutidos |
| Redução de movimento | `TokensStrip.prefersReducedMotion(context)` / `fxMotionDuration` | **Obrigatório**: zera animação de entrada (pilar 37) |
| Seleção em picker | `HapticFeedback.selectionClick()` | Já dentro de `FxInsetPickerOption` — não duplicar no caller |
| Ação destrutiva / confirmação | Haptic + `showFxConfirmSheet` | Haptic só em gesto deliberado, nunca em scroll ou first paint |
| Celebração | `FxCelebrationOverlay` / `FxRiveCelebration` / `FxConfettiBurst` | Só em conclusão real de outcome; ≤1 por fluxo |

## 8. Locale: aplicativo Brasil-first

Produto é **Brasil-first**. ADR: `focux-backend/docs/adr/002-brasil-first-sem-i18n.md`. O pilar 39 **não** pede `app_en`/`app_es` na UI.

1. Copy do app em **português do Brasil**.
2. Locale fixo `pt` (`main.dart`). Datas, telefone, PIX e `R$` no formato BR.
3. `app_en.arb` / `app_es.arb` existem no codegen Flutter — **standby**. Não migrar telas para EN/ES enquanto esta regra vigorar.
4. 10/10 do pilar 39 = PT-BR consistente na superfície + formatação por locale BR, **não** wiring multilíngue.

Microcopy (pilar 29): voz de ação, 2ª pessoa implícita, sem jargão interno ("fold", "provider", "BFF" nunca aparecem na UI). Rótulo de botão é verbo ("Cobrar", "Registrar treino", "Assinar"), não substantivo ("Cobrança").

---

# Parte II — A anatomia (varia por função)

## 9. Taxonomia de superfícies

Todo destino navegável do app é **exatamente um** destes nove tipos. A classificação é declarada no PR e determina esqueleto, componentes permitidos, tratamento da ação primária e proibições.

| Tipo | Job | Estrutura | Ação primária | Exemplos de rota |
|---|---|---|---|---|
| **S1** | Decidir e agir sobre um domínio hoje | Cards + foco + próximas ações | Chip in-card / banner | `/dashboard/personal`, `/ia`, hub financeiro |
| **S2** | Ler e alterar configuração da conta | **Inset-grouped** | Chip sticky de pendência (ou nenhuma) | `/perfil`, `/perfil/ferramentas`, configurações |
| **S3** | Entender e agir sobre 1 entidade | Header + métricas + seções | Barra sticky com botão | Aluno 360, treino, mensalidade, exercício |
| **S4** | Encontrar e escolher 1 item entre muitos | Busca + filtros + lista de cards | FAB / sticky "criar" | Lista de alunos, histórico, catálogo |
| **S5** | Capturar/alterar campos e confirmar | Grupos de campo + footer | **Botão full-width no footer** | Novo aluno, editar treino, dados bancários |
| **S6** | Converter: entrar, criar conta, pagar | Marca + poucos campos/planos + CTA | **Botão full-width com glow** | Login, cadastro, recuperar senha, planos, checkout |
| **S7** | Uma pergunta, uma escolha, um aviso | Handle + header + corpo curto | Confirmar (ou fechar) | Picker, confirm, form sheet, help |
| **S8** | Executar sem distração | Alvo único + controles grandes | Controle de execução | Treino em andamento, timer, captura ML Kit |
| **S9** | Uma decisão por etapa até um resultado | Progresso + 1 pergunta + Continuar | **Botão full-width "Continuar"** | First-run, criar treino em etapas |

---

### S1 — Hub operacional

**Job.** Em um olhar, saber o que fazer agora no domínio e conseguir fazer sem sair da tela.

**Esqueleto (topo → base).**
1. Header com saudação/contexto + freshness (`Olá, {primeiro}` · "atualizado há X").
2. **Um** banner de foco (`DashboardDayFocusBanner`) — a decisão do dia.
3. Bloco P0: próximas ações, no máximo 3 (`buildDashboardNextActions` → `CommandActionTile` / `CommandActionPanel`).
4. Blocos secundários, com header próprio e abertos por demanda (`DashboardSectionHeader` + `DashboardHomeSecondaryBlock`).
5. Rails horizontais com **top-N** (`FxHorizontalScrollPeek`, `DashboardAttentionRail`, `DashboardAgendaHojeStrip`) — score ≤5, aderência 3, agenda 3.
6. Sticky de prioridades como overlay (`DashboardPrioritiesOverlay`), que recolhe ao entrar na faixa de ferramentas.

**Componentes.** `FxShellScaffold(useMesh: true, constrainWidth: false)`, `FxShellAppBar`, `DashboardHomeHeader`, `DashboardDayFocusBanner`, `CommandActionTile` / `CommandActionPanel` / `CommandStatusTile`, `FxStripCard` / `fxStripCardDecoration(emphasize: true)` **só no P0**, `OperationalMetricTile`, `FxSparkline`, `DashboardSectionHeader`, `DashboardHomeSecondaryBlock`, `CustomScrollView` + slivers.

**Ação primária.** Chip in-card (`DashboardHomeActionChip`) ou a ação do banner de foco. Uma só, visível sem scroll.

**Proibido.** `FxSettingsGroup`/`FxSettingsTile` como estrutura da tela. Lista plana de tudo que existe. CTA full-width. Mais de um `emphasize: true` por viewport. Lista pesada no first paint (`alunos: null` no snapshot). Teaser de IA duplicado no header.

**Aceite.** Valor principal above the fold, sem scroll e sem segundo loading (pilar 13). Exatamente 1 P0 visualmente destacado (pilar 4). Um único request de hub (BFF).

---

### S2 — Hub de ajustes / conta

**Job.** Ler o estado da conta e alterar configurações. **Este é o único tipo cuja estrutura padrão é inset-grouped.**

**Esqueleto.**
1. Hero de identidade: avatar 80 + nome (`sectionTitle`) + score/percentual (`metric` 13).
2. Grupos inset (`FxSettingsGroup`) com header opcional, caption e footer explicativo.
3. Cada linha: `FxSettingsTile` — ícone outline 22 na cor da marca, label `cardTitle`, valor à direita `bodyMuted`, chevron 17 muted, divisor após o ícone.
4. Grupo destrutivo (Sair, Excluir conta) **isolado, por último**.
5. Chip sticky de prontidão (`PerfilStickyBar`) apenas quando houver pendência real.

**Componentes.** `FxSettingsLayout`, `FxSettingsGroup`, `FxSettingsGroupedList`, `FxSettingsTile`, `showFxInsetPickerSheet`, `FxPlanLockTrailing`, `FxHelpIconButton`.

**Ação primária.** Normalmente **nenhuma**: a tela é navegação e configuração. Quando existir pendência de cadastro, o chip sticky `Completar` é o P0.

**Proibido.** Cards KPI. Accordion. Pills no hero. Preview LIVE. CTA full-width. Linha que executa transação (pagar, enviar, iniciar) — isso é botão em S5/S6, não linha.

**Aceite.** Toda linha ou empilha uma rota, ou abre um picker, ou alterna um booleano. Nenhuma linha executa transação. Grupos ≤ 4; se passar de 7 destinos no mesmo nível, mover o excedente para rota-catálogo própria (foi assim que `/perfil/ferramentas` nasceu).

---

### S3 — Detalhe de entidade

**Job.** Entender uma entidade e agir sobre ela.

**Esqueleto.**
1. Header de identidade: avatar/ícone + nome (`sectionTitle`) + status (chip) + contexto (`bodyMuted`). `FxHubHeader`.
2. Faixa de 2 a 4 métricas (`OperationalMetricTile` / `kpi` + `FxSparkline`) — o "por que eu abri isso".
3. Seletor de seções: `AlunoSegmentedChoice` (2–4 seções) ou tabs.
4. Conteúdo da seção: cards (`FxStripCard`) e linhas de dado (`FxSatelliteListTile`).
5. **Barra sticky** na base com a ação primária (`FxLiquidPrimaryButton`), + até 2 secundárias em ícone/texto.

**Componentes.** `FxHubHeader`, `OperationalMetricTile`, `FxSparkline`, `AlunoSegmentedChoice`, `FxStripCard`, `FxSatellitePanel`, `FxSatelliteListTile`, `FxLiquidPrimaryButton` na sticky, `FxHelpIconButton` na app bar.

**Ação primária.** Um botão na barra sticky, na thumb zone. Exemplo: "Registrar treino", "Cobrar mensalidade", "Marcar como pago".

**Proibido.** Transformar as seções em pilha de `FxSettingsGroup` com chevrons (é o anti-padrão A1). Enterrar a ação primária no meio do scroll. Repetir a mesma métrica em card e em linha. Mais de 3 chips de status no header.

**Aceite.** Métricas above the fold. Ação primária alcançável sem scroll. Cada seção responde a uma pergunta nomeável.

---

### S4 — Coleção / lista

**Job.** Encontrar e escolher um item entre muitos.

**Esqueleto.**
1. App bar com título + contagem no subtítulo (`FxShellAppBar(subtitle: '32 alunos')`).
2. Busca, obrigatória a partir de ~10 itens (pilar 31).
3. Filtros: `FxToggleChip` em wrap, **≤5 visíveis**; excedente em sheet de ordenação/filtro.
4. `ListView.builder` / `SliverList` de `FxSatelliteListTile` ou card de domínio.
5. Paginação real no BE (scroll infinito ou "carregar mais").
6. Criar: FAB ou sticky.

**Componentes.** `FxAsyncBody` (loading/erro/vazio de graça), `FxSatelliteListTile`, `FxToggleChip`, `showFxInsetPickerSheet` para ordenação, `SkeletonList`.

**Ação primária.** Criar/adicionar — FAB ou botão sticky. **Nunca** uma das linhas da lista.

**Proibido.** `FxSettingsGroup` para dado dinâmico (grupo inset é para conjunto fixo e conhecido de configurações). Filtrar/ordenar o mundo no FE (pilar 65). Mais de 3 sinais visuais por linha (§12). Lista sem busca acima de ~10 itens. `ListView(children: [...])` para lista de tamanho desconhecido.

**Aceite.** Busca a um toque. Paginação no BE. Linha com no máximo: título, uma linha de contexto, um sinal de status, um valor.

---

### S5 — Formulário de página

**Job.** Capturar ou alterar um conjunto de campos e confirmar.

**Esqueleto.**
1. App bar com o nome da tarefa + "Cancelar" no leading (não seta, quando o fluxo é criação).
2. Grupos de **campos** em inset — aqui o grupo inset é correto: agrupa campos relacionados, com footer explicativo (`FxSettingsGroup` + `FxInputDeco` + `FxInsetPickerRow`).
3. Erros de validação **inline**, sob o campo.
4. **Footer sticky**: primário full-width (`FxLiquidPrimaryButton`) + secundário em texto.

**Componentes.** `FxInputDeco`, `FxInsetPickerRow`, `FxSettingsGroup` (container de campos), `AlunoSegmentedChoice` para 2–4 opções fixas, `FxToggleChip` para multi-seleção, `FxLiquidPrimaryButton`, `showFxConfirmSheet` para descarte com dados preenchidos.

**Ação primária.** **Botão full-width no footer sticky.** A proibição de CTA full-width vale para S1/S2 — aqui ela não se aplica.

**Proibido.** Submit como linha com chevron. Validação apenas no submit. `autofocus` sem `post-frame`. Teclado errado por tipo (usar `keyboardType` + máscara BR: telefone, CPF, CEP, moeda). Botão que não desabilita durante o envio.

**Aceite.** Validação inline; teclado e máscara corretos; botão com estado de envio; descarte com dados preenchidos pede confirmação; nenhum overflow com teclado aberto em phone e landscape.

---

### S6 — Conversão (autenticação, plano, pagamento)

**Job.** Converter. Cada elemento que não ajuda a converter é ruído.

**Esqueleto.**
1. Lockup de marca: `FocuxOfficialLogo` + `FocuxBrandTagline`.
2. O mínimo: 1–2 campos (login) **ou** 1–3 opções de plano em cards comparáveis.
3. **`FxLiquidPrimaryButton` full-width, com glow** — o elemento mais destacado da tela.
4. Alternativas em link de texto ("Criar conta", "Esqueci minha senha") — nunca competindo com o primário.
5. Nota legal / disclaimer discreto ao final.

**Componentes.** `FocuxOfficialLogo`, `FocuxBrandTagline`, `FxInputDeco`, `FxLiquidPrimaryButton`, `FxLiquidSecondaryButton`, `FxStripCard(emphasize: true)` para o plano recomendado, `UpgradePromptSheet`, `SubscriptionDeviceGuard`, `IaSafetyDisclaimer` quando houver IA no pitch.

**Ação primária.** Full-width, com glow, acima da dobra. **Correção normativa explícita:** `Entrar`, `Criar conta`, `Assinar`, `Continuar com…` são **botões**. Nunca `FxSettingsTile` com chevron.

**Proibido.** Estrutura inset-grouped. Mais de um CTA com peso de primário. Comparação de planos em lista de chevrons. Pedir dado que não é necessário para converter. Contornar `SubscriptionDeviceGuard` na UI.

**Aceite.** Conversão em ≤2 toques a partir do primeiro frame. Um único primário visível sem scroll. Erro de credencial via `friendlyError`, inline e específico, nunca stack.

---

### S7 — Sheet (overlay modal)

Quatro subtipos. Cada um tem um chrome fechado; não inventar um quinto.

| Subtipo | API | Corpo | Saída |
|---|---|---|---|
| **Picker** (1 valor) | `showFxInsetPickerSheet` | `FxSettingsGroup(edgeToEdgeRows: true)` + `FxInsetPickerOption` (check teal) | Fecha no tap |
| **Form** | `showFxFormSheet` | Campos curtos | Confirmar / Cancelar |
| **Confirm** | `showFxConfirmSheet` | Uma frase + consequência | Confirmar (destrutivo em `EagleTokens.bad`) + haptic |
| **Notice / Help** | `showFxNoticeSheet` / `showFxHelpSheet` | Texto + `FxHelpTipRow` | Um "Fechar" |

**Chrome comum.** `showFxHomeSheet` → `FxHomeSheetSurface` → `FxHomeSheetHandle` + `FxHomeSheetHeader` (título + subtítulo de contexto). `centerTitle: true` só aqui, e só em sheet curto sem lista densa.

**Regras rígidas (custaram crash de layout antes).**
- Nunca `Flexible`/`Expanded` dentro de `Column(mainAxisSize: min)` sem altura limitada.
- Lista no sheet: `expand: true` + `Expanded(ListView…)`.
- Altura capada pelas **constraints recebidas**, não por `%` da tela ignorando `viewInsets`.
- `autofocus` → focar **post-frame**.
- Fecha por back e por gesto; focus trap correto; nunca bloqueia sem saída (pilar 45).
- Máximo **um** nível de sheet aninhado.

---

### S8 — Execução / foco total

**Job.** Executar uma atividade em andamento sem nada competindo pela atenção.

**Esqueleto.**
1. Chrome mínimo: sem dock, sem badge, sem notificação in-screen.
2. **Um** alvo dominante: timer, contador, série atual — tipografia `kpi`, grande.
3. Contexto imediato abaixo, em uma linha (`bodyMuted`).
4. Controles primários grandes (≥64) na thumb zone: pausar / avançar / concluir.
5. "Sair" sempre visível, com confirmação (`showFxConfirmSheet`) se houver progresso não salvo.

**Proibido.** Listas. Chips de status. Badges. Chevron (não há navegação aqui). Mesh animada custosa em tela que roda por minutos — usar fundo estático. Celebração antes da conclusão real.

**Aceite.** Uma informação dominante. Controles alcançáveis com o polegar. Reduced motion respeitado. Tela permanece acesa quando o job exige. Interrupção (ligação, background) não perde progresso.

---

### S9 — Wizard / onboarding

**Job.** Uma decisão por etapa, até um resultado.

**Esqueleto.**
1. Indicador de progresso discreto (`Etapa 2 de 4`).
2. **Uma** pergunta por etapa, como `sectionTitle`.
3. Opções: `AlunoSegmentedChoice`, `FxToggleChip` ou cards de escolha — nunca lista longa de chevrons.
4. Primário full-width "Continuar"; "Voltar" em texto.
5. Estado salvo a cada etapa; sair e voltar retoma onde parou.

**Proibido.** Mais de uma decisão por etapa. Etapa sem como voltar. Perder o preenchido ao sair. First-run que mostra apenas "vazio" em vez de estado guiado (pilar 7).

---

## 10. Componente por intenção (matriz normativa)

Escolha do componente é **função da intenção**, nunca da aparência desejada nem do que a tela vizinha usa.

| Intenção | Componente | Affordance | Nunca |
|---|---|---|---|
| Navegar para outra tela (ver/editar mais) | `FxSettingsTile` (S2) · `FxSatelliteListTile` (S3/S4) | Chevron 17 muted | — |
| Escolher 1 valor entre poucos, em sheet | `showFxInsetPickerSheet` / `FxInsetPickerOption` | Check teal | Chevron |
| Escolher 1 valor, muitos itens | `FxInsetPickerOption.list` + busca acima | Check + busca | Chevron; lista sem busca |
| Escolher 1 entre 2–4 fixas, inline | `AlunoSegmentedChoice` / chips inline | Segmented | Linha com chevron |
| Escolher vários | `FxToggleChip` em wrap/grid | Chip selecionado | Picker de lista |
| Alternar booleano | `FxSettingsTile(accessory: Switch…)` | Switch | Chevron + sheet |
| **Ação primária transacional** (entrar, salvar, pagar, iniciar, confirmar, assinar) | `FxLiquidPrimaryButton` | Pill r50 + gradiente + glow | **`FxSettingsTile` / chevron** |
| Ação secundária | `FxLiquidSecondaryButton` | Pill outline | Segundo primário |
| Ação terciária | `TextButton` / link teal | Texto | Botão cheio |
| Ação in-card em hub | `DashboardHomeActionChip` / `CommandActionTile` | Chip | Full-width |
| Ação destrutiva | `showFxConfirmSheet` + linha/botão `danger` | Vermelho `EagleTokens.bad` + haptic | Swipe sem confirmação; destrutivo junto do resto |
| Abrir ajuda/contexto | `FxHelpIconButton` → `showFxHelpSheet` | Ícone `?` na app bar | Linha de ajuda no meio da lista |
| Exibir item de dado dinâmico | `FxSatelliteListTile` / `FxStripCard` | Card | `FxSettingsTile` |
| Exibir métrica | `OperationalMetricTile` / `kpi` / `FxSparkline` | Número + unidade | Linha com valor à direita |
| Comunicar bloqueio de plano | `FxPlanLockTrailing` + `UpgradePromptSheet` | Cadeado + tier | Esconder no FE; `if (plano == 'FREE')` |
| Informar estado do sistema | `FxConnectivityBanner` / freshness em `bodyMuted` | Banner/caption | Snackbar recorrente |
| Confirmar resultado de ação | `FeedbackHelper.showSuccess/Warn/Error` | Toast curto | Diálogo bloqueante |

### Regra do chevron (normativa)

> **Chevron ⟺ push de rota.** Se o tap não empilha uma tela, não existe chevron.

| Tap faz | Affordance |
|---|---|
| Empilha uma tela | Chevron |
| Abre sheet de escolha | Nenhuma (ou valor atual à direita) |
| Alterna booleano | Switch |
| Executa transação | **Botão** |
| Expande no lugar | Setinha de disclosure (baixo/cima), nunca chevron lateral |

Esta regra **revoga** a linha "Navegação / ação → `FxSettingsTile` (chevron)" da v1, que era a origem direta de "Entrar >" e afins.

---

## 11. Orçamento de destaque

Hierarquia não é subjetiva: é contável. Números aplicam-se **por viewport**, não por tela inteira.

| Limite | Valor |
|---|---|
| Ação primária (P0) | **Exatamente 1** por tela |
| Ações secundárias (P1) | ≤ 2 |
| Superfície com `emphasize: true` / `interactiveGlow` | ≤ 1 |
| Chips + badges simultâneos por card/linha | ≤ 3 |
| Chips + badges simultâneos na tela | ≤ 5 |
| Alertas/banners simultâneos | 1 (pilar 41) |
| Destinos de navegação no mesmo nível hierárquico | ≤ 7 — acima disso, agrupar em ≤4 grupos ou mover para catálogo |
| Métricas na faixa de KPI | 2 a 4 |
| `pageTitle` por tela | ≤ 1 |

**Três pesos, sem exceção.**

| Peso | Tratamento | Quantidade |
|---|---|---|
| **P0** | `FxLiquidPrimaryButton` (S5/S6/S9) · barra sticky (S3) · chip in-card destacado (S1) · controle grande (S8) | 1 |
| **P1** | `FxLiquidSecondaryButton`, chip tonal, ícone na app bar | ≤ 2 |
| **P2** | Linha, texto, link, chevron | resto |

**Tratamento por tipo de superfície** — a tabela que evita tanto "toda tela é perfil" quanto "toda tela tem botão gigante":

| Tipo | Tratamento do P0 | Full-width? |
|---|---|---|
| S1 | Chip in-card ou ação do banner de foco | **Não** |
| S2 | Chip sticky de pendência, ou nenhum P0 | **Não** |
| S3 | Botão em barra sticky | Opcional (largura da barra) |
| S4 | FAB ou botão sticky "criar" | Opcional |
| S5 | Botão em footer sticky | **Sim** |
| S6 | Botão com glow acima da dobra | **Sim** |
| S7 | Botão de confirmação do sheet | Sim (dentro do sheet) |
| S8 | Controle de execução ≥64 | Sim |
| S9 | "Continuar" no footer | **Sim** |

**Teste do squint.** Desfoque a tela mentalmente: deve sobrar **uma** mancha dominante. Se sobram cinco manchas iguais, a tela é uma lista plana e falha o pilar 4. Se não sobra nenhuma, falha o pilar 19.

---

## 12. Densidade e revelação progressiva

Este bloco é o antídoto direto do "muro de informação repetida".

1. **Regra da agregação (3).** Se **3 ou mais** itens consecutivos exibem o mesmo sinal (mesmo status, mesmo aviso, mesma pendência), remover o sinal das linhas e colocar **um** resumo no topo do bloco: `4 pendentes`, filtrável. Repetição idêntica não informa — só polui.
2. **Regra do 3 por linha.** Uma linha de lista carrega no máximo: título, uma linha de contexto, um sinal de status, um valor. O quarto sinal vai para o detalhe (S3).
3. **Top-N em hub.** Rails e blocos de S1 mostram top-N com "ver todos" para S4. Nunca lista completa em hub.
4. **Secundário não compete.** Bloco secundário de S1 fica abaixo do P0, com header próprio (`DashboardSectionHeader`) e sem tratamento de destaque. Quando o bloco for longo, mover o excedente para a rota S4 do domínio.
5. **Detalhe atrás de um toque.** Explicação de score, histórico e metadado vão para long-press / sheet de ajuda (`showFxHelpSheet`), não para a superfície.
6. **Vazio não é branco.** Todo vazio tem ícone + título + subtítulo + uma ação (pilar 25).
7. **Densidade por tipo:** S8 é a mais esparsa (1 informação dominante); S4 a mais densa (mas ≤3 sinais/linha); S1/S3 no meio; S2 é regular por construção (linhas de 52).

---

## 13. Estados obrigatórios

Toda tela que lê dados implementa **quatro** estados. Sem exceção, em todos os nove tipos.

| Estado | Componente | Regra |
|---|---|---|
| Carregando | `SkeletonList` / `SkeletonLoader` / `ShimmerListLoading` / `DashboardShimmerLoading` | Skeleton no formato do conteúdo real. **Nunca** tela branca; nunca spinner isolado sem contexto (pilar 26) |
| Vazio | `FxEmptyState` (+ `FxEmptyAction`) | Ícone + título + subtítulo + CTA. First-run é **guiado**, não "vazio" (pilar 7) |
| Erro | `FxErrorState` / `DashboardErrorState` + `friendlyError` | Mensagem humana + retry. **Proibido** `FeedbackHelper.showError(context, '$e')` |
| Freshness | `bodyMuted` / `FxHubFreshness` | "atualizado há X" sempre que houver cache (pilar 28) |

Atalho canônico: **`FxAsyncBody<T>`** entrega skeleton → erro com retry → vazio → dados a partir de um `AsyncValue`. Preferir a ele em vez de escrever `.when` na mão.

Offline: `FxConnectivityBanner`. Estado parcial não derruba a tela inteira — o bloco que falhou mostra erro local com retry.

---

## 14. Navegação, sheets, teclado e layout estável

- **Uma rota, um job nomeável** (pilar 2). Rota no shell correto — Personal vs. Aluno — na árvore do GoRouter (`buildPersonalShellRoute`, `buildAlunoRoutes`, `buildAuthRoutes`, `buildChromeShellRoute`).
- **Voltar é previsível.** `safePopOrGo`; sem loop, sem tela órfã (pilar 44). Back gesture Android e swipe iOS não conflitam com gesto customizado.
- **App bar.** `FxShellAppBar`, título e subtítulo **à esquerda** (`centerTitle: false`) — paridade `.toolbarRole(.editor)` do iOS 26. `centerTitle: true` só em sheet/modal curto, sem lista densa, título curto, sem subtítulo longo.
- **Largura.** `FxContentWidthLimiter` (via `FxShellScaffold(constrainWidth: true)`) em telas satélite; hubs full-bleed usam `false`.
- **Sheets, teclado e altura:** ver as regras rígidas em [S7](#s7--sheet-overlay-modal). Valem para qualquer overlay do app.
- **Layout estável:** evitar `LayoutBuilder` + `FittedBox` + `AnimatedContainer` no mesmo eixo. Preferir `FractionallySizedBox` ou constraints explícitas.
- **Crash de layout não se silencia no Crashlytics.** Overflow, `ParentData`, `S.of` e asserts são dívida de UI a corrigir na causa.
- **Deep link** funciona quando aplicável, e os parâmetros são documentados na tela (padrão Hoje: `?focus=on|off`, `?sheet=search|help|catalog`).

## 15. Acessibilidade e ergonomia

| Item | Regra |
|---|---|
| Semantics | Presente em todo controle interativo; `fxScreenA11yScope` na raiz da tela; hint em ação destrutiva |
| Alvo de toque | ≥ 48×48 (`DashboardLayout.touchTarget`); linha inset de 52 já cumpre; controle de S8 ≥ 64 |
| Contraste | ≥ 4.5:1 texto/fundo, via tokens de `ShellChrome` — verificado nos dois temas |
| Leitor de tela | Ordem de foco segue a ordem visual; ícone decorativo é `excludeSemantics` |
| Anúncio dinâmico | `fxAnnounce` / `fxAnnounceGlobal` ao mudar estado sem mudar tela |
| Reduced motion | `TokensStrip.prefersReducedMotion` zera entrada e stagger |
| Thumb zone | Ação frequente na metade inferior; nunca só no topo distante (pilar 36) |
| Responsivo | Sem overflow em phone, tablet e landscape; iPad em `UIRequiresFullScreen` (portrait-only aprovado) |
| Texto | Sem truncamento que perca informação essencial; `maxLines` + ellipsis só em rótulo secundário |

---

# Parte III — Regras que não podem ser esquecidas

Valem em **todo** o Personal, em qualquer tipo de superfície. Quebrar qualquer item é regressão de produto, não "detalhe de UI".

## 16. Rota, job, SSOT e tipos

1. **Uma rota = um job nomeável.** Hoje = operar o dia (cobrar / retomar / agenda). Perfil = conta, marca, operação da conta. Não misturar cadastro + financeiro + chat no mesmo fold.
2. **Hub tem BFF.** Home: um `GET /api/dashboard/home`, snapshot tipado. Não criar provider que refetcha o que o agregado já traz (`/home`, `/360`, `/perfil`).
3. **`dayFocus` é SSOT do BFF.** FE consome `home.dayFocus`. Sem fallback `DashboardDayFocus.resolve(` no runtime da Home (só em testes de paridade).
4. **`planoFeatures` do BFF** tem o mesmo shape de `GET /api/planos/me`. FE usa `seedFromHome` + `effectivePlanoFeatures(homeOverride:)`.
5. **Gates de plano** via `effectivePlanoFeatures` / capabilities / `verificarAcesso` no BE. **Proibido** `if (plano == 'FREE')` solto no widget. O BE é a fonte; a UI só comunica.
6. **Unread são dois domínios.** App: `notificacoesNaoLidas`. Chat: `pulse.mensagensNaoLidas`. Não unificar nem stubar inbox.
7. **Tipos na borda.** `fromJson` → model/DTO/record. Zero `Map<String, dynamic>` na UI.
8. **Lógica fora do `build()`.** Regras, priorização, formatação e estado em `utils/`, services ou funções puras.

## 17. IA, monetização e mutação

9. **IA:** opt-in, reversível, **nunca** autoaplicada no first paint. Entrada pela tab `/ia` — sem teaser duplicado no header da Home.
10. **Atalho bloqueado** → `UpgradePromptSheet`. Não esconder o gate só no FE.
11. **Mutação sensível** (pago, exclusão, dado financeiro): auditoria no BE; confirmação + haptic no FE; idempotência se a ação for repetível.
12. **LGPD:** exportação/exclusão só pelos endpoints `/api/lgpd/me`. A tela **não** inventa um segundo caminho. Não logar payload pessoal. Badge/unread sem preview de conteúdo. Contrato de delete: `senha` + `confirmacao: EXCLUIR`.
13. **Telemetria:** só **propor** evento novo; não inventar funil paralelo ao existente (`home_viewed`, `home_ttv`, etc.).

## 18. Tenant, auth e cache

14. **Tenant só de `TenantContext`.** Nunca `personalId` livre em query/body vindo do cliente.
15. **Rota atrás do auth** do app; BE com `@PreAuthorize` no papel correto.
16. **Cache Home:** client + server TTL **90s** (`dashboard-home`). Invalidar no **write path**, não refetch a cada tap. Writers (perfil, wallet, aluno, chat, mensalidade, white-label…) chamam `DashboardHomeCacheEvictor`.
17. **Prefetch** só em cold start de hub (login/splash → Home), não em toda tela interna.
18. **Snapshot de hub não traz lista pesada** (`alunos: null` no first paint). Top-N no BFF; paginar no BE, nunca filtrar o mundo no FE.
19. **Rate limit** nos endpoints que a tela dispara (hub GET 60/60s é o teto; IA, upload, busca, delete LGPD mais baixos). Não martelar `invalidate` em loop.
20. **Release exige `API_CERT_PINS`.** Sideload com `REQUIRE_API_CERT_PINS=false` é só teste — não shipar assim.

## 19. Superfície, erro e PII

21. **PII só do job.** Home não leva email/CPF no payload. Máscara quando o dado não precisa estar visível. WhatsApp no Perfil só se o cadastro estiver incompleto.
22. **Erros na UI:** `friendlyError` / `.when` / `FxAsyncBody`. **Proibido** `FeedbackHelper.showError(context, '$e')` — vaza stack.
23. **Estados obrigatórios:** loading (skeleton, nunca tela branca), vazio com CTA, erro + retry, freshness quando houver cache. Ver §13.
24. **Sheets e teclado:** regras rígidas de [S7](#s7--sheet-overlay-modal).
25. **Layout estável:** ver §14.
26. **Não silenciar crash de layout** no Crashlytics como se fosse correção.
27. **Clipboard PII** só via `copySensitiveToClipboard` (com timeout). Nunca `Clipboard.setData` solto.
28. **Pagamento:** `SubscriptionDeviceGuard` — jailbreak/root bloqueia assinatura. Não contornar na UI.
29. **IA na superfície:** manter `IaSafetyDisclaimer`.
30. **Token/role** só em `SecureStorage`. Nunca `SharedPreferences` para auth.

## 20. Segurança, privacidade e hardening

Fonte única no código: `lib/core/security/focux_security.dart` (`FocuxSecurity.coreSources`, `hubSecurityPatterns`, `forbiddenHubPatterns`, `automatedGates`). Ao elevar uma tela, **não reinventar**.
Gate de teste: `test/core/design_system/security_pillar_contract_test.dart`.

| Área | Onde | Regra ao subir telas |
|---|---|---|
| Token / sessão | `secure_storage.dart`, `app_router_redirect.dart`, `api_client.dart` | Token/role só em `SecureStorage`; redirect e Dio com Bearer + `SessionInvalidator` — nunca `SharedPreferences` para auth |
| Transporte | `tls_certificate_pinning.dart`, `Env.requireApiCertPins` | Release exige `API_CERT_PINS`; não desabilitar pinning "para facilitar debug" no ship |
| Erros na UI | `friendly_error.dart`, `FeedbackHelper` | `friendlyError` / `.when`; **proibido** `showError(context, '$e')` |
| IA | `ia_safety_disclaimer.dart` | Superfícies de IA mantêm `IaSafetyDisclaimer` |
| Pagamento | `subscription_device_guard.dart` | Jailbreak/root bloqueia fluxo de assinatura |
| Clipboard PII | `clipboard_sensitive.dart` | Copiar dado sensível só via helper com timeout |
| CI | `.github/workflows/security.yml`, `semgrep.yml` | Não quebrar `security_pillar_contract_test.dart` / `focux_security_test.dart` |

**Proibido no diff de upgrade visual:**
- Secret, API key ou PII desnecessário no payload/widget
- Token em prefs compartilhadas ou log de payload pessoal
- Relaxar manifest, backup rules, pinning ou headers "para passar no scanner"
- Auth, tenant, RLS, LGPD, migration ou contrato de API **sem aprovação** (pilares 52–68)

### Hardening mobile e web (baseline auditado 2026-08-20)

Rodada MobSF (APK release) + OWASP ZAP (site + backend). **Meta operacional:** 0 FAIL no ZAP; MobSF release ~50/100 (Grade B) é aceitável com os SDKs em uso (Health Connect, FCM, ML Kit) — **não** perseguir 100/100 removendo feature ou enfraquecendo manifest.

**Android (`focux-app`) — não regredir:**

| Artefato | Caminho | O que protege |
|---|---|---|
| Manifest | `android/app/src/main/AndroidManifest.xml` | `usesCleartextTraffic="false"`, `allowBackup="false"`, `taskAffinity=""` em activities exportadas (mitiga StrandHogg), App Links só `focuxpersonal.com` |
| Rede | `android/.../res/xml/network_security_config.xml` | TLS-only; alinhado ao pinning do app |
| Backup | `backup_rules.xml`, `data_extraction_rules.xml` | Exclui dados sensíveis de backup cloud/adb |
| Ofuscação | `android/app/proguard-rules.pro` | Regras ML Kit / R8 — não remover `dontwarn` necessários |
| Deep link | `focux-website/client/public/.well-known/assetlinks.json` + BE `application.yml` (`android-sha256-fingerprints`) | SHA-256 do keystore **release** |

**Achados MobSF aceitos (não "corrigir" no escuro):** StrandHogg residual em plugins (Health, `url_launcher` WebView), CBC/PKCS7 em bibliotecas de terceiros, 1 tracker Firebase/Google.

**iOS — não regredir:**

| Artefato | Caminho | O que protege |
|---|---|---|
| Orientação iPad | `ios/Runner/Info.plist` — `UIRequiresFullScreen = true` | Permite portrait-only no iPad (App Store 90474) |
| Deployment target | `ios/Podfile` + `Runner.xcodeproj` — 15.5 | Mínimo de `google_mlkit_commons`; manter os dois em sincronia |
| Assinatura | `ios/ExportOptions.plist` — `teamID` | Export de release |
| SPM | `pubspec.yaml` — `flutter: config: enable-swift-package-manager: false` | `flutter_native_splash` quebra na integração SPM experimental |
| APNs | Chave `.p8` no Firebase (não certificado SSL no portal) | Push via FCM |

**Web (`focux-website`) — headers em `vercel.json`:**
- CSP, HSTS, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`
- `Cross-Origin-Embedder-Policy: credentialless` (não `require-corp` — quebra assets)
- `Access-Control-Allow-Origin` restrito a `https://focuxpersonal.com` (não `*`)
- Re-scan ZAP baseline após mudança de headers (`security-scans/zap/` no monorepo)

**Backend — ao expor rotas novas:** `@PreAuthorize` + `TenantContext` (pilares 53–54); rate limit nos endpoints quentes (pilar 58); fingerprints de deep link sincronizados com website e Play signing key; teste `DeepLinkControllerTest`.

## 21. Desempenho

- **First paint:** um request de hub quando existir BFF; shimmer imediato; prefetch só em cold start de hub.
- **Scroll:** `CustomScrollView` / `ListView.builder` / slivers. Rails horizontais com **top-N**.
- **Rede:** timeout + retry do client; estado parcial não derruba a tela toda. Hub 60/60s é o teto.
- **Memória:** imagens lazy; sem listas locais pesadas no snapshot inicial. Paginar no BE.
- **Jank:** `TokensStrip.prefersReducedMotion` zera animação de entrada; haptics só em gesto deliberado. Em S8, fundo estático em vez de mesh animada.
- **Rebuild:** `select` / providers granulares; não invalidar o bundle inteiro do hub por causa de um chip.
- **BE:** sem N+1; batch; virtual threads só onde a Home já prova (`buildHomeResponseParallel`). Cache server com **evict no writer** e TTL explícito.
- **Peso:** não puxar `fl_chart`, câmera ou IAP se `FxSparkline` resolve.
- **Estabilidade:** null-safety respeitado; sem `!` perigoso sem tratamento; Crashlytics cobre a tela.

---

# Parte IV — Backend

## 22. Backend: proposta por tela e auditoria de legado

Duas frentes distintas, com ritmos distintos:

| Frente | Gatilho | Escopo | Onde |
|---|---|---|---|
| **Proposta por tela** | Toda vez que uma superfície é tocada | O caminho de dados **daquela** tela | §22.1–§22.4 |
| **Auditoria de legado** | Uma vez por domínio, independente do design | O código do backend como um todo | §22.5 |

A primeira impede que o trabalho de design deixe dívida invisível. A segunda é o que moderniza um backend escrito no começo do projeto — e **não** acontece como efeito colateral da primeira: uma auditoria conduzida a partir das telas só encontra o que a tela consegue sentir.

**Regra permanente, obrigatória, em toda tela tocada.** Ao trabalhar qualquer superfície, auditar o caminho de dados que a alimenta e **emitir o bloco "Proposta de backend" no scorecard — mesmo que a conclusão seja "nenhuma proposta"**. Backend **nunca** é alterado sozinho (§29): a entrega é a proposta, não o commit.

Motivo: UI boa sobre contrato ruim produz tela lenta, dado divergente e retrabalho. Auditar o dado junto do layout é mais barato do que descobrir depois.

### 22.1 Checklist de auditoria (rodar em toda tela)

| # | Sintoma no FE | Provável causa no BE | Pilar |
|---|---|---|---|
| 1 | A tela usa 4 campos de um payload de 40 | Falta BFF / endpoint genérico reaproveitado | 59 |
| 2 | Vários requests em série para montar um fold | Falta agregado | 59, 46 |
| 3 | FE filtra, ordena ou soma a coleção inteira | Falta filtro/ordenação/paginação no BE | 65 |
| 4 | Lista carrega tudo e pagina no cliente | Falta paginação real | 65 |
| 5 | Lista lenta conforme cresce | N+1 no Hibernate / falta `@EntityGraph` / falta índice | 61 |
| 6 | Dado muda numa tela e não na outra | Dual SSOT — dois endpoints como origem | 60 |
| 7 | Precisa de pull-to-refresh para ver o próprio write | Cache sem evict no write path | 62 |
| 8 | Regra de negócio escrita no widget | Regra ausente no BE | 3 |
| 9 | Gate de plano decidido no FE | Falta `verificarAcesso` / capability no BE | 11 |
| 10 | Duplo toque cria dois registros | Falta idempotência | 64 |
| 11 | Erro genérico sem como explicar ao usuário | Falta código/mensagem de domínio | 63 |
| 12 | Validação só no FE | Falta Jakarta Validation | 63 |
| 13 | Payload traz email/CPF que a tela não mostra | PII além do job | 52, 55 |
| 14 | Endpoint quente sem proteção (IA, upload, busca) | Falta rate limit | 58 |
| 15 | Campo novo sem contrato publicado | Falta `@Operation` / Springdoc | 68 |
| 16 | Mudança de schema aplicada à mão | Falta migration `V###__descricao.sql` | 66 |
| 17 | Impossível depurar lentidão da tela | Falta log/métrica/trace (Actuator/Micrometer/Brave) | 67 |
| 18 | Enum como string livre atravessando a borda | Falta tipo no contrato | 71 |
| 19 | Ação sensível sem registro | Falta auditoria | 56 |
| 20 | Ação principal sem evento de produto | Falta telemetria | 77 |

### 22.2 Template do bloco (obrigatório no scorecard)

```
## Proposta de backend — <rota> (<tipo S#>)

### P0 (bloqueia o ship desta tela)
- Sintoma: <o que o usuário sente / o que a UI é forçada a fazer>
  Evidência: <arquivo:linha no FE> · <endpoint> · <classe BE se conhecida>
  Impacto: pilar <#> — <consequência concreta>
  Proposta: <contrato atual → contrato proposto, campo a campo>
  Custo/risco: <quem consome hoje, o que quebra, precisa de migration?>
  Decisão pendente: <o que eu preciso que você aprove>

### P1 (propor agora, aplicar em PR próprio)
- <mesmo formato>

### P2 (registrar, sem urgência)
- <uma linha por item>

### Nenhuma proposta
- <quando for o caso, afirmar explicitamente e dizer o que foi verificado>
```

### 22.3 Severidade

| Nível | Critério | Efeito |
|---|---|---|
| **P0** | Correção de dado, segurança, tenant, PII, LGPD, gate de plano burlável, idempotência ausente em ação financeira | **Bloqueia o ship da tela.** Não maquiar com UI |
| **P1** | Performance (N+1, paginação, agregado), contrato gordo, cache sem evict, validação, observabilidade | Propor no scorecard; aplicar em PR próprio após aprovação |
| **P2** | Nomenclatura, documentação, telemetria adicional, refinamento de erro | Registrar |

### 22.4 Limites

- **Nunca** aplicar sozinho: auth, tenant/RLS, pagamento, migration, endpoint novo, mudança de contrato, rate limit, cache server, telemetria nova.
- Proposta descreve **contrato**, não implementação: campos, tipos, códigos de erro, paginação, TTL, invalidação.
- Se a tela precisar de campo que ainda não existe: **propor e parar**. Não inventar stub no FE, não criar segundo caminho de dado, não deixar `TODO`.

### 22.5 Auditoria de legado (varredura por domínio, não por tela)

**Limite declarado deste documento:** ele foi escrito a partir do aplicativo. Tudo o que ele afirma sobre o backend vem dos contratos que o app consome e das regras já documentadas — **não** de leitura do código de `focux-backend`. Portanto §22.5 é o **roteiro** da varredura, não o resultado dela. O resultado exige o repositório do backend aberto, e produz um relatório próprio, com severidade, por domínio.

Backend iniciado no começo do projeto acumula um tipo específico de dívida: o que funcionava com 3 alunos e 1 personal não sobrevive a tenant, plano, webhook de pagamento e hub agregado. A varredura procura exatamente essas costuras.

#### 22.5.1 Fase 0 — inventário (entregável antes de qualquer refactor)

Sem inventário, modernização vira caça a sintoma. Seis levantamentos, cada linha classificada como `OK` / `P0` / `P1` / `P2`:

| Inventário | O que levantar | Serve para |
|---|---|---|
| **Endpoints** | Método, path, papel exigido (`@PreAuthorize`), origem do tenant, rate limit, documentado no OpenAPI, **quem consome no app** | Achar endpoint sem autorização, sem tenant e **sem consumidor** (candidato a remoção) |
| **Entidades** | Tabela, relacionamentos, `fetch` (LAZY/EAGER), cascatas, índices, colunas de filtro/ordenação, soft delete, auditoria | Achar N+1 estrutural, FK sem índice, cascata perigosa |
| **Migrations** | Histórico Flyway completo, buracos de numeração, migration editada após aplicada, `ddl-auto` efetivo por ambiente, drift entre schema e entidades | Garantir que o schema é reproduzível do zero |
| **Dependências e plataforma** | Versão de Spring Boot, JDK, Hibernate e bibliotecas; fim de suporte; CVEs conhecidas; deprecations em uso | Planejar upgrade sem quebrar contrato |
| **Assíncrono** | Schedulers, filas, webhooks (MercadoPago, Terra), push FCM: idempotência, retry, tratamento de falha, reprocessamento | Achar duplicidade de cobrança e evento perdido |
| **Caches** | Nome, TTL, quem popula, **quem invalida**, invalidação distribuída (Redis pub/sub) | Achar cache sem evict no writer e dado velho servido como novo |

#### 22.5.2 Ordem de ataque (por risco, não por idade do código)

1. **Autorização, tenant e RLS.** Vazamento de dado entre personais é o pior defeito possível do produto. Vem antes de tudo.
2. **Correção de dado.** Transação, concorrência, idempotência de webhook e de ação financeira.
3. **Testes dos caminhos críticos.** Antes de refatorar, travar o comportamento atual em teste — é a escora.
4. **Contrato.** DTO/record na borda, erro padronizado, OpenAPI, agregado para hub.
5. **Performance.** N+1, índice, paginação, cache com TTL e evict.
6. **Resiliência e observabilidade.** Timeout, retry com backoff, métrica e trace por endpoint.
7. **Estrutura interna.** Camadas, god-service, duplicação de mapeamento.
8. **Plataforma.** Upgrade de versões — **por último**, e somente com o passo 3 pronto. Trocar a fundação antes de ter escora é como subir de versão sem rede.

#### 22.5.3 Checklist por área

Sintomas típicos de backend legado, com o alvo correspondente. Cada item vira linha do relatório com severidade.

**A. Autorização, tenant e sessão** (pilares 52–55)

| Sintoma de legado | Alvo |
|---|---|
| Endpoint sem `@PreAuthorize`, ou com papel genérico demais | Papel explícito por endpoint |
| `personalId` chegando por `@PathVariable`/`@RequestParam`/body | Tenant **só** de `TenantContext` |
| Query sem filtro de tenant confiando no filtro do app | Filtro no repositório + RLS no Postgres como rede |
| RLS ausente ou desalinhada das queries | Política por tabela multi-tenant |
| CORS `*` ou `@CrossOrigin` espalhado no controller | Origem restrita, configurada num só lugar |
| Refresh token sem rotação/revogação | Rotação + revogação testada |

**B. Persistência e modelo** (pilares 61, 71)

| Sintoma de legado | Alvo |
|---|---|
| `EAGER` por conveniência; coleção carregada sempre | `LAZY` + `@EntityGraph`/join fetch no caso de uso |
| Loop chamando repositório dentro de laço | Consulta em lote |
| `findAll()` alimentando tela | Consulta paginada e filtrada |
| FK e coluna de filtro/ordenação sem índice | Índice por padrão de acesso real |
| `CascadeType.ALL` amplo, com `orphanRemoval` implícito | Cascata mínima e explícita |
| Entidade JPA devolvida direto como resposta HTTP | DTO/record na borda |
| Enum persistido por `ORDINAL` ou string livre | `@Enumerated(STRING)` com valor estável |
| `Date`/`Calendar` legado; timestamp sem timezone | `Instant`/`OffsetDateTime`, UTC no banco |
| Dinheiro em `double`/`float` | `BigDecimal` com escala definida |
| Exclusão física onde o produto precisa de histórico | Soft delete + auditoria |

**C. Migrations e schema** (pilar 66)

| Sintoma de legado | Alvo |
|---|---|
| `ddl-auto: update` fora de teste local | `validate` em produção; schema só por migration |
| Migration editada depois de aplicada | Migration nova, sempre |
| Coluna criada à mão em produção | Toda mudança versionada em `V###__descricao.sql` |
| Banco impossível de recriar do zero | Histórico Flyway íntegro, verificado em CI |

**D. Contrato e API** (pilares 59, 63, 68, 71)

| Sintoma de legado | Alvo |
|---|---|
| Endpoint devolvendo o mundo; app usa 4 de 40 campos | Resposta do tamanho do caso de uso; agregado para hub |
| Muitos endpoints para montar uma tela | Um agregado tipado (padrão `GET /api/dashboard/home`) |
| `Map<String, Object>` como resposta | Record/DTO tipado |
| Erro respondido como texto livre ou stacktrace | Corpo de erro padronizado com **código de domínio** que o app traduz em copy |
| `catch (Exception e)` engolindo a causa | Exceção de domínio + handler global |
| Validação só no app | Jakarta Validation na borda do BE |
| Endpoint sem `@Operation`/Springdoc | 100% dos endpoints consumidos pelo app documentados |
| Mudança de contrato sem par no app | PRs pareados; nunca quebrar cliente em produção |

**E. Idempotência, transação e concorrência** (pilar 64)

| Sintoma de legado | Alvo |
|---|---|
| Webhook de pagamento reprocessado gera cobrança/baixa duplicada | Idempotência por id do evento, com teste que envia o mesmo evento duas vezes |
| `@Transactional` no controller, ou ausente no serviço que muda estado | Fronteira de transação no serviço, no tamanho da operação |
| Escrita concorrente sobrescrevendo silenciosamente | Versionamento otimista ou trava explícita |
| Retry do cliente criando registro repetido | Chave de idempotência na requisição |
| Chamada externa dentro da transação | Externo fora da transação |

**F. Cache e invalidação** (pilares 49, 62)

| Sintoma de legado | Alvo |
|---|---|
| Cache sem TTL, ou TTL só no cliente | TTL explícito nos dois lados, alinhados |
| Nenhum writer invalidando | Evict no **write path** (padrão `DashboardHomeCacheEvictor`) |
| Instâncias com cache divergente | Invalidação distribuída (Redis pub/sub) |
| Expiração simultânea derrubando o banco | Jitter no TTL |
| App forçando refresh a cada tap para ver o próprio write | Evict correto, não refetch |

**G. Resiliência e rede** (pilar 48)

| Sintoma de legado | Alvo |
|---|---|
| Cliente HTTP sem timeout | Timeout de conexão e leitura em toda integração |
| Retry infinito, ou nenhum | Retry com backoff (Resilience4j) e teto |
| Falha de integração derrubando a resposta inteira | Degradação parcial, com o campo faltante sinalizado |
| Sem proteção em endpoint quente (IA, upload, busca) | Rate limit por endpoint (pilar 58) |

**H. Observabilidade** (pilar 67)

| Sintoma de legado | Alvo |
|---|---|
| `System.out.println` / log de payload pessoal | Log estruturado, **sem PII** |
| Impossível saber o p95 de um endpoint | Timer por endpoint (Micrometer), nome por domínio |
| Erro sem correlação entre app e servidor | Trace propagado, id de correlação |
| Sem health/readiness | Actuator exposto no que é seguro expor |

**I. Testes** (pilares 73, 75)

| Sintoma de legado | Alvo |
|---|---|
| Regra de negócio sem teste | Teste de regra no serviço |
| Endpoint crítico sem teste de controller/contrato | Teste por path crítico |
| Teste dependendo de banco compartilhado ou de ordem | Banco efêmero por execução, teste independente |
| Refactor feito sem rede | Teste que trava o comportamento **antes** do refactor |

**J. Estrutura e limpeza** (pilares 69, 70, 72)

| Sintoma de legado | Alvo |
|---|---|
| Serviço com centenas de linhas e várias responsabilidades | Recorte por caso de uso |
| Regra de negócio no controller | Controller fino; regra no domínio |
| Mapeamento entidade→DTO duplicado em cada endpoint | Mapeamento num só lugar |
| Injeção por campo (`@Autowired` em atributo) | Injeção por construtor |
| Endpoint, entidade ou flag sem consumidor | Remoção, no mesmo ship (pilar 72) |
| Configuração espalhada em `@Value` soltos | Objeto de configuração tipado |

**K. Segredos, LGPD e auditoria** (pilares 55–57)

| Sintoma de legado | Alvo |
|---|---|
| Credencial em `application.yml` versionado | Variável de ambiente / gerenciador de segredo |
| PII em log, em resposta de erro ou em payload de hub | Somente o dado do caso de uso |
| Exclusão/exportação de dados sem caminho único | Só `/api/lgpd/me`, com o contrato existente |
| Ação sensível sem trilha | Registro de auditoria (quem, quando, o quê) |

#### 22.5.4 Metas mensuráveis

"Perfeito" não é adjetivo — é uma lista que passa ou falha. O backend está no alvo quando:

1. **0** endpoint sem papel exigido e sem tenant de `TenantContext`.
2. **0** ocorrência de tenant vindo do cliente.
3. RLS ativa e coerente em toda tabela multi-tenant.
4. **100%** dos endpoints consumidos pelo app documentados no OpenAPI.
5. **0** N+1 nos endpoints mais chamados, verificado com log de SQL sob carga realista.
6. Índice em toda FK e em toda coluna usada para filtro ou ordenação.
7. Toda lista exibida no app paginada, filtrada e ordenada **no servidor**.
8. Todo cache com TTL explícito e evict no writer; invalidação distribuída funcionando.
9. Todo webhook e toda ação financeira idempotentes, com teste de evento repetido.
10. Banco recriável do zero pelo histórico de migrations, verificado em CI; `ddl-auto: validate` em produção.
11. **0** segredo no repositório.
12. Erro de domínio com código estável, consumido pelo app para gerar copy específica.
13. p95 dos endpoints de hub dentro de um orçamento declarado por endpoint.
14. Teste de contrato em todo path crítico; `./gradlew test` verde sem teste ignorado.
15. **0** endpoint, entidade ou flag sem consumidor.

#### 22.5.5 Regras de execução

- **Um domínio por PR** (alunos, financeiro, treinos, assinatura, notificações, IA). Não misturar domínios.
- **Nunca** mudar contrato sem PR pareado no aplicativo. O app em produção não pode quebrar.
- Toda mudança de schema em migration nova. Nunca editar migration aplicada.
- Antes de refatorar, escrever o teste que trava o comportamento atual.
- Upgrade de plataforma só depois dos testes de contrato nos paths críticos.
- Relatório por domínio com severidade. **P0 do backend vem antes de qualquer trabalho estético** — inclusive antes do lote de design daquele domínio.

### 22.6 Estado do backend em 2026-09-02 e travas sobre o plano de design

Resultado da primeira varredura de `focux-backend`. Relatório completo em `focux-backend/docs/BACKEND_AUDIT.md`.

**Placar: 4 de 15 metas passam.** Spring Boot 3.4.4 (fora do suporte OSS) · JDK 21 · 432 endpoints · 12 P0 · 22 P1.

O que **passa**: nenhum endpoint aceita tenant do cliente (0 de 432 — a disciplina de `TenantContext` é real); `ddl-auto: validate` em produção; todo cache com TTL e invalidação distribuída ativa; nenhum teste ignorado.

#### 22.6.1 A causa-raiz: o gate nunca existiu

Quatro workflows ativos com **0 execuções**, e nenhum dos 790 commits passou por verificação. A suíte está vermelha (31 de 1087) e ninguém foi avisado. Pior: **21 das 31 falhas são apenas arquivos que não existem** (`AUDIT.md` na raiz, `docs/adr/001-jacoco-indicador.md`) — e não existem porque o `.gitignore` do backend ignora `/docs/`, a mesma política que o `focux-app` tem.

A cadeia é: `/docs/` ignorado → ADR não pode viver em `docs/` → teste que afirma a existência do arquivo falha → suíte vermelha → CI desligado não reclama → 790 commits sem gate → todo o resto desta lista pôde entrar sem resistência.

**Consequência de método:** consertar P0 com suíte vermelha e CI desligado é consertar no escuro. O primeiro PR do backend não é correção de código — é **fechar o gate**: decidir o destino de `/docs/`, resolver as 31 falhas, ligar o Actions. Só depois os P0 são seguros.

#### 22.6.2 Achados P0 por domínio

| Domínio | P0 | Pilar | Esforço | Quebra o app |
|---|---|---|---|---|
| plataforma | CI com 0 execuções; 790 commits sem gate | 79 | P | não |
| plataforma | Suíte vermelha 31/1087, incl. teste impossível de passar | 79 | M | não |
| auth | `SECRETARIA` altera o próprio papel para `CO_PERSONAL`, isento de todo cap | 54 | P | não |
| auth | Qualquer `PERSONAL` concede a si permissão arbitrária; recurso e nível são string livre do cliente | 54 | P | não |
| auth | RBAC de equipe em 6 de 64 módulos; colaborador alcança backup e pagamentos | 54 | G | não |
| financeiro | `catch` apaga o marcador de idempotência: MercadoPago re-entrega e credita o mês duas vezes | 64 | M | não |
| financeiro | Idempotência por check-then-act em vez de `INSERT ON CONFLICT` | 64 | M | não |
| financeiro | `@Transactional(REQUIRES_NEW)` anulado por auto-invocação | 64 | P | não |
| transversal | **342** `LocalDate(Time).now()` sem zona, container UTC, produto BR | 3 | G | não |
| assinatura | `POST /api/feedback-videos` não checa `POSE_COACH`; o gêmeo do aluno checa | 11 | P | não |
| assinatura | 4 entradas sem gate: pacotes, lote financeiro, converter lead, post de comunidade | 11 | M | não |
| IA e rede | 7 de 9 clientes HTTP sem timeout de connect ou read | 48 | P | não |

**Nenhum dos 12 P0 quebra o contrato do app.** Todos podem ser corrigidos sem PR pareado — o que os torna baratos em coordenação, não em risco.

#### 22.6.3 Matriz de travas: qual lote de design espera o quê

Aplicação literal da regra "P0 do backend antes do trabalho estético no domínio". Isto **substitui** a ordem sugerida em §28.3.

| Lote | Estado | Trava | Por quê |
|---|---|---|---|
| **S6 login / cadastro / recuperar senha** | **Liberado** | — | — |
| **S6 paywall / planos** | **Liberado** | — | Gates no servidor devolvem 403 com `codigo` do catálogo. Sheet já lê `upgradePlano` / `detalhes.feature` |
| **S1 hubs** | **Liberado** | — | `FocuxClock` em America/Sao_Paulo. 21h UTC-3 do dia 1 permanece dia 1 |
| **S3 detalhe de entidade** | **Liberado** | — | Números de streak/aderência/agenda passam a ter “hoje” estável |
| **S4 coleção / lista** | **Liberado** | — | Envelope A no ar. Primeiro: `GET /api/alunos` via `Pagina.fromJson`. Chat legado intacto. B/C fora desta rodada |
| **S5 formulário** | **Liberado** | — | Gate/cota/409/429 por `codigo`. 400 de campo continua prosa |
| **S8 execução** | **Liberado** | — | — |
| **S9 wizard** | **Liberado** | — | — |
| **S7 sheets** | **Liberado** | — | — |
| **S2 ajustes** | **Liberado** | — | Auditar limites de §11 |
| Telas de **financeiro** | **Liberado** | `double` no contrato (dívida, não trava) | Mesma notificação MP 2× credita 1× |
| Telas de **IA** | **Liberado** | — | Connect 5s / read 30s; estouro vira erro, não loading infinito |

**Lote em massa:** a ordem do §28.3 volta a valer. Um tipo por PR, no máximo 3 telas do mesmo tipo. Extrair padrão repetido para `lib/core/widgets/` *antes* do lote (§28.2). `double` em dinheiro e paginação B/C não bloqueiam estética.

#### 22.6.4 Acoplamentos descobertos no lado do app

Cruzamento do relatório contra `focux-app`. Três itens que o backend marcou como "não verificável" ficam fechados, e um vira mais grave do que parecia.

**1. O gate de plano do app era preso a texto em português — migrado.** `isPlanGateError` agora lê `codigo` como fonte primária (`lib/core/api/api_error.dart`, catálogo em `ApiErrorCodes`). Código conhecido decide sozinho; código fora do catálogo cai no heurístico de texto, senão um código novo derrubaria a sheet em silêncio; ausência de código continua no match `requer plano` / `faça upgrade` / `premium`. A reescrita de mensagem no servidor continua bloqueada enquanto houver versão antiga em produção — ver `docs/CONTRATO_APP_BACKEND.md` §2.4. `_humanizeServerMessage` segue preso a prosa para Cloudinary e 503; isso é copy, não classificação.

**2. `Idempotency-Key`: o app cobre, e o app *reproduz* mutações.** `ApiClient` (`lib/core/api/api_client.dart:195`) injeta o header em **todo** POST, PUT, PATCH e DELETE, exceto rotas de auth, `/api/suporte/analisar-erro`, `/api/uploads` e corpos `FormData`; `PaymentApiClient` faz o mesmo no caminho de pagamento. A cobertura do lado do cliente está essencialmente completa.

O agravante: `OfflineSyncService` (`lib/core/api/offline_sync_service.dart`) **enfileira mutações offline e as reenvia preservando a chave**. Reenvio não é hipótese — é comportamento projetado. Portanto o P0 "idempotência por check-then-act" não é teórico: a fila pode disparar duas requisições concorrentes com a mesma chave e vencer a janela entre o `SELECT` e o `INSERT`.

Nota de escopo: a idempotência do app (header) e a do webhook (marcador de evento do MercadoPago) são sistemas distintos. Os três P0 de `WebhookController` são do segundo, e nenhum deles é resolvido pela chave que o app envia.

Ressalva medida depois: a chave é preservada **na fila offline**, mas é regerada a cada tentativa no caminho normal, o que limita muito o alcance real da proteção — ver §22.7.3, item 3.

**3. O payload `dados` do FCM não é parâmetro morto — é feature quebrada.** O app consome `message.data` em seis pontos de `lib/core/fcm/fcm_service.dart` e `plan_sync_coordinator.dart`: `type`, `route`, `alunoId`, `chatId`, `event`, `plano`. Dois usos dependem dele:

- **Roteamento no toque da notificação** (`_handleNotificationTap`) — sem `dados`, o toque não leva a lugar nenhum.
- **Sincronização de plano** (`type: plan_sync`) — é como o app descobre que o plano mudou. Sem isso, depois de um upgrade ou downgrade o app segue com a permissão antiga até expirar cache ou reiniciar.

O relatório aponta o descarte em `enviarNotificacaoParaAluno`, que é o caminho do aluno. **Fechado na rodada seguinte:** o `plan_sync` do personal usa `enviarDataParaPersonal`, que faz `putAllData` corretamente, então a sincronização de plano do personal funciona hoje. O quebrado é qualquer payload data-only destinado a **aluno**, pelos seis chamadores de `enviarNotificacaoParaAluno`. Isso desacopla o bug do P1 do webhook MP: o app é avisado da troca de plano; o que falta é o registro na trilha de auditoria.

#### 22.6.5 O que segue em aberto

- **N+1 real (meta 5).** `show-sql` desligado; candidatos achados por análise estática, não observados em SQL.
- **Credencial no histórico do git.** O commit que removeu os scripts não reescreveu o histórico.

Fechados depois desta seção: consumidor de cada endpoint (meta 15) e orçamento de p95 (meta 13) — ver §22.7.

### 22.7 Cruzamento app × backend (backend @66ba467, app nesta branch)

Fecha a meta 15. Reprodutível com `python3 tools/audit/xref_endpoints.py`: o inventário recebido do backend está em `tools/audit/backend_endpoints.tsv` e o extrator varre `lib/**/*.dart` procurando `.get|post|put|patch|delete('/...')`, normaliza `$var`, `${expr}` e `{pathVariable}` para `{}`, e compara verbo + path contra o inventário. Regerar o TSV no repo do backend e substituir o arquivo inteiro; o script sai com código 1 se o app passar a chamar endpoint inexistente, então serve de gate.

**Números.** 432 endpoints no backend, 342 call sites em código de produto, 330 endpoints consumidos.

| Camada | Qtd | Significado |
| --- | --- | --- |
| Chamado por código de produto | 330 | contrato vivo; mudança quebra tela |
| Path no produto, outro verbo | 7 | ex.: app faz `POST /api/fcm/token` e nunca `DELETE` |
| Só no catálogo de smoke QA | 5 | backend pronto, UI inexistente |
| Zero menção no app | 90 | ver §22.7.1 |

Dois resultados negativos que valem tanto quanto os positivos: **nenhuma chamada do app aponta para endpoint inexistente** e **nenhuma usa verbo divergente**. O cliente não tem rota morta nem 404 latente, o que dá confiança de que a lista de 90 órfãos é do backend, não erro do extrator.

**Cobertura de OpenAPI na fronteira que importa:** 225 dos 330 endpoints que o app chama não têm `@Operation`. O P1 do pilar 68 medido só onde tem consumidor.

#### 22.7.1 Endpoints sem consumidor (meta 15)

Dos 90 sem menção, 20 são legitimamente fora do app — 4 webhooks servidor-a-servidor, 2 `.well-known` (consumidos pelo SO), e 14 de superfície web pública (`/`, `/p/{slug}`, `/c/{slug}`, `public/personal/*`, `loja/publico/*`, `pacotes/publico/*`, `captura/publico/*`, `public/ical/*`, `public/resolve-domain`).

**Restam 70 endpoints autenticados que só um cliente app alcançaria e que nenhum cliente chama.** Os agrupamentos que mudam decisão:

- **`comunidade` — 12 endpoints, módulo inteiro, zero referência.** Grupos, posts, entrada, bloqueio, denúncia e moderação existem no backend e não existem no app; não há `lib/features/comunidade/`. Consequências diretas: (a) o P0 "post de comunidade sem gate de plano" não tem caminho de UI, então o **vazamento de receita observado é zero** — a dívida permanece e precisa ser fechada antes de a superfície nascer; (b) 9 das 29 fugas de entidade JPA estão em `ComunidadeController`, então corrigir esses DTOs é **grátis** — não há contrato de app para quebrar. Decisão de produto pendente: construir a superfície ou remover o módulo.
- **Telemetria do cliente nunca emitida.** `POST /api/analytics/evento`, `POST /api/pql/eventos/{tipo}` e `GET /api/pql/me` não são chamados. O app lê `GET /api/analytics` e `GET /api/analytics/funil`, mas **não produz nenhum evento**. Os painéis de funil e o escore de PQL são alimentados só pelo que o servidor infere. `analytics/cohort` e `analytics/wau` também não têm consumidor.
- **Consentimento LGPD nunca registrado.** `GET` e `POST /api/lgpd/me/consent` sem consumidor, e `GET /api/lgpd/me/export` só aparece no catálogo de smoke. O app exclui conta (`DELETE /api/lgpd/me/delete` é chamado) mas nunca grava consentimento. Lacuna de pilar 55 no lado do app, com endpoint pronto.
- **Listas cruas já substituídas pelo gêmeo paginado.** `GET /api/alunos/{id}/timeline-360` (List) está órfã enquanto `/timeline-360/page` (Page) é usada. Mesmo padrão em `/api/exercicios` cru vs. `/api/exercicios/v2`. São remoções seguras.
- **Backend pronto sem UI (camada de smoke):** `POST /api/backup/create`, `GET /api/backup/list`, `GET /api/exportacao/dados`, `GET /api/lgpd/me/export`. Quatro funcionalidades completas sem superfície — candidatas naturais a S8 (Configuração) sem custo de backend.
- **`PUT` e `DELETE /api/tenant/membros/{id}` sem consumidor.** O app só lista (`GET`) e cria (`POST`) membro; nunca edita nem remove. É exatamente onde mora o P0 de escalonamento de privilégio (`TenantMembroController`). Ver a ressalva abaixo antes de concluir qualquer coisa sobre severidade.
- **`GET /api/pose-coach/status` nunca chamado** — ver §22.7.3.
- Outros grupos órfãos, sem decisão pendente: `auditoria` (3 — a trilha existe e nenhuma tela a mostra), `templates` (3), `trilhas` (3 de 6), `dashboard/focux-score` (2), `agenda/ocupacao` e `agenda/periodo`, `financeiro/lote/marcar-pago` e `mensalidades/marcar-atrasadas`.

> **Ressalva de leitura, obrigatória.** Órfão significa "nenhum cliente nosso chama", não "inalcançável". Um endpoint autenticado sem consumidor continua exposto a qualquer portador de token com `curl` — o atacante não usa o app. Portanto:
>
> - Para P0 de **autorização** (escalonamento em `TenantMembroController`, concessão arbitrária em `RbacController`, RBAC em 6 de 64 módulos), ser órfão **não reduz severidade em nada**. O único efeito é liberar a correção para ser agressiva: sem consumidor, não há contrato de app a preservar, então dá para fechar no nível mais restrito sem período de compatibilidade.
> - Para P0 de **gate de plano** (post de comunidade, pacotes, lote financeiro, conversão de lead), ser órfão reduz o vazamento de receita observado, porque nenhum usuário legítimo tem caminho de UI para consumir a feature sem pagar. A dívida continua e precisa ser fechada antes de a superfície existir.
>
> Em resumo: usar esta seção para dimensionar **risco de quebrar o app**, nunca para dimensionar **risco de segurança**.

#### 22.7.2 Paginação: as 61 listas que o app consome

Dos 86 endpoints com flag `L`, **61 têm consumidor de produto e 25 não**. Não paginar os 25. Os 61 se dividem por risco de crescimento, não por módulo:

| Bucket | Qtd | Ação |
| --- | --- | --- |
| **A — paginar primeiro** | 19 | cresce sem teto e alimenta tela de lista primária |
| **B — paginar depois** | 14 | cresce, mas volume por tenant é menor ou a tela é secundária |
| **C — só cap de `size`** | 26 | conjunto naturalmente pequeno; paginar aqui é custo sem ganho |
| **D — remover o cru** | 2 | gêmeo paginado já existe; app já migrou, backend pode apagar |

**Bucket A:** `/api/alunos`, `/api/leads`, `/api/feed`, `/api/feed/aluno`, `/api/feed/{postId}/comentarios`, `/api/checkin/historico`, `/api/feedback-videos`, `/api/feedback-videos/me`, `/api/feedback-videos/aluno/{alunoId}`, `/api/alunos/{alunoId}/fotos`, `/api/alunos/{alunoId}/medidas`, `/api/alunos/{alunoId}/avaliacoes`, `/api/alunos/{alunoId}/recordes`, `/api/alunos/{id}/historico-mensalidades`, `/api/chat/inbox/archived`, `/api/broadcasts`, `/api/captura`, `/api/retencao/base`, `/api/ranking`.

**Bucket B:** `/api/agenda/aluno/meus`, `/api/aluno/medidas`, `/api/automacoes/{fluxoId}/logs`, `/api/coach-proativo/mensagens`, `/api/depoimentos`, `/api/personal/depoimentos`, `/api/habitos/compliance`, `/api/habitos/me`, `/api/leads/{id}/interacoes`, `/api/loja/pedidos`, `/api/personal/gallery`, `/api/suporte/tickets/meus`, `/api/trilhas/aluno/{alunoId}`, `/api/winback/log`.

**Bucket D:** `/api/chat/aluno/historico` e `/api/chat/historico/{alunoId}`. **Resolvido do lado do app:** `historico()` não tinha chamador nenhum e saiu; `historicoAluno()` tinha um só, um fallback em `ia_aluno_screen` que baixava o histórico inteiro para ler um `alunoId`, e agora usa `historicoAlunoPage(limit: 1)`. Os dois endpoints crus passaram a órfãos no cruzamento e o backend está livre para apagá-los.

##### Envelope de paginação: escolher um antes de propagar

O app já convive com **três formatos** de resposta paginada, e essa é a dívida que os 33 endpoints dos buckets A e B multiplicariam se cada um for feito à mão:

| Formato | Campos | Onde |
| --- | --- | --- |
| Spring `Page` padrão | `content`, `number`, `size`, `totalElements`, `totalPages`, `last` | `/api/exercicios/v2`, `/api/exercicios/picker` |
| Financeiro | `mensalidades`, `page`, `size`, `hasMore` | `/api/financeiro/mensalidades` |
| Notificações | `items`, `page`, `total`, `hasMore` | `/api/notificacoes` |

Nenhum dos três é errado; ter três é. O custo real não é estético: array com nome de domínio (`mensalidades`) impede um parser genérico único no app, então cada endpoint novo vira um `fromJson` novo.

**Contrato único para os endpoints novos** — não mexer nos três que já funcionam: array em `content` (nome genérico, não de domínio), `page`, `size` com **cap no servidor**, `totalElements`, e `hasNext` explícito. `hasNext` explícito em vez de derivar de `last`, porque sem ele S4 não distingue "fim da lista" de "carregando mais" e o rodapé fica sem contrato. Ordenação **fixada no servidor** — o P1 "2 endpoints repassam `Sort` do cliente ao JPA" não deve se propagar junto.

Para coleção que cresce pela ponta e é lida de trás para frente, o cursor do chat (`items`, `nextBeforeId`, `hasMore`) é o modelo melhor e já está implementado: preferir cursor a offset em histórico e feed, onde `page`/`offset` sofre com item inserido durante a navegação.

#### 22.7.3 Três bugs do lado do app achados pelo cruzamento

São do app, entram no meu lado do plano, não no do backend.

**1. Logout não desregistra o token de push.** **Resolvido nos dois lados:** app chama `DELETE` antes do logout; servidor reclama o token no registro e `V157` cria unique em `token`. Ver `docs/CONTRATO_APP_BACKEND.md` §3.

**2. A fila offline trata falha permanente como transitória.** **Resolvido no app:** 4xx permanente sai na primeira tentativa; 5xx/transporte/408/409/429 retentam; descarte aparece no banner.

**3. `Idempotency-Key` nova por tentativa anula a proteção contra toque duplo.** **Resolvido no app** para criar/pagar/PIX de mensalidade via `ApiClient.idempotent(scope)`. O P0 restante de dinheiro é o webhook MercadoPago, não esta chave.

#### 22.7.4 Correções ao que ficou registrado antes

- **O 409 da idempotência concorrente é benigno, e o risco real é outro.** A fila offline só é acionada em `connectionError`/`connectionTimeout` (`api_client.dart:77`), então um 409 do servidor nunca entra na fila; e dentro da fila um 409 é engolido, reenviado com backoff e resolvido pelo replay quando a primeira requisição completa. O 409 não chega ao usuário. O problema naquele mesmo trecho é o do item 2 acima.
- **O gate do Pose Coach pode fechar sem quebrar usuário legítimo.** O app trava a feature 100% no cliente por `features.poseCoach`, vindo de `GET /api/planos/me` (`lib/features/checkin/widgets/gated_pose_coach_panel.dart:36` e `lib/features/alunos/utils/aluno360_ferramentas_logic.dart`), e **nunca chama `GET /api/pose-coach/status`**. Como o app já esconde a entrada com a mesma capability que o backend passará a exigir, fechar o gate em `POST /api/feedback-videos` não remove nada que um cliente atualizado ofereça a um plano sem direito. A decisão de produto fica bem mais barata do que o relatório sugeriu; o endpoint `/api/pose-coach/status` é dívida (ou vira a fonte única e o cliente para de inferir).
- **O app já migrou para `codigo`.** `isPlanGateError` lê o catálogo de `ApiErrorCodes` primeiro e mantém o match de string só como fallback. Cota (`IA_QUOTA_ESGOTADA` e irmãos) não é gate, mesmo com "Faca upgrade" no texto. Contrato: `docs/CONTRATO_APP_BACKEND.md` §2. A reescrita de `erro` no servidor continua no passo 4, bloqueada enquanto houver versão antiga em produção.

## 23. Contrato de dados por tipo de superfície

| Tipo | Forma esperada do dado | Cache | Paginação |
|---|---|---|---|
| S1 | **Um** agregado tipado (BFF), com top-N embutido e `null` nas listas pesadas | Client + server, TTL explícito (Home: 90s), evict no writer | Não se aplica (top-N) |
| S2 | Um GET de perfil/config + gates de plano | Curto; invalidar no write | Não |
| S3 | Um agregado da entidade (`/360`) | Curto | Seções internas paginadas se longas |
| S4 | Página tipada: `content` + `page`/`total`/`hasNext` | Curto ou nenhum | **Obrigatória no BE**, com filtro e ordenação |
| S5 | GET do recurso (edição) + PUT/POST validado | Nenhum | Não |
| S6 | Sessão/auth e catálogo de planos | Catálogo pode cachear | Não |
| S7 | Reusa o dado da tela-mãe | Herda | Não |
| S8 | Estado local durável + sync eventual idempotente | Local first | Não |
| S9 | Rascunho persistido por etapa | Local + servidor | Não |

## 24. Superfície Hoje: contrato vigente de referência

Contrato em produção da principal S1. Não apagar estas regras: elas são o modelo de qualquer hub novo.

| Tema | Contrato |
|---|---|
| Rota | Shell `/dashboard/personal` (tab Hoje). Job = cobrar / retomar / agenda |
| BFF | `GET /api/dashboard/home` + `DashboardHomeBundle.fromJson`. Rate limit 60/60s. Timer `focux.dashboard.home` |
| Foco | `dayFocus` do BFF; banner + chip; «Foco» só no banner |
| Próximas ações | `buildDashboardNextActions` / `CommandCenterService`. Sticky `DashboardPrioritiesOverlay` recolhe na faixa de tools |
| Plano | `planoFeatures` no bundle = `/api/planos/me` |
| Unread | Badge do app ≠ unread do chat |
| Cache | TTL 90s client + server; `DashboardHomeCacheEvictor` + Redis pub/sub |
| First paint | Header `Olá, {primeiro}` + freshness → Foco → P0. Conta nova: `DashboardActivationCta` |
| IA | Só na tab `/ia`. Complete/snooze via `/command-center/actions/*` |
| Deep link | `?focus=on\|off`, `?sheet=search\|help\|catalog` |
| Top-N | Score ≤5, aderência 3, agenda strip 3. Sem lista infinita |
| Funil | `home_viewed`, `home_ttv`, `home_search_opened`, `home_priorities_opened`, `home_day_focus_action`, `home_help_opened` |
| Pele | Glass/`ShellChrome`, raio 20, ícone 22 sem poço. Financeiro **não** é hero invertido. CTA in-card = chip sticky (`DashboardHomeActionChip`), não botão branco no preto nem full-width |

**BE a espelhar em hubs:** `DashboardController.getHome` → `DashboardService` / `DashboardHomeResponse` / `DashboardDayFocusResolver` / `DashboardHomeCacheEvictor`.

**Composição Hoje-only** (reusar só se houver outro "Hoje"): `PersonalDashboardScreen` + parts, `buildDashboardHomePrimarySlivers`, `DashboardHomeSecondaryBlock`.

---

# Parte V — Os 80 pilares

## 25. Regra de evidência

Nenhum pilar recebe nota sem evidência verificada em código — ou é marcado explicitamente **"não verificável nesta sessão"**, com o que falta abrir para verificar. Print de tela sozinho só é evidência suficiente para os pilares puramente visuais (14–30, aprox.); os demais exigem abrir o(s) arquivo(s) FE e/ou BE.

**Lado(s):** **FE** = frontend Flutter · **BE** = backend Spring Boot · **FE+BE** = ambos aplicáveis por padrão (podem virar N/A individualmente dependendo da tela avaliada).

A coluna **10/10 elevado** existe onde a v2 endurece o critério; `=` significa que a evidência mínima já é o alvo.

## 26. Tabelas dos 80 pilares

### Produto e valor

| # | Pilar | Lado(s) | Evidência mínima | 10/10 elevado |
|---|---|---|---|---|
| 1 | Produtividade operacional | FE+BE | Ação principal completável em poucos toques, sem ida-e-volta desnecessária entre telas. | Ação principal do tipo (§9) em ≤2 toques a partir do first paint |
| 2 | Rota & job-to-be-done | FE | A rota/tela resolve um job único e nomeável; não mistura fluxos não relacionados. | Tela **classificada** em S1–S9 e coerente com o esqueleto do tipo |
| 3 | Lógica de negócio & regras | FE+BE | Regra (ex.: aluno inativo, plano FREE) aplicada nos dois lados e refletida na UI, não só silenciosa no BE. | Regra em função pura testada; ausência no BE gera proposta P0 (§22) |
| 4 | Hierarquia de decisão (foco/priorização) | FE | Existe 1 ação/decisão primária visualmente destacada; não é lista plana. | **Exatamente 1 P0**, no tratamento previsto para o tipo (§11); passa o teste do squint |
| 5 | Valor aluno (loop retenção/outcome) | FE+BE | Ação conecta a um outcome visível (score, progresso, conquista) quando a tela permite. | = |
| 6 | Descoberta & educação in-product | FE | Funcionalidade não óbvia tem dica/tooltip/empty-state educativo. | Ajuda via `FxHelpIconButton`/`showFxHelpSheet`, não linha no meio da lista |
| 7 | Onboarding & first-run | FE | Primeira visualização sem dados tem estado guiado, não só "vazio". | `FxEmptyState` com CTA que inicia o job; S9 quando houver múltiplas etapas |
| 8 | Personalização & white-label | FE | Cor/identidade do personal aplicada via token, não hardcoded. | Acento sempre `BrandPalette.softened(colorScheme.primary)` |
| 9 | IA assistiva (sugestão, opt-in, reversível) | FE+BE | Sugestão de IA é opt-in e reversível (aceitar/rejeitar explícito), nunca autoaplicada. | = |
| 10 | Confiança & transparência (scores, IA, dados) | FE+BE | Score/número tem origem explicável (tooltip "como calculamos"); IA tem disclaimer. | = |
| 11 | Monetização & gates de plano | FE+BE | Limite de plano é checado no BE (não só escondido no FE) e comunicado com copy clara. | `FxPlanLockTrailing` + `UpgradePromptSheet`; zero `if (plano == …)` em widget |
| 12 | Notificações & unread unificado | FE+BE | Contagem de não lidos bate entre a tela, o badge da tab e a central. | = |
| 13 | Time-to-value | FE | Valor principal visível sem scroll/loading extra (above the fold). | Valor do **tipo** above the fold: métrica em S3, foco em S1, CTA em S6 |

### UX / UI / visual

| # | Pilar | Lado(s) | Evidência mínima | 10/10 elevado |
|---|---|---|---|---|
| 14 | Design visual & identidade | FE | Paridade de tokens de cor/glass com a Home. | Os **7 itens da assinatura Focux** (§2) presentes |
| 15 | Tipografia & hierarquia | FE | Usa `AppTypography` (Outfit / JetBrains Mono) nos mesmos papéis da Home. | Papel semântico de §5; zero `fontSize` literal; ≤1 `pageTitle` |
| 16 | Espaçamento & layout | FE | Usa tokens de spacing; zero número mágico solto. | Todo valor rastreável a §4 |
| 17 | Cores & contraste (WCAG) | FE | Contraste texto/fundo ≥ 4.5:1. | Verificado nos dois temas |
| 18 | Dark / light parity | FE | Testado em tema escuro; nenhuma cor hardcoded quebra o dark. | Toda cor via `ShellChrome`/tokens |
| 19 | Hierarquia visual & foco atencional | FE | Peso visual primário vs. secundário replica o padrão da Home. | **Três pesos** de §11 respeitados: 1 P0, ≤2 P1, resto P2 |
| 20 | Componentes & design system | FE | Reusa componentes de core; não reimplementa estilo inline. | Componente escolhido pela **matriz de intenção** (§10) |
| 21 | Densidade de informação | FE | Densidade comparável à Home — nem vazia demais, nem lotada. | Limites contáveis de §11–§12 (≤3 sinais/linha, agregação a partir de 3) |
| 22 | Gestalt & percepção | FE | Agrupamento por proximidade/similaridade organiza itens relacionados. | ≤4 grupos por nível; destrutivo isolado |
| 23 | Personalidade & branding | FE | Tom de copy consistente com o resto do app. | Rótulo de ação é verbo; sem jargão interno |
| 24 | Data viz & conteúdo dinâmico | FE | Gráficos/números seguem o estilo já usado na Home. | `FxSparkline` antes de `fl_chart`; número sempre com unidade |
| 25 | Empty states & zero-data | FE | Ícone + título + subtítulo + CTA. | `FxEmptyState` + `FxEmptyAction` que inicia o job |
| 26 | Loading / skeleton / disclosure | FE | Usa skeleton; nunca spinner isolado sem contexto. | Skeleton no **formato** do conteúdo real; `FxAsyncBody` preferido |
| 27 | Erro / retry / degradação | FE | Estado de erro com retry; nunca exceção crua na tela. | `friendlyError`; erro **local** por bloco quando o resto funciona |
| 28 | Offline / stale / freshness | FE | Indica dado desatualizado quando a tela depende de cache. | = |
| 29 | UX writing & microcopy | FE | Copy curta, orientada à ação, sem jargão técnico/interno. | = |
| 30 | Feedback & estados de interação | FE | Hover/press/disabled seguem o padrão de motion da Home. | Estado de envio explícito em S5/S6 |
| 31 | Search & findability | FE | Lista longa tem busca/filtro acessível. | Busca obrigatória em S4 acima de ~10 itens; ≤5 chips visíveis |
| 32 | Forms & data entry | FE | Validação inline, máscara e teclado corretos por tipo. | Esqueleto S5 completo, incluindo footer sticky e descarte confirmado |
| 33 | Touch targets & haptics | FE | Alvo mínimo 48×48dp; haptic em ações destrutivas/confirmação. | Controle de S8 ≥64; haptic nunca em first paint/scroll |
| 34 | Gestos & adaptação de plataforma | FE | Back gesture Android / swipe iOS não conflitam com gesto customizado. | = |
| 35 | Responsividade | FE | Sem overflow em phone/tablet/landscape. | Testado com teclado aberto; `FxContentWidthLimiter` em satélite |
| 36 | Thumb zone & ergonomia | FE | Ações frequentes na zona inferior alcançável. | P0 na metade inferior em S3/S5/S6/S8/S9 |
| 37 | Motion design & reduced motion | FE | Curva/duração igual ao padrão; respeita "reduce motion" do SO. | `prefersReducedMotion` verificado; S8 sem mesh animada |
| 38 | Acessibilidade (WCAG 2.2 AA) | FE | `Semantics` presentes; navegável por leitor; contraste ok. | `fxScreenA11yScope` na raiz; `fxAnnounce` em mudança de estado |
| 39 | Internacionalização & locale | FE | Datas/moeda formatadas por locale. | **PT-BR na superfície** + formatos BR (§8). Não migrar para EN/ES |
| 40 | Conteúdo & clareza informacional | FE | Texto sem ambiguidade; números sempre com unidade/contexto. | = |
| 41 | Sustentabilidade de atenção | FE | Não empilha múltiplos alertas/badges sem necessidade. | 1 banner; ≤5 chips na tela; agregação a partir de 3 repetições |

### Navegação e arquitetura de informação

| # | Pilar | Lado(s) | Evidência mínima | 10/10 elevado |
|---|---|---|---|---|
| 42 | Navegação & IA | FE | Rota no shell certo (Personal vs. Aluno) na árvore do GoRouter. | = |
| 43 | Shell / tabs / deep links | FE | Acessível via tab/shell consistente; deep link funciona se aplicável. | Parâmetros de deep link documentados |
| 44 | Back stack & predicabilidade | FE | Voltar leva ao lugar esperado, sem loop nem tela órfã. | `safePopOrGo`; S5/S9 confirmam descarte |
| 45 | Modais / sheets / overlays / focus trap | FE | Focus trap correto; fecha por back/gesture; nunca bloqueia sem saída. | Um dos 4 subtipos de S7; ≤1 nível de aninhamento; regras de altura/teclado |

### Performance e resiliência

| # | Pilar | Lado(s) | Evidência mínima | 10/10 elevado |
|---|---|---|---|---|
| 46 | Performance percebida (TTI) | FE | Skeleton aparece rápido; nunca tela branca. | Um request de hub; sem segundo loading no fold |
| 47 | Performance real (jank/scroll) | FE | `ListView.builder`/lazy rendering em listas; sem rebuild desnecessário. | Stagger só em bloco finito, nunca em item de lista longa |
| 48 | Rede & resiliência | FE+BE | Timeout, retry com backoff, estado parcial tratado na UI. | = |
| 49 | Cache client | FE | Cache local coerente com o TTL do padrão Home. | TTL alinhado ao BE; evict no write path |
| 50 | Cold start / peso da tela | FE | Lazy loading de imagens/dados pesados; não bloqueia o primeiro frame. | = |
| 51 | Estabilidade (crash-free) | FE | Null-safety respeitado; sem `!` perigoso; Crashlytics cobre a tela. | Crash de layout corrigido na causa, não silenciado |

### Segurança, privacidade e compliance

| # | Pilar | Lado(s) | Evidência mínima | 10/10 elevado |
|---|---|---|---|---|
| 52 | Segurança de superfície (PII na UI) | FE | Dado sensível mascarado quando não estritamente necessário. | PII fora do job vira proposta P0 (§22) |
| 53 | Autenticação & sessão | FE+BE | Token expira/renova (refresh com rotação); 401 desloga corretamente. | = |
| 54 | Autorização / tenant / RLS | BE | Endpoint valida `personal_id` via `TenantContext`; nunca tenant por parâmetro livre; RLS coerente. | = |
| 55 | LGPD / privacidade / consentimento | FE+BE | Dado pessoal com base legal; `/api/lgpd/me` respeitado. | Sem segundo caminho de exportação/exclusão |
| 56 | Auditoria & trilha | BE | Ação sensível gera registro de auditoria. | = |
| 57 | Secrets / OWASP mobile | FE | Nenhum secret hardcoded; certificate pinning ativo em release. | `REQUIRE_API_CERT_PINS=false` só em sideload de teste |
| 58 | Rate limit & abuse | BE | Endpoints consumidos pela tela (IA, upload) têm rate limit. | Ausência em endpoint quente vira proposta P0 |

### Backend, dados e ops

| # | Pilar | Lado(s) | Evidência mínima | 10/10 elevado |
|---|---|---|---|---|
| 59 | Contrato API & BFF | BE | Endpoint retorna só o que a tela precisa; contrato documentado no Springdoc. | Contrato conforme §23 para o tipo da tela |
| 60 | Single source of truth | FE+BE | Dado não diverge entre telas (mesmo provider/endpoint como origem). | Zero provider duplicado do agregado |
| 61 | Performance API (N+1, batch, p95) | BE | Sem N+1 (checar fetch/`@EntityGraph`); índice presente. | = |
| 62 | Cache server & invalidação | BE | TTL correto, invalidado ao mutar o dado relacionado. | Evict no writer, não refetch por tap |
| 63 | Validação & erros de domínio | BE | Validação Jakarta + mensagem de domínio clara, nunca stacktrace. | Código de erro que o FE traduz em copy específica |
| 64 | Idempotência & concorrência | BE | Ação repetível é idempotente; concorrência tratada. | = |
| 65 | Paginação / filtros / ordenação | BE | Lista pagina no backend, não traz tudo para paginar no cliente. | Toda S4 com contrato paginado (§23) |
| 66 | Migrations / Flyway / schema | BE | Mudança de schema em migration versionada. | = |
| 67 | Observabilidade BE | BE | Log/métrica/trace suficientes para depurar problema desta tela. | Timer p95 nomeado por domínio |
| 68 | Documentação (API/contrato/runbook) | BE | Endpoint documentado no Springdoc OpenAPI. | = |

### Engenharia e qualidade

| # | Pilar | Lado(s) | Evidência mínima | 10/10 elevado |
|---|---|---|---|---|
| 69 | Código limpo & SRP | FE+BE | Responsabilidade única; sem "god file". | Lógica fora do `build()`; parts por bloco, não por conveniência |
| 70 | Escalabilidade & composição | FE+BE | Componente composável/reutilizável, não copiar-colar entre telas. | Padrão que vai repetir é **extraído para core antes** do lote (§28) |
| 71 | Tipagem & modelos de borda | FE+BE | DTOs/models tipados nas bordas; sem `dynamic`/`Object` solto. | Zero `Map<String, dynamic>` na UI |
| 72 | Dead code & dívida técnica | FE+BE | Sem import/método morto; sem TODO crítico esquecido. | Fold antigo removido **no mesmo ship** (§30) |
| 73 | Testes unitários (regras) | FE+BE | Regra nova coberta; lógica de estado crítica coberta no Flutter. | = |
| 74 | Testes de UI / widget | FE | `flutter test` cobre o widget principal da tela. | Teste de contrato afirma o **tipo** da superfície (§32) |
| 75 | Testes de contrato / API / MVC | BE | Endpoint tem teste de controller/contrato. | = |
| 76 | A11y automatizada em testes | FE | `Semantics` verificado em teste ou checado com TalkBack/VoiceOver. | = |
| 77 | Telemetria / analytics de produto | FE+BE | Product event disparado na ação principal da tela. | Evento novo só **proposto**, nunca funil paralelo |
| 78 | Feature flags & rollout | FE+BE | Mudança arriscada protegida por flag quando aplicável. | = |
| 79 | CI / release readiness | FE+BE | `flutter analyze --fatal-warnings --fatal-infos` e `./gradlew test` sem novo warning. | Rodado de fato; não pontuar de memória |
| 80 | Docs de produto / help na superfície | FE | Tela complexa tem help/tooltip acessível nela mesma. | `FxHelpIconButton` na app bar |

## 27. Pilares estruturais 81–92

Extras da v1, generalizados para todo o app. Avaliados junto dos 80.

| # | Pilar | Lado | Evidência de 10/10 |
|---|---|---|---|
| 81 | **Tipo de superfície declarado** | FE | A tela é classificada em S1–S9 no PR e o esqueleto corresponde ao tipo (§9) |
| 82 | **Paridade tipográfica** | FE | Papéis de `FocuxHubTypography`; sem escala ad-hoc |
| 83 | **Ícones e acento na marca** | FE | Leading na marca, chevron muted, `FxIcon` outline 22 |
| 84 | **Sem CTA invertido** | FE | Nenhum botão branco sobre preto; nenhum hero invertido |
| 85 | **Sem tema emprestado** | FE | Mesh + glass; não copia o preto/azul do ChatGPT nem o azul iOS |
| 86 | **Limpeza no mesmo ship** | FE | Fold antigo, campos e testes velhos removidos no mesmo commit (§30) |
| 87 | **Picker canônico** | FE | Seleção única em sheet via `showFxInsetPickerSheet` / `FxInsetPickerOption` |
| 88 | **Destrutivo isolado** | FE | Sair / excluir em grupo próprio, ao fim, com confirmação |
| 89 | **App BR** | FE | PT-BR na superfície; sem tradução EN/ES ativa |
| 90 | **Chevron ⟺ rota** | FE | Nenhum chevron em ação transacional; nenhum botão para navegação simples (§10) |
| 91 | **Orçamento de destaque** | FE | 1 P0, ≤2 P1, ≤1 `emphasize`, ≤3 sinais por linha (§11–§12) |
| 92 | **Proposta de backend entregue** | FE+BE | Bloco de §22 presente no scorecard, mesmo quando vazio |

---

# Parte VI — Execução

## 28. Playbook de implementação em massa

Objetivo: **paridade operacional + pele deste arquivo + anatomia do tipo certo**.

### 28.0 Ruflo no Cursor

O playbook deste capítulo vive no skill do repo (`.cursor/skills/ruflo/SKILL.md`). No Desktop:

1. Abrir o `focux-app` e um chat **Agent** novo.
2. Digitar `/ruflo` e confirmar com **Alt+Enter** (Windows/Linux) ou **Option+Enter** (Mac), ou **Use as Mode**. O badge fica no input até sair do modo.
3. Escolher o modelo no picker do chat. O skill não trava modelo.
4. Pedir o lote (primeiro: S6, no máximo 3 telas). O Ruflo lê este arquivo e `docs/CONTRATO_APP_BACKEND.md`; não precisa colar o playbook.

A rule `.cursor/rules/focux-design.mdc` entra sozinha em arquivos `*.dart` mesmo sem o modo. User Rules da conta **não** devem carregar esta referência (estoura contexto e vaza para outros projetos).

### 28.1 Fase 0 — inventário (antes de qualquer edição)

Entregável único, sem tocar em código: **planilha de rotas**, uma linha por destino navegável.

| Coluna | Conteúdo |
|---|---|
| Rota | Path no GoRouter |
| Tela | Widget raiz |
| Tipo | S1…S9 |
| Estrutura atual | O que está lá hoje (ex.: "inset-grouped") |
| Divergência | Anti-padrão identificado (§31) |
| P0 atual / correto | Qual é a ação primária e como está tratada |
| Endpoint(s) | Caminho de dados |
| Lote | Agrupamento de execução |

Nada de "editar no escuro": se houver dúvida sobre qual tela é, listar candidatas e perguntar.

### 28.2 Fase 1 — extração para core

Antes de cada lote, **extrair para `lib/core/widgets/`** o padrão que vai se repetir naquele tipo. É isto que evita centenas de edições divergentes: a tela nova compõe, não recria.

Candidatos prováveis por tipo: barra sticky de ação (S3), footer de formulário (S5), lockup de conversão (S6), header de execução (S8), passo de wizard (S9). Se o padrão ainda não é widget, ele nasce widget **antes** de ser colado na segunda tela.

### 28.3 Fase 2 — lotes por tipo, não por pasta

Consistência intra-tipo é o que faz o app parecer desenhado. Ordem sugerida por impacto.

> **Vigente:** a matriz de §22.6.3 está liberada. A ordem desta tabela volta a valer. `double` em dinheiro e paginação B/C não bloqueiam.

| Ordem | Lote | Por quê |
|---|---|---|
| 1 | **S6** conversão | Maior dano hoje (CTA como linha); menor superfície; impacto direto em receita |
| 2 | **S1** hubs | Definem a percepção de produto |
| 3 | **S3** detalhes | Onde o personal passa o dia |
| 4 | **S4** listas | Busca, filtro e paginação |
| 5 | **S5** formulários | Volume alto, padrão fechado |
| 6 | **S8** execução | Poucas telas, ganho alto de foco |
| 7 | **S9** wizard | Depende de S5 pronto |
| 8 | **S7** sheets | Varredura de conformidade |
| 9 | **S2** ajustes | Já está no padrão; só auditar limites de §11 |

### 28.4 Ritmo (agilidade sem dívida)

1. **Uma tela — ou um lote homogêneo de até 3 telas do mesmo tipo — por PR.** Não misturar tipos no mesmo PR.
2. **Identificar FE + BE antes de editar:** widget, provider, rota, endpoint(s).
3. **Copiar padrão, não copiar arquivo.** Reusar tokens, sheets, estados, tipografia.
4. **Diff mínimo, estruturalmente correto.** Corrigir a causa; não espalhar magic numbers nem duplicar microcopy.
5. **Não misturar** refactor amplo + feature nova + upgrade visual no mesmo commit.
6. **Limpar o fold antigo no mesmo ship** (§30).
7. **Scorecard no chat**, no formato de §33. Sem Canvas, sem `.md` novo, sem "10/10" no subject do git.
8. **Checagens reais** quando houver terminal: `flutter analyze --fatal-warnings --fatal-infos`, testes da feature, e no BE `./gradlew test` do módulo tocado. Não pontuar 69–79 de memória.
9. **Bloco de proposta de backend obrigatório** em todo PR (§22), mesmo vazio.
10. Chats de bugfix/git/limpeza **não** reabrem o playbook inteiro — só o pedaço que o bug toca.

### 28.5 Definição de pronto por tela

- [ ] Tipo declarado e esqueleto conforme §9
- [ ] Assinatura Focux completa (§2)
- [ ] Componentes escolhidos pela matriz de intenção (§10)
- [ ] Orçamento de destaque respeitado (§11) e densidade dentro dos limites (§12)
- [ ] Quatro estados implementados (§13)
- [ ] Regras de §16–§21 verificadas
- [ ] Bloco de proposta de backend entregue (§22)
- [ ] Mortos removidos (§30)
- [ ] Analyze + testes do caminho tocado passaram
- [ ] Scorecard + "Precisa da sua decisão" (pode ser vazio)

## 29. O que pode aplicar sozinho vs. o que só propor

Espelha a regra Cursor `focux-10-10`. Na dúvida: **propor**, nunca auto-aplicar.

| Pode editar direto | Só propor e esperar aprovação |
|---|---|
| Visual, UX, tipografia, densidade, a11y, motion, navegação de UI, sheets, empty/loading/erro, performance **client-side**, SRP/limpeza que **não** muda contrato nem regra | Regra de negócio, IA, gates de plano, PII, auth/sessão, tenant/RLS, LGPD, auditoria, secrets, rate limit, contrato API/BFF, cache **server**, validação de domínio, idempotência, paginação BE, Flyway, observabilidade BE, testes de contrato, telemetria de produto |
| Pilares típicos: 1–2, 4, 6–8, 13–51, 69–72, 74, 76, 78–80, 81–91 | Pilares típicos: 3, 9, 11, 52–68, 73, 75, 77, 92 |

**Nunca editar sozinho:** auth, tenant, pagamento, migration, RLS, endpoint novo sem contrato.

## 30. Limpeza de mortos

O fold novo **não** convive com o antigo. Depois de implementar, no mesmo ship, antes do scorecard:

1. Apagar campos, `GlobalKey`, flags, métodos e `part`s que só existiam para o layout anterior.
2. Grep do símbolo no app: se **nenhuma outra rota** chama, apagar o arquivo — não deixar "por precaução".
3. Se outra tela ainda usa, extrair para o domínio dela; não manter morto no hub elevado.
4. Reescrever testes que afirmavam o fold antigo **no mesmo commit**.
5. Só então `flutter analyze --fatal-warnings --fatal-infos` — tem que falhar se sobrou `unused_*`.

Não vale "limpa no próximo PR". Campo morto no State depois de um redesign é regressão do pilar 72.

## 31. Anti-padrões

Catálogo de defeitos. Cada um tem nome para poder ser citado em revisão.

| Cód. | Nome | Sintoma | Correção |
|---|---|---|---|
| **A1** | Tela-perfil | Inset-grouped como estrutura fora de S2 | Aplicar o esqueleto do tipo real (§9) |
| **A2** | CTA com chevron | `Entrar >`, `Salvar >`, `Assinar >` como linha | `FxLiquidPrimaryButton` (§10) |
| **A3** | Muro de repetição | 3+ linhas com o mesmo chip de status | Agregar em 1 resumo com contagem (§12.1) |
| **A4** | Tela plana | Nenhum elemento dominante | Definir 1 P0 no tratamento do tipo (pilar 4) |
| **A5** | Dois primários | Dois botões com glow competindo | Rebaixar um a `FxLiquidSecondaryButton` |
| **A6** | Número órfão | Métrica sem unidade nem contexto | Unidade/rótulo no mesmo bloco (pilar 40) |
| **A7** | Full-width fora de lugar | CTA full-width em hub ou ajustes | Chip in-card (§11) |
| **A8** | Tema emprestado | Botão branco sobre preto, azul iOS, hero invertido | Mesh + glass + teal (§2) |
| **A9** | KPI em ajustes | Card de métrica dentro de S2 | Mover para S1/S3 |
| **A10** | Picker com chevron | Escolha de valor exibindo chevron | Check teal em `FxInsetPickerOption` |
| **A11** | Stack na tela | `showError(context, '$e')` | `friendlyError` / `FxAsyncBody` |
| **A12** | Regra no widget | `if (plano == 'FREE')` na UI | `effectivePlanoFeatures` / capability |
| **A13** | Sheet sem altura | `Flexible`/`Expanded` em `Column(min)` sem cap | `expand: true` + `Expanded(ListView)` |
| **A14** | Mundo no cliente | FE busca tudo para filtrar/paginar | Paginação e filtro no BE (proposta §22) |
| **A15** | SSOT duplo | Provider refetcha o que o agregado já traz | Consumir o agregado |
| **A16** | Morto convivendo | Fold antigo mantido "por precaução" | §30 no mesmo ship |
| **A17** | Chip como submit | Chip de hub usado para enviar formulário | Footer sticky full-width (S5) |
| **A18** | Execução poluída | Timer com listas, badges e notificações | S8: um alvo dominante |
| **A19** | Wizard sobrecarregado | Várias decisões numa etapa | Uma pergunta por etapa (S9) |
| **A20** | Ajuda enterrada | Linha "Ajuda" no meio da lista | `FxHelpIconButton` na app bar |

## 32. Gates verificáveis

O que a v1 tinha de melhor era ter transformado segurança em teste (`security_pillar_contract_test.dart`). A v2 propõe o mesmo para a taxonomia — regra que não é testada volta a ser violada em escala.

**Vigente:**

| Gate | Arquivo |
|---|---|
| Contrato de segurança dos hubs | `test/core/design_system/security_pillar_contract_test.dart` |
| Catálogo de segurança | `test/core/security/focux_security_test.dart` |
| Hardening de plataforma | `test/core/security/platform_hardening_test.dart` |
| Analyze | `flutter analyze --fatal-warnings --fatal-infos` |

**Proposto (implementar no Fase 1 do playbook, não agora):**

| Gate | Onde | O que afirma |
|---|---|---|
| `FocuxSurfaces` — catálogo de superfícies | `lib/core/design_system/focux_surfaces.dart` | Mapa rota → tipo S1–S9, espelhando o padrão de `FocuxSecurity.coreSources` |
| `surface_taxonomy_contract_test.dart` | `test/core/design_system/` | Toda rota do router está classificada; nenhuma rota sem tipo |
| Regra "inset só em S2" | idem | Telas S1/S3/S4/S6/S8/S9 não usam `FxSettingsGroup` como raiz do body |
| Regra "chevron ⟺ rota" | idem | Rótulo de `FxSettingsTile` não casa com verbo transacional (`entrar`, `salvar`, `pagar`, `assinar`, `iniciar`, `confirmar`, `enviar`) |
| Regra "1 P0" | idem | No máximo 1 `FxLiquidPrimaryButton` por árvore de tela |
| Regra "sem CTA full-width em S1/S2" | idem | S1/S2 não instanciam `FxLiquidPrimaryButton` |
| Regra "S6 tem primário" | idem | Toda rota de `buildAuthRoutes` instancia exatamente 1 `FxLiquidPrimaryButton` |

Um gate de source-contract (leitura do arquivo + regex, como os testes de segurança já fazem) é suficiente e barato — não precisa de golden test.

## 33. Scorecard e checklist de ship

Formato do relatório de cada tela, entregue no chat.

### 33.1 Cabeçalho

```
# <Rota> — <nome da tela>
Tipo de superfície: S<#> (<nome>)
Job: <uma frase>
P0: <ação primária e tratamento>
Estados: loading / vazio / erro / freshness — <ok | o que falta>
Endpoints: <lista>
Mortos removidos: <lista>
Checagens: analyze <ok|falhou> · testes <quais>
```

### 33.2 Tabela de pilares

Colunas: `#` · `Pilar` · `Cat` · `Lado` · `FE` · `BE` · `Nota` · `Meta` · `Evidência`.
Meta é sempre 10. `N/A` quando o pilar não se aplica à tela — com justificativa na evidência.
Fechar com: **Nota geral (pilares com nota, N/A fora): X/10.**

### 33.3 Blocos finais

1. **Proposta de backend** — template de §22.2, obrigatório.
2. **Precisa da sua decisão** — lista de escolhas que dependem do dono do produto (pode ser vazia).

### 33.4 Checklist rápido antes do ship

- [ ] Tipo de superfície declarado; job da rota claro; chrome/dock no shell certo
- [ ] Esqueleto do tipo respeitado; nenhum anti-padrão de §31
- [ ] 1 P0 no tratamento do tipo; ≤2 P1; ≤1 `emphasize` por viewport
- [ ] Densidade dentro de §12 (≤3 sinais/linha; agregação a partir de 3 repetições)
- [ ] Loading / vazio / erro / retry / freshness
- [ ] Tokens, tipografia, sheets e toque 48dp — sem paleta paralela
- [ ] Dark e light verificados
- [ ] Sem provider duplicado do agregado; parse tipado na borda
- [ ] Sem PII extra; tenant não veio do cliente; erros com `friendlyError` (sem `$e`)
- [ ] Hub passa `security_pillar_contract_test` se estiver na lista de hubs
- [ ] Lista longa = builder + paginação no BE; sheet = altura limitada + teclado
- [ ] Sem `Flexible` unbounded; sem overflow com teclado/landscape
- [ ] Nada de auth/pagamento/migration/IA autoaplicada neste diff
- [ ] Fold antigo limpo; testes do fold velho atualizados
- [ ] Analyze + testes do caminho tocado passaram
- [ ] Scorecard + proposta de backend + "Precisa da sua decisão"

## 34. Catálogo de componentes

Preferir estes; extrair para core antes de duplicar (pilar 70).

### Estrutura e chrome

| Símbolo | Caminho |
|---|---|
| `FxShellScaffold`, `FxShellAppBar`, `ShellSurface`, `FxSatellitePanel`, `FxSatelliteListTile` | `lib/core/widgets/fx_shell_scaffold.dart` |
| `fxListCardDecoration`, `fxListTileCardShell`, `fxStripCardDecoration`, `fxScreenInk`, `fxScreenMute` | idem |
| `ShellChrome` | `lib/core/theme/shell_chrome.dart` |
| `CinematicMeshBackground`, `MeshScope` | `lib/core/widgets/cinematic_mesh_background.dart`, `mesh_scope.dart` |
| `FxGlassSurface`, `FxStripCard`, `FxHubHeader` | `lib/core/widgets/fx_glass_surface.dart`, `fx_strip_card.dart`, `fx_hub_header.dart` |
| `FxContentWidthLimiter` | `lib/core/widgets/fx_content_width_limiter.dart` |
| `FxRouteChrome`, `FxDock`, `FxDockItems` | `lib/core/widgets/fx_route_chrome.dart`, `fx_dock.dart` |
| `FocuxSystemChrome` | `lib/core/theme/focux_system_chrome.dart` |

### Tokens e tipografia

| Símbolo | Caminho |
|---|---|
| `TokensStrip` | `lib/core/theme/tokens_strip.dart` |
| `FxSettingsLayout` | `lib/core/theme/fx_settings_layout.dart` |
| `FocuxHubTypography`, `AppTypography`, `FocuxTypography` | `lib/core/theme/` |
| `BrandPalette`, `EagleTokens` | `lib/core/theme/brand_palette.dart`, `design_tokens.dart` |
| `DashboardLayout` | `lib/features/dashboard/constants/dashboard_layout.dart` |

### Ação e entrada

| Símbolo | Caminho |
|---|---|
| `FxLiquidPrimaryButton`, `FxLiquidSecondaryButton`, `FxSpringButton`, `FxStaggerItem`, `FxInteractiveGlow` | `lib/core/widgets/fx_motion.dart` |
| `FxPremiumEntrance` | `lib/core/widgets/fx_premium_entrance.dart` |
| `FxInputDeco` | `lib/core/widgets/fx_input_deco.dart` |
| `FxToggleChip` | `lib/core/widgets/fx_toggle_chip.dart` |
| `FxIcon` | `lib/core/widgets/fx_icon.dart` |
| `AlunoSegmentedChoice` (2–4 opções inline) | `lib/features/alunos/widgets/aluno_form_choices.dart` |
| `PerfilStickyBar` (chip sticky de pendência, modelo de S2) | `lib/features/perfil/widgets/perfil_sticky_bar.dart` |

### Listas inset e picker

| Símbolo | Caminho |
|---|---|
| `FxSettingsGroup`, `FxSettingsGroupedList`, `FxSettingsTile` | `lib/core/widgets/fx_settings_group.dart`, `fx_settings_grouped_list.dart`, `fx_settings_tile.dart` |
| `showFxInsetPickerSheet`, `FxInsetPickerSheetItem` | `lib/core/widgets/fx_inset_picker_sheet.dart` |
| `FxInsetPickerOption`, `FxInsetPickerOptionSpec` | `lib/core/widgets/fx_inset_picker_option.dart` |
| `FxInsetPickerRow` | `lib/core/widgets/fx_inset_picker_row.dart` |

### Sheets, estados e feedback

| Símbolo | Caminho |
|---|---|
| `showFxHomeSheet`, `FxHomeSheetSurface`, `FxHomeSheetHandle`, `FxHomeSheetHeader`, `FxHomeSheetScaffold`, `FxHomeSheetChrome` | `lib/core/widgets/fx_home_sheet.dart` |
| `showFxConfirmSheet` | `lib/core/widgets/fx_confirm_sheet.dart` |
| `showFxFormSheet`, `showFxNoticeSheet` | `lib/core/widgets/fx_form_sheet.dart` |
| `showFxBottomSheet` | `lib/core/widgets/fx_bottom_sheet.dart` |
| `FxAsyncBody` | `lib/core/widgets/fx_async_body.dart` |
| `FxEmptyState`, `FxEmptyAction` | `lib/core/widgets/fx_empty_state.dart` |
| `FxErrorState` | `lib/core/widgets/fx_error_state.dart` |
| `FxLoading`, `SkeletonLoader`/`SkeletonList`, `ShimmerListLoading` | `lib/core/widgets/fx_loading.dart`, `skeleton_loader.dart`, `loading_shimmer.dart` |
| `FeedbackHelper`, `FocuxFeedback` | `lib/core/widgets/feedback_helper.dart`, `lib/core/ux/focux_feedback.dart` |
| `FxConnectivityBanner` | `lib/core/widgets/fx_connectivity_banner.dart` |
| `FxHelpIconButton`, `showFxHelpSheet`, `FxHelpTipRow`, `FxHelpChrome` | `lib/core/widgets/fx_help.dart` |
| `FxCelebrationOverlay`, `FxConfettiBurst`, `FxRivePlayer` | `lib/core/widgets/fx_celebration_overlay.dart`, `fx_confetti_burst.dart`, `fx_rive_player.dart` |

### Dados e métricas

| Símbolo | Caminho |
|---|---|
| `FxSparkline` | `lib/core/widgets/fx_sparkline.dart` |
| `OperationalMetricTile` | `lib/core/widgets/operational_metric_tile.dart` |
| `FxHorizontalScrollPeek` | `lib/core/widgets/fx_horizontal_scroll_peek.dart` |
| `FxPlanLockBadge`, `FxPlanLockTrailing` | `lib/core/widgets/fx_plan_lock_badge.dart` |
| `effectivePlanoFeatures` | `lib/features/planos/utils/effective_plano_features.dart` |
| `UpgradePromptSheet` | `lib/features/subscription/widgets/upgrade_prompt_sheet.dart` |
| `FeatureGate` | `lib/core/widgets/feature_gate.dart` |

### Marca

| Símbolo | Caminho |
|---|---|
| `FocuxOfficialLogo`, `FocuxBrandTagline`, `BrandedAppIcon` | `lib/core/widgets/focux_official_logo.dart`, `focux_brand_tagline.dart`, `branded_app_identity.dart` |
| `FocuxBranding`, `FocuxBrandCopy`, `FocuxMicrocopy` | `lib/core/brand/` |

### Domínio Hoje (reusar só em outro S1)

| Símbolo | Caminho |
|---|---|
| `DashboardDayFocusBanner` | `lib/features/dashboard/widgets/dashboard_day_focus_banner.dart` |
| `DashboardHomeHeader` | `lib/features/dashboard/widgets/dashboard_home_header.dart` |
| `DashboardCommandCenterSection`, `showCommandActionsSheet` | `lib/features/dashboard/widgets/dashboard_command_center_section.dart` |
| `CommandActionTile`, `CommandActionPanel`, `CommandStatusTile`, `CommandPrioritiesSheet` | `lib/features/dashboard/widgets/command_*.dart` |
| `DashboardPrioritiesOverlay` | `lib/features/dashboard/widgets/dashboard_command_center_sticky_header.dart` |
| `DashboardSectionHeader`, `DashboardHomeSecondaryBlock` | `lib/features/dashboard/widgets/` |
| `DashboardAttentionRail`, `DashboardAgendaHojeStrip`, `DashboardDayPulseStrip`, `DashboardBaseRadarStrip` | `lib/features/dashboard/widgets/` |
| `DashboardHomeActionChip`, `DashboardHomeActivationStrip`, `DashboardHomeCoachBanner` | `lib/features/dashboard/widgets/` |
| `DashboardShimmerLoading`, `DashboardErrorState`, `DashboardFinanceEmptyState` | `lib/features/dashboard/widgets/` |
| `showDashboardToolsCatalogSheet`, `showDashboardQuickSearchSheet`, `showDashboardHomeHelpSheet`, `showDashboardRadarSheet` | `lib/features/dashboard/widgets/` |
| `DashboardHomeClientCache`, `DashboardMicrocopy`, `buildDashboardNextActions`, `DashboardHomeFocusRules`, `DashboardDayFocus` | `lib/features/dashboard/utils/` |
| `DashboardActivationCta` | `lib/features/subscription/widgets/dashboard_activation_cta.dart` |
| `NotificacaoBadgeButton` | `lib/features/notificacoes/widgets/notificacao_badge_button.dart` |

### Segurança (app-wide — usar em todo hub)

| Símbolo | Caminho |
|---|---|
| `FocuxSecurity` (catálogo) | `lib/core/security/focux_security.dart` |
| `SecureStorage` | `lib/core/storage/secure_storage.dart` |
| `TlsCertificatePinning` | `lib/core/api/tls_certificate_pinning.dart` |
| `friendlyError` | `lib/core/utils/friendly_error.dart` |
| `copySensitiveToClipboard` | `lib/core/utils/clipboard_sensitive.dart` |
| `IaSafetyDisclaimer` | `lib/core/widgets/ia_safety_disclaimer.dart` |
| `SubscriptionDeviceGuard` | `lib/features/assinatura/services/subscription_device_guard.dart` |
| Hardening Android (catálogo) | `FocuxSecurity.androidHardeningSources` |

### Utilitários

| Símbolo | Caminho |
|---|---|
| `fxScreenA11yScope` | `lib/core/widgets/fx_screen_a11y.dart` |
| `fxAnnounce`, `fxAnnounceGlobal` | `lib/core/utils/a11y_announce.dart` |
| `fxMotionDuration`, `fxMotionDurationMs` | `lib/core/utils/motion_preferences.dart` |
| `fxTitleCaseName`, `fxInitials`, `fxTimeAgo`, `fxDateFull`, `fxDateShort`, `fxMonthYear` | `lib/core/utils/fx_utils.dart` |
| `BrPhone` | `lib/core/utils/br_phone.dart` |
| `FxHubFreshness` | `lib/core/ux/fx_hub_freshness.dart` |
| `fxTransitionPage` | `lib/core/router/fx_page_transition.dart` |

## 35. Padrões de detalhe

### 35.1 Picker inset (seleção única em sheet)

Padrão **global** para escolher **um** valor em bottom sheet (tema, nível, taxonomia, ordenação, filtro enum). Não reinventar `InkWell` + `Icons.check`.

**Quando usar:**

| Situação | Componente |
|---|---|
| Lista em sheet, **1 opção** | `showFxInsetPickerSheet` ou `FxInsetPickerOption` + `FxSettingsGroup(edgeToEdgeRows: true)` |
| Lista com **busca** (muitos itens) | `FxInsetPickerOption.list` + campo de busca acima |
| **Multi-seleção** | `FxToggleChip` em grid/wrap — não é picker de lista |
| **2–4 opções fixas** em formulário | `AlunoSegmentedChoice` / chips inline |
| **Navegar** para outra tela | `FxSettingsTile` com chevron |
| **Executar** transação | `FxLiquidPrimaryButton` — **nunca** linha de picker nem chevron |

**Contrato visual:**

1. **Chrome:** `showFxHomeSheet` → `FxHomeSheetSurface` → `FxHomeSheetHandle` + `FxHomeSheetHeader` (título + subtítulo de contexto).
2. **Grupo:** `FxSettingsGroup(accent: primary, edgeToEdgeRows: true)` — sem padding interno; `ClipRRect` no card.
3. **Linha:** `FxInsetPickerOption` — altura mínima `rowMinHeight` (52), padding horizontal `groupPadH` (16).
4. **Selecionado:** fundo `accent` a 10% (light) / 16% (dark) **de borda a borda**; label em bold + `Icons.check_rounded` teal à direita; cantos arredondados no primeiro e no último item.
5. **Ícone opcional** à esquerda (22, cor da marca); **subtítulo opcional** (`bodyMuted`).
6. **Haptic:** `HapticFeedback.selectionClick()` no tap — já dentro do widget, não duplicar no caller.
7. **Proibido:** `BoxDecoration` manual com `alpha: 0.08` dentro de grupo com padding — gera highlight quebrado.

**Exemplo mínimo:**

```dart
final picked = await showFxInsetPickerSheet<ThemeMode>(
  context,
  title: 'Aparência',
  headerIcon: Icons.dark_mode_outlined,
  selected: current,
  items: [
    FxInsetPickerSheetItem(value: ThemeMode.system, label: 'Sistema'),
    FxInsetPickerSheetItem(value: ThemeMode.light, label: 'Claro'),
    FxInsetPickerSheetItem(value: ThemeMode.dark, label: 'Escuro'),
  ],
);
```

Lista com ícone/subtítulo em grupo (sheet que não fecha no tap — ex.: status em lote):

```dart
FxSettingsGroup(
  header: 'Ordenação',
  edgeToEdgeRows: true,
  accent: primary,
  children: FxInsetPickerOption.list(
    accent: soft,
    items: [
      FxInsetPickerOptionSpec(
        label: 'Nome A-Z',
        subtitle: 'Ordem alfabética.',
        icon: Icons.sort_by_alpha_rounded,
        selected: ordenacao == AlunoOrdenacao.nome,
        onTap: () => _setOrdenacao(AlunoOrdenacao.nome),
      ),
    ],
  ),
)
```

### 35.2 Grupo inset como container de campos (S5)

Em formulário, o grupo inset é **correto** — ele agrupa campos relacionados, não navegação:

- `FxSettingsGroup(header: 'Contato', footer: 'Usamos o WhatsApp para avisar o aluno.')`
- Campos com `FxInputDeco`; slot de prefixo `insetPrefixWidth` (48) para paridade com as linhas.
- Escolha inline via `FxInsetPickerRow` (abre picker, mostra o valor — sem chevron).
- Erro de validação inline, sob o campo, em `EagleTokens.bad`.
- **O submit nunca é uma linha do grupo.** Ele é o botão full-width do footer sticky.

### 35.3 Barra sticky de ação (S3)

- Fixa na base, sobre a superfície, com blur (`TokensStrip.blurLight`) e borda superior `chrome.line`.
- Um `FxLiquidPrimaryButton` + no máximo dois ícones/links secundários.
- Respeita `SafeArea` inferior e recolhe com o teclado.
- Nunca dois níveis de sticky simultâneos (barra + chip).

---

# Apêndices

## A. Registro de auditoria: hub Perfil

Auditoria concluída em 2026-08-25 sobre `/perfil` + `/perfil/ferramentas` — **nota geral 10/10** nos pilares com nota (N/A fora). Preservado como registro histórico e como exemplo de scorecard preenchido. Os `N/A` refletem o escopo daquela tela, não uma dispensa geral.

> ### Ressalva após a auditoria do backend (2026-09-02)
>
> Este scorecard foi levantado **a partir da tela**. A varredura de `focux-backend` contradiz três linhas, que ficam registradas aqui em vez de serem reescritas — o histórico se preserva, mas não pode induzir a erro:
>
> | # | Nota registrada | O que a auditoria do backend mostrou |
> |---|---|---|
> | 54 | 10 — "`TenantContext`; sem `personalId` do cliente" | A metade verificável pela tela está correta: **nenhum** endpoint aceita tenant do cliente. Mas **não existe política de RLS por tenant** — só `USING(false)` para `anon`/`authenticated`, que não cobre o papel da aplicação. O isolamento entre personais depende inteiramente do filtro na camada de aplicação, sem rede no banco. Além disso, a autorização **dentro** do tenant tem escalonamento de privilégio, e o RBAC de equipe está aplicado em 6 de 64 módulos. Nota real: bem abaixo de 10 |
> | 63 | 10 — "`@Valid` + `FocuxException`" | Verdadeiro no escopo do Perfil, mas o critério elevado ("código de erro que o FE traduz em copy específica") falha globalmente: **2 códigos de erro para 623 lançamentos** |
> | 11 | 10 — "`verificarAcesso`; contrato intacto" | Verdadeiro nesta tela; falso no produto: **5 pontos de entrada sem gate de plano**, incluindo feature ENTERPRISE liberada para FREE/PRO |
>
> **Lição de método:** pilar de backend avaliado só pela superfície produz nota inflada. Os pilares 52–68 exigem o repositório do backend aberto — é exatamente o que §22.5 passa a exigir.

| # | Pilar | Nota | Evidência |
|---|---|---|---|
| 1 | Produtividade operacional | 10 | Conta / marca / operação em poucos toques |
| 2 | Rota & job | 10 | Hub único; Ferramentas em rota própria |
| 3 | Lógica & regras | 10 | FE ∪ API `readinessMissing` (`PersonalReadiness`) |
| 4 | Hierarquia de decisão | 10 | Sticky `Completar`/`Hoje` + Planos em destaque teal |
| 5 | Valor aluno | 10 | `%` + `readinessPercent` visíveis |
| 6 | Descoberta | 10 | Caption + long-press em Marca |
| 7 | First-run | 10 | Grupo de prontidão só quando incompleto |
| 8 | White-label | 10 | `corPrimaria` via `BrandPalette` em ícones e avatar |
| 9 | IA assistiva | N/A | Sem IA nesta tela |
| 10 | Transparência | 10 | Hint "como calculamos" + payload BE |
| 11 | Gates de plano | 10 | `verificarAcesso`; tile `locked`; contrato intacto |
| 12 | Unread | N/A | Sem unread |
| 13 | Time-to-value | 10 | Hero + 1º grupo sem scroll extra |
| 14 | Identidade visual | 10 | Mesh/glass/teal; não copia o preto do ChatGPT |
| 15 | Tipografia | 10 | Papéis de `FocuxHubTypography`; sem Inter 17 ad-hoc |
| 16 | Espaçamento | 10 | `FxSettingsLayout` 16/24/52/20 |
| 17 | Contraste | 10 | Labels `ink`; ícone teal sobre chrome |
| 18 | Dark/light | 10 | `cardFill` e avatar ring via `ShellChrome` |
| 19 | Hierarquia visual | 10 | Nome = headline; linhas = `cardTitle` |
| 20 | Design system | 10 | `FxSettings*` em core |
| 21 | Densidade | 10 | Linha 52; sem KPI card; sem preview LIVE |
| 22 | Gestalt | 10 | Grupos + Sair isolado |
| 23 | Branding | 10 | Ícones outline 22 na marca |
| 24 | Data viz | N/A | Sem gráfico |
| 25 | Empty | 10 | Linha "criar link público" como CTA |
| 26 | Loading | 10 | Skeleton em Ferramentas |
| 27 | Erro/retry | 10 | `FxErrorState` + retry |
| 28 | Freshness | 10 | Subtítulo da app bar |
| 29 | Microcopy | 10 | Labels de ajuste, sem jargão |
| 30 | Feedback | 10 | Chevron/check + `selectionClick` |
| 31 | Search | N/A | Lista curta |
| 32 | Forms | 10 | `showFxFormSheet` (excluir conta) |
| 33 | Touch/haptics | 10 | Linha 52 ≥ 48dp |
| 34 | Gestos | 10 | Back do shell; `safePopOrGo` |
| 35 | Responsivo | 10 | `constrainWidth` + inset 16 |
| 36 | Thumb zone | 10 | `PerfilStickyBar` na base |
| 37 | Motion | 10 | `FxStaggerItem` + reduced motion |
| 38 | A11y | 10 | Semantics nas linhas; hint no destrutivo |
| 39 | i18n | 10 | PT-BR; `Locale('pt')`; sem EN/ES na UI |
| 40 | Clareza | 10 | Plano e score com unidade |
| 41 | Atenção | 10 | Hero limpo; sem pills de Marca/Plano |
| 42 | IA nav | 10 | `/perfil` no shell Personal |
| 43 | Deep links | 10 | Push para wallet/planos/etc. |
| 44 | Back stack | 10 | Ferramentas → Perfil previsível |
| 45 | Sheets | 10 | `showFxHomeSheet` / `FxHomeSheetSurface`; picker com linha 52 |
| 46 | TTI | 10 | Scaffold de loading; sem tela branca |
| 47 | Scroll | 10 | `CustomScrollView`; sem preview pesado |
| 48 | Rede | 10 | GET perfil 60/min; `friendlyError` |
| 49 | Cache client | 10 | TTL 90s; invalidate no refresh |
| 50 | Cold start | 10 | Foto lazy; sem card LIVE |
| 51 | Estabilidade | 10 | Null-safe; `fatal-infos` no escopo |
| 52 | PII na UI | 10 | WhatsApp só se cadastro incompleto |
| 53 | Auth/sessão | 10 | Logout 204; teste revoga refresh |
| 54 | Tenant/RLS | 10 | `TenantContext`; sem `personalId` do cliente |
| 55 | LGPD | 10 | `DELETE /api/lgpd/me`; contrato inalterado |
| 56 | Auditoria | 10 | `PERFIL_UPDATE`; wallet e identidade também |
| 57 | Secrets | 10 | Sem secret; `Env`; pins=false só em sideload |
| 58 | Rate limit | 10 | `@RateLimit` em perfil/planos/public |
| 59 | Contrato API | 10 | Springdoc no path crítico perfil + delete |
| 60 | SSOT | 10 | Evict da home no write |
| 61 | N+1 | 10 | `findById`; plano EAGER no Personal |
| 62 | Cache server | 10 | Perfil e wallet invalidam home |
| 63 | Validação domínio | 10 | `@Valid` + `FocuxException` (telefone/PIX) |
| 64 | Idempotência | 10 | Refresh já revogado → 401 |
| 65 | Paginação BE | N/A | Sem lista paginada |
| 66 | Flyway | N/A | Sem mudança de schema |
| 67 | Observabilidade | 10 | Timer `focux.personal.perfil` (p95) |
| 68 | OpenAPI | 10 | `@Operation` no gate crítico |
| 69 | SRP | 10 | Layout separado da pele; utils/widgets |
| 70 | Composição | 10 | Ferramentas reusa o tile |
| 71 | Tipagem | 10 | Borda tipada; records no BE |
| 72 | Dead code | 10 | Grep + compile no mesmo ship |
| 73 | Testes regra | 10 | FE (labels/tokens) + BE (`ReadinessTest`) |
| 74 | Testes UI | 10 | `perfil_screen_contract_test` |
| 75 | Contrato API test | 10 | PUT + LGPD HTTP; paths no OpenAPI |
| 76 | A11y testes | 10 | Source contract de semantics |
| 77 | Telemetria | 10 | view/share/sticky + Micrometer |
| 78 | Flags | N/A | Fold visual |
| 79 | CI/analyze | 10 | FE + BE passaram |
| 80 | Help na superfície | 10 | Caption + long-press em Marca |

**Extras da v1 (hoje pilares 81–92):** fold inset (81), paridade tipográfica (82), ícones da marca (83), sem CTA invertido (84), sem tema ChatGPT (85), limpeza no mesmo ship (86), picker Aparência (87), Sair isolado (88), app BR (89) — todos 10.

**Precisa da sua decisão:** vazio à época — tema, CTA, sticky chip, LGPD/gates e i18n PT-BR já decididos.

**Reclassificação v2:** `/perfil` e `/perfil/ferramentas` são **S2**. A auditoria segue válida. O que mudou é o alcance: o esqueleto desta tela **não** é o esqueleto padrão do app.

## B. Mortos: não reintroduzir

**Fold Perfil (removidos):** `perfil_action_tile`, `perfil_card_section`, `perfil_quiet_collapsible`, `_HeroMarcaChip`, `_PlanPill`, `_BrandPreview`, `_PerfilPublicLinkCard`, `perfilPlanSectionLabel`.

**Picker:** `_AlunosSheetCheckRow` e rows custom com `InkWell` + `Icons.check` em sheets de seleção. Highlight de seleção recuado dentro de `FxSettingsGroup` sem `edgeToEdgeRows`.

**Padrões proibidos (§31):** CTA com chevron (A2), inset-grouped fora de S2 (A1), CTA full-width em hub/ajustes (A7), botão branco sobre preto (A8), `showError(context, '$e')` (A11), `if (plano == 'FREE')` em widget (A12).

**Regra geral:** ao remover, remover de verdade — arquivo, campos, testes do fold antigo, no mesmo commit (§30).
