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
   A app bar não repete o avatar: o Perfil já está no dock.
2. **Card de foco — o que tenho hoje.** Eyebrow, título, 1 linha de descrição,
   `AlunoHomeInsightLine` (só leitura: título + detalhe, sem CTA) e o chip P0
   (`FxActionChip`), único toque do card. Saem o badge de sequência, a pill de
   ritmo local e as linhas de narrativa.
3. **Aviso único.** No máximo um banner: anamnese pendente; se não houver,
   mensagem do coach ("Seu coach Focux"). Nenhum dos dois → nada. No
   bloqueio financeiro o card de foco não mostra insight. O coach passa por
   `alunoCoachVisiveis`: na retomada saem `SEM_TREINO_5D` e
   `STREAK_QUEBRADO` (o card de foco já diz isso); com prontidão visível sai
   `SONO_BAIXO`. "Entendi" some com a mensagem na hora e só recarrega a Home
   quando a última é lida.
4. **Sua semana — como estou.** Três métricas: sessões na semana contra a meta
   ("2 de 3"), sequência em semanas e volume da semana. Meta batida marca o
   tile de sessões com o verde de sucesso e um check. Abaixo, o
   `AlunoRecoveryCard` alimentado pelo BFF (`alunoProntidaoVisivel`): prontidão
   de hoje com histórico de wearable, ou convite para sincronizar quando a
   última é antiga. Sem wearable o bloco não existe.
5. **Evolução — estou evoluindo.** Gráfico de força (1RM est.) e volume das 8
   semanas, variação da força como métrica e o último recorde em uma linha.
   Recorde dos últimos 7 dias vira "Novo recorde". A linha de força usa a cor
   secundária da marca (verde fica para status). Sem texto que repita o
   insight e sem botão "Treinar agora".
6. **Pendências — próximo passo.** Até 3 itens (§3.2). Lista vazia → o bloco
   some.
7. **Ofertas.** `AlunoUpsellCarousel` com as ofertas do BFF, header de seção,
   botões de 48 dp travados durante o envio. Altura do conteúdo (fonte grande
   não corta); uma oferta ocupa a largura toda.
8. **Ferramentas.** `_StudentToolsSection` com até 3 atalhos dinâmicos
   (`AlunoHomeView.atalhos`): ordem de `alunoAtalhosPrioridade`, sem abas do
   dock e sem destino que já aparece acima (`rotasNoTopo`: foco, aviso de
   anamnese, chat do cabeçalho e pendências). Atalhos e catálogo escondem o
   que o plano do personal não libera (`recursosIndisponiveis`).

NPS: o BFF só libera depois de 3 treinos concluídos e sem resposta nos
últimos 30 dias. Fechar sem responder adia 7 dias neste aparelho (chave
limpa no logout).

Acima da dobra: cabeçalho, card de foco e, no máximo, o aviso. Cada bloco só
entra com conteúdo e traz o próprio espaçamento, então bloco escondido não
soma espaço.

## 2. Dados e contrato

### 2.1 Backend (`focux-backend`)

- `AlunoDashboardHomeResponse` ganha `Integer concluidosSemanaIso`: sessões
  concluídas desde a segunda-feira da semana ISO atual (São Paulo). O valor sai
  de `AlunoInsightInput.concluidosSemanaIso()`, já calculado em
  `AlunoHomeInsightInputs.montar`.
- Se a montagem do input falhar, o campo vai `null` (mesma regra do `insight`).
- `frequenciaDias` é a meta da Home: `AlunoDashboardHomeSurface.metaSemanal`
  = fichas ativas do rodízio (2–7). Com menos de 2 fichas o plano não diz a
  frequência, então vai `null`.
  `FocuxScoreCalculator.metaDiasSemanaPlano` segue só como denominador de score.
- `recordes` vem com cap 1: a Home usa só o último.
- `insight` só traz o que nenhum bloco mostra: `RITMO_CAIU` (média das 4
  semanas anteriores ≥ 2/semana, 1+ treino nos últimos 7 dias, abaixo da
  metade da média e meta não batida) ou `VOLUME_SUBINDO`. Nada disso → `null`.
  Sem `acao` nem `evidencia`.
- `coachMensagens`: não lidas dos últimos 3 dias
  (`CoachProativoScheduler.VALIDADE_DIAS`).
- `recursosIndisponiveis`: recursos de `RECURSOS_DO_ALUNO`
  (`HABIT_COACHING`, `COMUNIDADE_GRUPOS`) que o plano do personal não libera.
- `npsDeveResponder` segue `NpsElegibilidade` (3+ treinos concluídos, sem
  resposta em 30 dias), a mesma regra de `/api/nps/deve-responder`.
- Mensalidade paga/editada/em atraso, treino atribuído/desvinculado/excluído e
  mensagem do coach enviada limpam o cache da Home do aluno
  (`AlunoDashboardHomeCacheEvictor`).
- Aditivo: nenhum campo removido; `historico` legado continua `[]`. Entra no
  cache de 60s e na ETag. Sem tabela, sem migration.
- Atualizar a descrição do OpenAPI em `AlunoDashboardController`.

### 2.2 App — fonte de cada bloco

