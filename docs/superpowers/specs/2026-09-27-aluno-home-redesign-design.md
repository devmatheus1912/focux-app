# Aluno — Home "Hoje" (referência oficial)

Data: 2026-09-27 · Revisão 2 (fecha os gaps das auditorias de 27/09).
Repos: `focux-app` (principal), `focux-backend` (ajustes pequenos).

Esta spec é a **referência da Home do aluno** (`/dashboard/aluno`). A
`FOCUX_DESIGN_REFERENCE.md` descreve a Home do personal; dela a Home do aluno
herda só a pele (tokens, `FxStripCard`, estados, densidade). System design:
`docs/system/04-api.md` (contrato aditivo), `05-cache.md` (Caffeine 60s + ETag).

A seção 8 é o **contrato fechado**: a auditoria final checa só aquela lista.
Ideia nova vira backlog, não gap.

## Decisões aprovadas

| Tema | Decisão |
|---|---|
| Job da tela | O que fazer hoje primeiro; depois como estou indo |
| Ordem | Agir primeiro: foco, aviso e pendências antes de semana, prontidão e evolução |
| Pendências | Por urgência: mensagem do personal, horário novo, medida, cadastro |
| Prontidão baixa | O card de foco fala; o card de prontidão não repete a dica |
| Aviso único | Saúde antes de dinheiro: atestado, mensalidade, anamnese, coach |
| Execução | Regras em funções puras no app (`utils/`); servidor manda os fatos |
| Evolução | Só força na Home; volume fica em Sua semana. Tela de Evolução é a spec 3b |
| Idiomas | Só PT-BR (`app_pt.arb`); en/es congelados até o app escalar |

## 1. Anatomia (topo → base)

Cada bloco responde uma pergunta. Só o card de foco tem `emphasize: true`.
Bloco sem dado some e não soma espaço (cada bloco traz o próprio espaçamento).

1. **Cabeçalho.** App bar "Hoje" + frescor (`FxHubFreshness`). No corpo,
   "Olá, {primeiro nome}" e a linha "Seu personal: {nomePersonal}" com logo
   24 px; toque → `/chat/aluno`. Sem nome do personal → a linha some. A app bar
   não repete o avatar (o Perfil está no dock).
2. **Foco do dia — o que faço hoje.** Eyebrow, título, descrição, prazo,
   linha do próximo horário, `AlunoHomeInsightLine` e o chip P0
   (`FxActionChip`), único toque do card.
   - Descrição até 2 linhas. Prazo em linha própria (até 2 linhas): nunca é
     cortado pela descrição.
   - Próximo horário: linha só de leitura "Horário com seu personal: hoje às
     18:00" (ou "amanhã às 07:30") quando `agendaProximoInicio` é hoje ou amanhã.
   - Prontidão baixa (§3.4): a descrição vira "Prontidão baixa: prefira um
     treino leve ou mobilidade." O CTA não muda.
3. **Aviso único.** No máximo um banner (§3.3). O coach passa por
   `alunoCoachVisiveis`: na retomada saem `SEM_TREINO_5D` e `STREAK_QUEBRADO`;
   com prontidão visível sai `SONO_BAIXO`. "Entendi" some com a mensagem na
   hora e só recarrega a Home quando a última é lida.
4. **Pendências — próximo passo.** Até 3 itens (§3.2). Lista vazia → some.
5. **Sua semana — como estou.** Só depois do primeiro treino concluído
   (`jaTreinou`). Sessões contra a meta ("2 de 3"), sequência em semanas e
   volume da semana. Meta batida marca o tile de sessões com verde e check.
6. **Prontidão.** `AlunoRecoveryCard` (`alunoProntidaoVisivel`): anel, rótulo
   e dica do servidor. Com prontidão baixa, sem a dica (o foco já falou).
   Sem snapshot de hoje e última antiga → convite para sincronizar. Sem
   wearable → some.
7. **Evolução — estou evoluindo.** Só com `jaTreinou`. Linha de força (1RM
   est.) das 8 semanas, variação da força e o último recorde ("Novo recorde"
   até 7 dias). Sem volume (já está em Sua semana). O card não abre nada
   (`/evolucao` redireciona para a Home até a spec 3b).
8. **Ofertas.** `AlunoUpsellCarousel` (`AlunoHomeView.ofertas`, vazia com
   mensalidade em atraso). Aceitar é `OutlinedButton`, recusar `TextButton`,
   48 dp, travados no envio. Os dois pedem confirmação (`showFxConfirmSheet`):
   a resposta não volta atrás. Uma oferta ocupa a largura toda.
