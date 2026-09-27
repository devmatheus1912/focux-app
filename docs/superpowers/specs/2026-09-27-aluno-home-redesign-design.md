# Aluno — Home "Hoje" redesenhada (spec 3 de 4)

Data: 2026-09-27 · Repos: `focux-app` (principal), `focux-backend` (1 campo aditivo).
Base: auditoria da Home do aluno (27/09, 25 achados) e
`docs/FOCUX_STUDENT_EXPERIENCE_AUDIT.md` §14–§17. Spec anterior:
`2026-09-25-aluno-dados-insights-design.md` (partes 1 e 2, entregues).

Referência de design: `docs/FOCUX_DESIGN_REFERENCE.md` §9 (S1), §11 (orçamento
de destaque), §12 (densidade), §13 (estados), §37.5 (Home aluno: "o que fazer
hoje, 1 P0, sem catálogo de módulos no fold"). System design:
`docs/system/04-api.md` (contrato aditivo), `05-cache.md` (Caffeine 60s + ETag).

## Decisões aprovadas

| Tema | Decisão |
|---|---|
| Escopo | Só a Home. Tela de Evolução vira spec 3b |
| Ritmo e meta | Servidor é a fonte. Sai o score local do app |
| Bloco "Evolução detectada" | Removido (o insight de força cobre) |
| Ofertas de upsell | Abaixo do progresso do aluno |
| Central do aluno | Bloco "Pendências" com até 3 itens, sem repetir o P0, sem porcentagem |
| Marca do personal | Linha no cabeçalho com logo pequeno e nome; toque abre o chat |
| Nome da tela | "Hoje", igual ao dock, com "Olá, {primeiro nome}" |
| Idiomas | Todo texto da Home redesenhada em ARB pt, en e es nesta spec |
| Abordagem | Híbrida: servidor manda os fatos de treino; app escolhe a ação do dia numa função pura |

## 1. Anatomia (topo → base)

Cada bloco responde uma pergunta. Só o card de foco tem `emphasize: true`.

1. **Cabeçalho.** App bar "Hoje" + freshness (`FxHubFreshness`). No corpo:
   "Olá, {primeiro nome}" e a linha "Seu personal: {nomePersonal}" com logo
   24 px; toque → `/chat/aluno`. Sem nome do personal → a linha não aparece.
2. **Card de foco — o que tenho hoje.** Eyebrow, título, 1 linha de descrição,
   `AlunoHomeInsightLine` (título + evidência; CTA só se a rota for diferente
   da ação) e o chip P0 (`FxActionChip`). Saem o badge de sequência, a pill de
   ritmo local e as linhas de narrativa.
3. **Aviso único.** No máximo um banner: anamnese pendente; se não houver,
   mensagem do coach proativo. Nenhum dos dois → nada.
4. **Sua semana — como estou.** Três métricas: sessões na semana contra a meta
   ("2 de 3"), sequência em semanas e volume da semana. Abaixo, o
   `AlunoRecoveryCard` com as regras atuais (só com histórico de wearable).
5. **Evolução — estou evoluindo.** Gráfico de força (1RM est.) e volume das 8
   semanas, variação da força como métrica e o último recorde em uma linha.
   Sem texto que repita o insight e sem botão "Treinar agora".
6. **Pendências — próximo passo.** Até 3 itens (§3.2). Lista vazia → o bloco
   some.
7. **Ofertas.** `AlunoUpsellCarousel`, como hoje, só que nesta posição.
8. **Ferramentas.** `_StudentToolsSection`, sem mudança.

Acima da dobra: cabeçalho, card de foco e, no máximo, o aviso.

## 2. Dados e contrato

### 2.1 Backend (`focux-backend`)

- `AlunoDashboardHomeResponse` ganha `Integer concluidosSemanaIso`: sessões
  concluídas desde a segunda-feira da semana ISO atual (São Paulo). O valor sai
  de `AlunoInsightInput.concluidosSemanaIso()`, já calculado em
  `AlunoHomeInsightInputs.montar`, então o bloco "Sua semana" e o insight
  `META_ATINGIDA` usam o mesmo número.
- Se a montagem do input falhar, o campo vai `null` (mesma regra do `insight`).
- Aditivo: nenhum campo removido; `historico` legado continua `[]`. Entra no
  cache de 60s e na ETag. Sem tabela, sem migration.
- Atualizar a descrição do OpenAPI em `AlunoDashboardController`.

### 2.2 App — fonte de cada bloco

| Bloco | Fonte |
|---|---|
| Cabeçalho | `aluno.nome` (primeiro nome), `personalBrand.nomePersonal`, `personalBrand.logoUrl` |
| Card de foco | `resolveAlunoTodayAction` (§3.1) + `insight` |
| Aviso | `minhaAnamneseProvider` (como hoje) e `coachMensagens` |
| Sua semana | `concluidosSemanaIso`, `frequenciaDias`, `streakAtual`, `volumeSemanaKg` |
| Prontidão | `recovery`, `recoveryStale`, `hasWearableHistory` |
| Evolução | `forcaPorSemana`, `volumePorSemana`, `forcaDeltaPercent`, `recordes.first` |
| Pendências | `resolveAlunoPendencias` (§3.2) |

`AlunoDashboardHomeBundle` lê `concluidosSemanaIso` como `int?`; valor ausente
ou malformado → `null`.

### 2.3 Fallback honesto

- `concluidosSemanaIso == null` (backend antigo ou falha): "Sua semana" mostra
  só sequência e volume.
- `frequenciaDias == null`: "{n} treinos nesta semana", sem meta.
- `volumeSemanaKg == 0`: a métrica de volume some (não mostra "0 kg").
- Sem série válida para força: `forcaDeltaPercent == null` → a métrica some;
  o gráfico segue com as regras atuais (sem zero falso).
- Sem objetivo cadastrado: nenhum texto menciona objetivo.

## 3. Regras no app (funções puras em `lib/features/dashboard/utils/`)

### 3.1 Ação do dia — `resolveAlunoTodayAction`

Entrada: `Aluno`, `treinos`, `historico` (resumo do BFF, só para o rodízio),
completude do perfil e `hoje`. Saída: `AlunoTodayAction` (modo, rota,
`routeExtra`, chave de texto e parâmetros). Ordem = prioridade:

| # | Modo | Quando | CTA → rota |
|---|---|---|---|
| 1 | `financialHold` | `aluno.inadimplente` | Abrir financeiro → `/financeiro/aluno` |
| 2 | `workoutReady` | `proximoTreinoParaHoje(treinos, historico) != null` | Treinar agora → `/checkin/executar` (`routeExtra: treinoId`) |
| 3 | `awaitingRelease` | algum treino `isTreinoAguardandoLiberacao` | Ver treinos → `/checkin/treinos` |
| 4 | `profileSetup` | completude < 60% | Completar perfil → `/aluno/perfil` |
| 5 | `noWorkout` | nenhum dos anteriores | Falar com o personal → `/chat/aluno` |

- `workoutReady` mantém o rodízio de `proximoTreinoParaHoje` e o aviso de
  prazo (`TreinoAtribuicaoPrazo.homeHint`). Descrição: "{n} exercícios no
  treino de hoje" (sem lente de objetivo).
- Em `workoutReady`, se `aluno.diasSemTreino >= 7`, só muda o texto: título
  "Volte com {treino}" e CTA "Retomar agora". O dado vem do servidor em dias
  de calendário; sai a conta de 24h no fuso do aparelho.
- `inadimplente` já é `inadimplente || statusFinanceiro == INADIMPLENTE` no
  `AlunoSelfResponse` (spec 1), então o app lê só o booleano.
- Saem os modos `comeback` (vira variação de texto), `evolution` e `steady`.
- Completude do perfil: telefone e WhatsApp contam como um campo "contato".

### 3.2 Pendências — `resolveAlunoPendencias`

Candidatas, em ordem de prioridade:

| Tipo | Quando | Rota |
|---|---|---|
| `perfil` | completude < 100% | `/aluno/perfil` |
| `foto` | sem `fotoUrl` | `/aluno/perfil` |
| `medida` | nenhuma medida ou a última com mais de 14 dias (regra atual) | `/aluno/perfil` |
| `chat` | `chat.naoLidasDoPersonal > 0` | `/chat/aluno` |
| `agenda` | `isAlunoAgendaReviewed() == false` | `/agenda/aluno` |

A tarefa "Enviar contexto no chat" (aluno nunca mandou mensagem) e a tarefa
de treino da semana saem: a primeira não é pendência real e a segunda já é o
card de foco.

- Remove a candidata do mesmo tipo do P0 (ex.: `profileSetup` remove "perfil
  incompleto").
- Corta em 3. Sem porcentagem, sem barra e sem contar "financeiro em dia"
  como pendência resolvida.
- Cada item: ícone, título, uma linha de contexto, toque → rota. Chevron
  permitido (é navegação, P2).

## 4. Estrutura do código

- **Novos** em `lib/features/dashboard/`:
  `utils/aluno_today_action.dart`, `utils/aluno_pendencias.dart`,
  `widgets/aluno_home_header.dart`, `widgets/aluno_week_summary.dart`,
  `widgets/aluno_pendencias_block.dart`. `aluno_dashboard_screen.dart` fica só
  com composição e estados.
- **Apagados** (grep antes; hoje só a Home os usa): `aluno_autonomy_plan.dart`
  (`FocuxScore`, `AlunoObjectiveLens`, narrativas, `_latestEvolution`,
  `buildAlunoHomeExperience`, `buildAlunoAutonomyPlan`), `_AlunoHeroCard`,
  `_HeroPill`, `_HomeNarrativeRail`, `_StreakFoldBadge`, `_WorkoutInsightPill`,
  `_StudentJourneyCard`, `_NextBestTaskPanel`, `_AutonomyTaskTile`,
  `_AutonomyTaskPill` e o texto de insight de `_PerformanceEvolutionCard`.
  `ProgressoSemanalWidget` sai da Home; se ninguém mais usar, o arquivo é
  apagado. Testes do contrato antigo (`aluno_autonomy_plan_test.dart` e
  trechos do `aluno_dashboard_visual_contract_test.dart`) são reescritos para o
  contrato novo.
- **Efeitos colaterais**: `MeusTreinosMemCache.save` sai do `build()` e vai
  para o ponto em que o provider entrega os dados. Nenhum cálculo roda duas
  vezes por build.
- `alunoHomeComoCalculamos` e o sheet de ajuda passam a falar de "Hoje" e das
  quatro perguntas; sem citar score.

## 5. Idiomas, acessibilidade e analytics

- Todo texto novo ou mantido na Home (cabeçalho, ação do dia, aviso, Sua
  semana, Evolução, Pendências, ajuda) vai para `app_pt.arb`, `app_en.arb` e
  `app_es.arb`. Números via formatação de locale já usada (`pt_br_display`
  para pt).
- `Semantics` agrupado: "Sua semana" é lido como uma frase ("2 de 3 treinos
  nesta semana, sequência de 4 semanas, volume de 3.200 kg"); o último recorde
  também. Linha do personal tem rótulo "Abrir conversa com {nome}".
- Alvos de toque ≥ 48 dp; contraste pelos tokens da paleta.
- Analytics (`ProductEvents`): `aluno_today_action_tapped` (prop `modo`),
  `aluno_pendencia_tapped` (prop `tipo`), `aluno_pendencias_viewed` 1× por
  sessão. Reset no `session_invalidator`, como o insight. Sem PII nas props.

## 6. Estados

- Carregando: `SkeletonList` no formato novo (cabeçalho, card de foco, 3
  métricas, gráfico).
- Erro: `FxErrorState` + `friendlyError` + retry (como hoje).
- Vazio: aluno sem treino e sem histórico → card de foco em `noWorkout` e
  `FxEmptyState` no lugar de Sua semana e Evolução, com ação "Ver treinos".
- Bloco sem dado some; nada vira zero fingindo dado.
- Offline e cache: comportamento atual do `AlunoDashboardHomeClientCache`.

## 7. Testes

Backend (JUnit):
- `AlunoDashboardControllerTest`: payload com `concluidosSemanaIso`; `null`
  quando a montagem do input falha.
- `AlunoHomeInsightInputsTest` (ou o teste existente do input): virada de
  semana (domingo → segunda) e sessões duplicadas no mesmo dia contam 2.

App (flutter test):
- `aluno_today_action_test.dart`: um caso por modo, prioridade entre modos,
  variação "Volte com {treino}" com `diasSemTreino` 6 e 7, foto ausente não
  tira o treino do P0, rodízio preservado.
- `aluno_pendencias_test.dart`: exclusão do tipo do P0, corte em 3, lista
  vazia, medida com 14 e 15 dias, chat com 0 e 1 não lida, contato contado
  uma vez.
- Bundle: `concluidosSemanaIso` válido, ausente e malformado.
- Widget: Sua semana com e sem meta e com `concluidosSemanaIso` nulo; linha do
  personal sem nome; aviso único (anamnese vence o coach).
- Contrato visual da Home: um `emphasize: true`; ofertas abaixo de Evolução;
  sem catálogo antes do card de foco.
- l10n: chaves novas presentes nos três ARB.

Verificação antes do commit: `.\gradlew.bat test --console=plain`,
`flutter analyze --fatal-warnings --fatal-infos --no-pub`,
`flutter test --no-pub -r failures-only`, gitleaks no diff.

## 8. Rollout

- Backend primeiro (campo aditivo); o app da loja ignora o campo.
- App novo tolera backend sem o campo (§2.3).
- O build de loja sai quando o dono mandar.

## 9. Fora de escopo

- Tela de Evolução do aluno (spec 3b).
- Acabamento transversal fora da Home (spec 4).
- Meta semanal definida pelo personal (campo novo).
- Mover a ação do dia ou as pendências para o servidor.
- Remover `historico` legado do payload (depende da versão mínima do app).
- Mudar regras do insight, da sequência ou da prontidão.