| Bloco | Fonte |
|---|---|
| Cabeçalho | `aluno.nome` (primeiro nome), `personalBrand.nomePersonal`, `personalBrand.logoUrl` |
| Card de foco | `resolveAlunoTodayAction` (§3.1) + `insight` |
| Aviso | `anamnesePendente` e `coachMensagens` |
| Sua semana | `concluidosSemanaIso`, `frequenciaDias`, `streakAtual`, `volumeSemanaKg` |
| Prontidão | `recovery`, `recoveryStale`, `hasWearableHistory` |
| Evolução | `forcaPorSemana`, `volumePorSemana`, `forcaDeltaPercent`, `recordes.first` |
| Pendências | `listAlunoPendenciasAbertas` + `alunoPendenciasVisiveis` (§3.2) |
| Ofertas | `upsellPendentes` |

Tudo que a Home deriva do bundle sai de `buildAlunoHomeView`, memoizado por
bundle e estado da agenda. Escritas que mudam a Home (check-in, confirmar
plano, coach lido, oferta respondida, chat, anamnese, perfil) chamam
`invalidateAlunoDashboardHome(ref)`, que limpa o cache do app antes de
invalidar o provider.

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
| 4 | `profileSetup` | completude < 60% | Completar perfil → `/aluno/perfil/editar` |
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

### 3.2 Pendências — `listAlunoPendenciasAbertas`

Candidatas, em ordem de prioridade:

| Tipo | Quando | Rota |
|---|---|---|
| `perfil` | completude < 100% | `/aluno/perfil/editar` |
| `foto` | sem `fotoUrl` | `/aluno/perfil/editar?acao=foto` (abre o seletor) |
| `medida` | nenhuma medida ou a última com mais de 14 dias (regra atual) | `/aluno/perfil/editar?acao=medida` (abre o registro) |
| `chat` | `chat.naoLidasDoPersonal > 0` | `/chat/aluno` |
| `agenda` | agenda não aberta nesta semana | `/agenda/aluno` |

- Agenda: `markAlunoAgendaReviewed` grava a segunda-feira da semana
  (`alunoAgendaSemanaKey`); a pendência volta toda segunda. A chave é limpa no
  logout (`session_invalidator`). Enquanto o estado não carregou, a Home
  trata a agenda como conferida: nada pisca e nenhum `VIEWED` sai antes.
- `alunoPendenciasVisiveis` tira `chat` quando o foco já é `noWorkout`
  (mesmo destino) e corta em 3. As escondidas seguem abertas para o
  `COMPLETED` de autonomia.

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
  `utils/aluno_home_week.dart`, `utils/aluno_home_texts.dart`,
  `utils/aluno_autonomy_analytics.dart`, `widgets/aluno_home_header.dart`,
  `widgets/aluno_week_summary_card.dart`, `widgets/aluno_evolution_card.dart`,
  `widgets/aluno_pendencias_block.dart`. `aluno_dashboard_screen.dart` fica só
  com composição e estados.
- **Apagados** (grep antes; hoje só a Home os usa): `aluno_autonomy_plan.dart`
  (`FocuxScore`, `AlunoObjectiveLens`, narrativas, `_latestEvolution`,
  `buildAlunoHomeExperience`, `buildAlunoAutonomyPlan`), `_AlunoHeroCard`,
  `_HeroPill`, `_HomeNarrativeRail`, `_StreakFoldBadge`, `_WorkoutInsightPill`,
  `_StudentJourneyCard`, `_NextBestTaskPanel`, `_AutonomyTaskTile`,
  `_AutonomyTaskPill` e o texto de insight de `_PerformanceEvolutionCard`.
  `ProgressoSemanalWidget` sai da Home, mas o arquivo fica (Meus Treinos usa).
  `aluno_performance_evolution.dart` perde `AlunoPerformanceEvolutionView`,
  `buildAlunoPerformanceEvolutionView`, `alunoPerformanceForcaDeltaInsight` e
  `alunoUltimaEvolucaoPerformance`; ficam `alunoTrendPlot` e
  `parseAlunoHomeSeries`. `volumeMesKg` sai do bundle do app (o campo segue no
  payload). Testes do contrato antigo (`aluno_autonomy_plan_test.dart` e
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
- Analytics: reaproveita o contrato de autonomia que já existe
  (`ProductEvents.alunoAutonomyTask*` + `POST /api/aluno/autonomia/eventos`).
  O backend abre ações no Centro de Comando do personal a partir desses
  eventos (`AlunoAutonomiaService`), então os `taskId` não mudam:
  `perfil-base`, `foto-dados`, `medida-recente`, `chat-contexto`,
  `agenda-semana`, `treino-semana`, `financeiro`. O `taskTitle` enviado fica
  em pt fixo, porque vira texto da ação do personal.
  - Pendência visível → `VIEWED` 1× por sessão por `taskId` (reset no
    `session_invalidator`, como o insight). "Visível" = metade do bloco na
    viewport com a aba ativa (`FxOnVisible`), não a montagem. Toque →
    `CLICKED`.
  - Toque no P0 → `CLICKED` só onde o personal precisa agir:
    `financialHold` → `financeiro`, `noWorkout` → `treino-semana`,
    `profileSetup` → `perfil-base`. `workoutReady` e `awaitingRelease` não
    mandam evento de autonomia (começar treino não é pedido de apoio).
  - Nenhum evento novo; sem PII nas props.

## 6. Estados

- Carregando: `AlunoHomeSkeleton` no formato novo (cabeçalho, card de foco, 3
  métricas, gráfico).
- Erro: `FxErrorState` + `friendlyError` + retry (como hoje).
- Vazio: aluno sem treino e sem histórico → o card de foco em `noWorkout` é o
  estado guiado; Sua semana e Evolução somem.
- Coach e ofertas: envio travado, erro com `FeedbackHelper` e texto do ARB.
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