9. **Atalhos.** Até 3 (`AlunoHomeView.atalhos`), na ordem de
   `alunoAtalhosPrioridade`, sem abas do dock, sem destino que já aparece
   acima (`rotasNoTopo`) e sem recurso fora do plano (`recursosIndisponiveis`).
   Sem atalho → a seção mostra só o cabeçalho com "Ver catálogo".

NPS: o BFF libera depois de 3 treinos concluídos e sem resposta em 30 dias. O
app só pergunta com o foco em `workoutDone` e com a Home como rota visível
(`alunoHomeRoute`). Fechar sem responder adia 7 dias (chave limpa no logout).

## 2. Dados e contrato

### 2.1 Backend (`focux-backend`)

`GET /api/dashboard/aluno/home` (`AlunoDashboardService`, `@Cacheable` 60s +
ETag, 4 grupos read-only em paralelo):

- `concluidosSemanaIso`: sessões desde a segunda ISO (São Paulo); `null` se a
  montagem do input falhar.
- `frequenciaDias` = fichas do rodízio (2–7); menos de 2 → `null`.
- `streakAtual` lê só as execuções das últimas 104 semanas
  (`TREINOS_JANELA_SEMANAS`).
- `recordes` com cap 1.
- `insight`: `RITMO_CAIU` ou `VOLUME_SUBINDO`, sem `acao` nem `evidencia`.
- `coachMensagens`: não lidas dos últimos 3 dias, sem `SEM_TREINO_5D` e
  `STREAK_QUEBRADO` anteriores ao último treino (`coachAindaValido`).
- `recursosIndisponiveis`: `AGENDA`, `HABIT_COACHING`, `COMUNIDADE_GRUPOS`
  que o plano do personal não libera.
- `agendaProximoInicio`: próximo horário não cancelado nos próximos 7 dias
  (`MIN(inicio)` numa query). Plano sem `AGENDA` → `null` (`agendaVisivel`).
- `npsDeveResponder` segue `NpsElegibilidade`.
- Escritas que mudam a Home limpam o cache do aluno
  (`AlunoDashboardHomeCacheEvictor`): agenda, mensalidade, treino atribuído,
  status, coach, oferta respondida.
- **Deprecated** no OpenAPI: `agendaProxima` e `volumeMesKg`. O app atual não
  lê; builds antigos da loja leem. Saem quando a versão mínima subir.
- `historico` legado segue `[]`. Sem tabela nova, sem migration.

### 2.2 App — fonte de cada bloco

| Bloco | Fonte |
|---|---|
| Cabeçalho | `aluno.nome`, `personalBrand.nomePersonal`, `personalBrand.logoUrl` |
| Foco | `resolveAlunoTodayAction` (§3.1), `insight`, `recovery`, `agendaProximoInicio` |
| Aviso | `anamnesePendente`, `aluno.inadimplente`, `coachMensagens` |
| Pendências | `listAlunoPendenciasAbertas` + `alunoPendenciasVisiveis` (§3.2) |
| Sua semana | `concluidosSemanaIso`, `frequenciaDias`, `streakAtual`, `volumeSemanaKg` |
| Prontidão | `recovery`, `recoveryStale`, `hasWearableHistory` |
| Evolução | `forcaPorSemana`, `forcaDeltaPercent`, `recordes.first` |
| Ofertas | `upsellPendentes` |

Tudo que a Home deriva sai de `buildAlunoHomeView(home, now:, agendaReviewed:)`.
Ausente ou malformado no bundle → `null`, e o bloco segue §6.

## 3. Regras (funções puras em `lib/features/dashboard/utils/`)

### 3.1 Foco — `resolveAlunoTodayAction`

| # | Modo | Quando | CTA → rota |
|---|---|---|---|
| 1 | `workoutDone` | sem sessão `EM_ANDAMENTO` e o último `CONCLUIDO` é de hoje | Ver resumo → `/checkin/historico/{id}` |
| 2 | `workoutReady` | `proximoTreinoParaHoje(treinos, historico) != null` | Treinar agora → `/checkin/executar` |
| 3 | `awaitingRelease` | algum treino aguardando liberação | Ver treinos → `/checkin/treinos` |
| 4 | `profileSetup` | completude < 60% | Completar perfil → `/aluno/perfil/editar` |
| 5 | `noWorkout` | nenhum dos anteriores | Falar com o personal → `/chat/aluno` |

- `workoutDone`: "Próximo: {ficha}" ou convite ao descanso; não manda treinar.
- `workoutReady`: "{n} exercícios no treino de hoje"; com `diasSemTreino >= 7`
  vira "Volte com {treino}" / "Retomar agora".
- Mensalidade atrasada não é modo: vira aviso (§3.3) e tira as ofertas.
- Completude: telefone e WhatsApp contam como um campo.

### 3.2 Pendências

Candidatas, em ordem de urgência:

| Tipo | Quando | Rota | Título · detalhe |
|---|---|---|---|
| `chat` | `chat.naoLidasDoPersonal > 0` | `/chat/aluno` | "Responder o personal" · "1 mensagem nova" / "{n} mensagens novas" |
| `agenda` | horário depois de amanhã e ainda não visto | `/agenda/aluno` | "Seu próximo horário" · "qua., 30 de set. às 18:00" |
| `medida` | nenhuma medida ou a última com mais de 14 dias | `/aluno/perfil/editar?acao=medida` | texto de primeira medida quando nunca registrou |
| `perfil` | completude < 100% ou sem `fotoUrl` | só a foto falta → `/aluno/perfil/editar?acao=foto`; senão `/aluno/perfil/editar` | "Adicionar foto" quando só a foto falta; senão "Completar perfil" |

- Agenda hoje ou amanhã fica na linha do foco; a pendência não repete.
- Visto por horário: abrir a agenda por qualquer caminho grava o início visto
  (`aluno_agenda_vista_v3`). Horário novo ou remarcado pede de novo. A Home
  relê o visto quando volta a ser a rota da frente e no pull-to-refresh. Chave
  limpa no logout. Antes de ler, a agenda conta como vista (nada pisca).
- `alunoPendenciasVisiveis`: sem o destino do foco (`profileSetup` tira
  `perfil`; `noWorkout` tira `chat`) e corta em 3. As escondidas seguem
  abertas para o `COMPLETED` de autonomia.

### 3.3 Aviso — `resolveAlunoHomeAviso`

Um por vez, nesta ordem:

| # | Aviso | Quando | Toque |
|---|---|---|---|
| 1 | Atestado | `anamnesePendente == PRECISA_ATESTADO` | `/aluno/anamnese` |
| 2 | Financeiro | `aluno.inadimplente` | `/financeiro/aluno` |
| 3 | Anamnese | `anamnesePendente == SOLICITADA` | `/aluno/anamnese` |
| 4 | Coach | `alunoCoachVisiveis` não vazia | card do coach |

Atestado e financeiro em tom `warn`; anamnese em `info`.

### 3.4 Prontidão baixa — `alunoProntidaoBaixa`

Foco em `workoutReady`, prontidão visível, snapshot de hoje e
`recoveryScore < 45` (corte "Descanso recomendado" do `RecoveryScoreCalculator`).

### 3.5 Próximo horário no foco — `alunoHorarioNoFoco`

`agendaProximoInicio` cujo dia é hoje ou amanhã (relativo a `now`). Fora
disso → `null`.

### 3.6 Atalhos

`rotasNoTopo` = rota do foco, rota do aviso (atestado e anamnese →
`/aluno/anamnese`; financeiro → `/financeiro/aluno`), chat do
cabeçalho e rotas das pendências visíveis.

## 4. Estado, dados e frescor

- **Volta do background:** pausa de 2 min ou mais recarrega a Home do aluno
  junto com a do personal (`main.dart`); acima do TTL limpa o cache do aluno.
- **Virada do dia:** o memo da view usa (bundle, horário visto, dia de hoje).
  O mesmo bundle no dia seguinte recalcula foco, horário, recorde e prazo.
- **Um relógio por build:** a tela passa `now` para `buildAlunoHomeView` e
  para os textos; nenhum widget decide texto com `DateTime.now()` próprio.
- **304:** o bundle reaproveitado ganha `fetchedAt` = agora (`withFetchedAt`).
- **Subtítulo:** mesmo `skipLoadingOnReload` e `skipError` do corpo.
- **Pull-to-refresh:** busca sem apagar o cache; sem rede, mantém os dados e
  avisa ("Sem conexão agora. Mostrando os últimos dados.").
- **Escritas** (check-in, plano, coach, oferta, chat, anamnese, perfil) chamam
  `invalidateAlunoDashboardHome(ref)`.
- **Custo:** voltar para a Home só faz `setState` se o horário visto mudou.
  `UpsellRepository` vem de provider.

## 5. Acessibilidade, idioma e analytics

- Todo texto em `app_pt.arb`. Números via locale (`pt_br_display`).
- "Sua semana" e o último recorde lidos como uma frase. Linha do personal com
  rótulo "Abrir conversa com {nome}". Avisos lidos como botão com título e
  detalhe.
- Alvos ≥ 48 dp. Contraste pelos tokens.
- Movimento reduzido: o coração da prontidão (`FxRiveHeartPulse`) vira ícone
  estático.
- Autonomia (`POST /api/aluno/autonomia/eventos`): `taskId` fixos
  (`perfil-base`, `foto-dados`, `medida-recente`, `chat-contexto`,
  `agenda-semana`, `treino-semana`, `financeiro`). `taskTitle` em pt fixo; o
  da agenda é "Conferir próximo horário".
  - Pendência → `VIEWED` 1× por sessão quando visível (`FxOnVisible`); toque →
    `CLICKED`. Perfil e foto no mesmo item mandam o `taskId` do que falta
    (`foto-dados` se só a foto falta; senão `perfil-base`).
  - P0: `noWorkout` → `treino-semana`, `profileSetup` → `perfil-base`.
  - Aviso financeiro → `CLICKED` de `financeiro`.
  - Nenhum evento novo; sem PII.

## 6. Estados

- Carregando: `AlunoHomeSkeleton` com cabeçalho e foco.
- Erro sem cache: `FxErrorState` + `friendlyError` + retry.
- Vazio: aluno sem treino → foco em `noWorkout`; semana e evolução somem.
- Evolução com treino mas sem carga registrada: texto guia "Registre a carga
  das séries para ver sua evolução aqui."
- Coach e ofertas: envio travado; erro com `FeedbackHelper` e texto do ARB.

## 7. Estrutura do código

- Regras: `aluno_today_action.dart`, `aluno_pendencias.dart`,
  `aluno_home_view.dart` (inclui `alunoHorarioNoFoco`, `alunoProntidaoBaixa`),
  `aluno_home_texts.dart`, `aluno_autonomy_analytics.dart`.
- Tela: `aluno_dashboard_screen.dart` (composição e estado), os `part`s de
  aviso e ferramentas e o widget `AlunoTodayFocusCard`.
- `AlunoPendenciaTipo.foto` continua no enum (rota e `taskId` próprios), mas
  só aparece quando o perfil está completo: nunca junto com `perfil`.
- Limpeza no mesmo ship: série de volume do `AlunoEvolutionCard`,
  `volumePorSemana` do bundle, `_TodayFocusCard` e o que mais ficar sem caller.

## 8. Contrato fechado (auditoria final)

Cada critério tem prova. A Home é 10/10 quando todos passam.

| # | Critério | Prova |
|---|---|---|
| C1 | Ordem: cabeçalho, foco, aviso, pendências, semana, prontidão, evolução, ofertas, atalhos | contrato visual |
| C2 | Só o foco tem `emphasize` | contrato visual |
| C3 | Bloco sem dado some e não soma espaço | contrato visual |
| C4 | Foco com 5 modos na prioridade de §3.1; financeiro não é modo | unit |
| C5 | Linha do próximo horário só hoje ou amanhã | unit + widget |
| C6 | Prontidão baixa: texto no foco, CTA igual, card sem dica | unit + widget |
| C7 | Prazo visível com fonte 2x | widget |
| C8 | Aviso: atestado, financeiro, anamnese, coach | unit |
| C9 | Mensalidade atrasada: treino no foco, ofertas vazias | unit |
| C10 | Pendências: chat, agenda, medida, perfil; no máximo 3 | unit |
| C11 | Perfil e foto em 1 item; só a foto falta → seletor de foto | unit |
| C12 | Agenda: só depois de amanhã e não visto; visto por horário; relido ao voltar | unit + contrato |
| C13 | Nenhuma pendência repete o destino do foco | unit |
| C14 | Chat mostra a quantidade de mensagens | unit |
| C15 | Evolução só com força; volume só em Sua semana | widget |
| C16 | Atalhos sem topo, sem dock, sem recurso bloqueado; vazio → só catálogo | unit + widget |
| C17 | Oferta confirma antes; sem `FilledButton` | contrato |
| C18 | Volta do background (≥ 2 min) recarrega a Home do aluno | contrato `main.dart` |
| C19 | Mesmo bundle no dia seguinte: "feito hoje" vira treino pronto | unit |
| C20 | 304 atualiza `fetchedAt` | unit |
| C21 | Subtítulo não pisca e segue offline | contrato |
| C22 | Refresh offline mantém dados e avisa | contrato |
| C23 | Movimento reduzido, alvos 48 dp, leitura agrupada | widget |
| C24 | `taskId` iguais; título da agenda "Conferir próximo horário"; VIEWED só visível | unit |
| C25 | Só PT-BR; en/es sem chave fora do pt | `arb_parity_test` |
| C26 | BE: `agendaProxima`, `volumeMesKg` e `volumePorSemana` deprecated no OpenAPI; `gradlew test` verde | gradle |
| C27 | `dart analyze --fatal-warnings --fatal-infos`, órfãos, `flutter test`, gitleaks verdes | comandos |

## 9. Fora de escopo

- Tela de Evolução do aluno (spec 3b).
- Mover foco ou pendências para o servidor.
- Remover `agendaProxima`, `volumeMesKg` e `historico` do payload (depende da
  versão mínima do app).
- Mudar regras do insight, da sequência ou do cálculo de prontidão.
- Meta semanal definida pelo personal.
