# Aluno — aba Treinos (auditoria e referência oficial)

Data: 2026-09-28 · Revisão 2 (fatia 1: hub de Treinos; fatia 2: histórico, seção 14).
Repos: `focux-app` (principal), `focux-backend` (ajustes aditivos + prévia).

Este documento junta a auditoria da experiência de treino do aluno e a spec
da **fatia 1** (hub `/checkin/treinos`). A seção 11 é o **contrato fechado**:
a auditoria final checa só aquela lista. Ideia nova vira backlog, não gap.

System design: `docs/system/04-api.md` (contrato aditivo) e `05-cache.md`
(Caffeine 60s + ETag). A pele vem da `FOCUX_DESIGN_REFERENCE.md` e da spec da
Home do aluno (`docs/superpowers/specs/2026-09-27-aluno-home-redesign-design.md`).

## Decisões aprovadas

| Tema | Decisão |
|---|---|
| Escopo | Em fatias: 1) hub; 2) histórico; 3) execução; 4) evolução (spec 3b). Segurança do backend em commit à parte |
| Job da aba | "O que vou treinar?" Operacional: iniciar, continuar, consultar. Sem métricas da Home |
| Consistência | Sai da aba. Semana, sequência, volume e força ficam só na Home |
| Topo | Um destaque: em andamento → concluído hoje → próximo do rodízio → em preparação |
| Depois do treino do dia | "✓ Concluído hoje" no destaque + próximo do rodízio compacto, ainda com Iniciar |
| "Fiz o treino" | Vira "Já fiz este treino", só na prévia, com confirmação. Grava o treino sem séries: conta para semana e sequência, sem volume, força ou recorde |
| Prévia | Tela empilhada com os exercícios; só o botão Iniciar abre sessão |
| Dados | O hub lê só o agregado da Home (`/api/dashboard/aluno/home`); `meus-treinos` sai |
| Idiomas | Só PT-BR (`app_pt.arb`) |

## 1. Arquitetura atual (antes)

- Rota `/checkin/treinos` → `MeusTreinosScreen` (aba 2 do shell do aluno).
- Dados: `meusTreinosProvider` → `GET /api/checkin/meus-treinos?page&size=20`
  **e** `alunoDashboardHomeProvider` (agregado da Home), que já traz os mesmos
  treinos. Dois fetches para a mesma lista.
- Topo: `ProgressoSemanalWidget` ("Consistência": aderência, volume, bolinhas da
  semana, "Você treinou N dias · meta N"), usado só nesta aba.
- Lista: `_TrainingPlanCard` igual para todas as fichas: ícone, nome,
  subtítulo, `Iniciar` grande e `Fiz o treino` ao lado. O card inteiro inicia.
- Banner "Retomar treino" via `treinoSessaoEmAndamento(treinos)`.
- Execução: `/checkin/executar` faz `POST /api/checkin/iniciar` ao abrir.
- Histórico: `/checkin/historico` (cursor, 20) e `/checkin/historico/:id`.
- Evolução do aluno: não existe tela; `/evolucao` redireciona para a Home.

## 2. Fluxo atual

Home (foco "Iniciar" → execução direta) · Treinos (card → execução direta) ·
Execução (séries, descanso, finalizar) · volta para Treinos · Histórico pela
app bar · detalhe da sessão (volume vs anterior, recordes, abas).

## 3. Home × Treinos

| Informação | Home | Treinos hoje | Decisão |
|---|---|---|---|
| Treinos na semana, meta | Sua semana | Consistência | Só Home |
| Sequência | Sua semana | frase de ritmo | Só Home |
| Volume da semana | Sua semana | chip Volume | Só Home |
| Aderência % | — | chip | Sai (métrica do personal) |
| Força, recorde | Evolução | — | Só Home |
| Próximo treino | foco (CTA direto) | lista sem destaque | Os dois, mesma regra (`proximoTreinoParaHoje`) |
| Plano completo, prévia, últimos treinos | — | parcial | Só Treinos |

## 4. Dados existentes

- Treino da lista (`ExecucaoResponse` via `mapMeusTreinos`): `treinoId`,
  `treinoNome`, `status` (`DISPONIVEL`/`AGUARDANDO_LIBERACAO`), `dataInicio`,
  `dataFim`. `exercicios` vem **vazio**; a contagem é calculada e descartada.
  Sem ordem (`Sort.unsorted()`).
- Histórico resumido (Home, 12 itens): `id`, `treinoId`, `treinoNome`, `status`,
  `iniciadoEm`, `concluidoEm`, `exerciciosCount` (todos os exercícios da sessão,
  não os feitos).
- Sessão: status gravados `EM_ANDAMENTO`, `CONCLUIDO`, `CANCELADO`. Não existe
  pausado. Duração não é salva (só `concluidoEm − iniciadoEm`).
- Rotina: **não há agenda por dia da semana**. Há rodízio: próximo = o seguinte
  ao último concluído (`AlunoTreinoRepository.PROXIMO_TREINO_AT_ID`, por
  `AlunoTreino.id`; no app, `proximoTreinoParaHoje`).
- Recorde: carga maior que todas as anteriores do exercício
  (`CheckinEvolucaoAnalyzer`). Volume: Σ carga × primeiro número das reps.

## 5. Endpoints do aluno (checkin)

`/api/checkin/*` com `@PreAuthorize("hasRole('ALUNO')")`, aluno sempre de
`TenantContext.getAlunoId()`. Tudo com `{id}` usa `findByIdAndAlunoId` (404 para
id de outro aluno). `iniciar`/`confirmar-plano` checam atribuição ativa.
Listagem, execução (iniciar, série, confirmar restante, concluir, descartar),
histórico (cursor, `q`, `status`), detalhe, `evolucao-sessao`, agregado da Home
(Caffeine 60s + ETag, `@RateLimit` 60/min).

## 6. Problemas atuais

1. **"Retomar" nunca aparece.** A lista só manda `DISPONIVEL`/`AGUARDANDO`;
   `treinoSessaoEmAndamento(treinos)` sempre dá null, e a prioridade do rodízio
   para a sessão aberta também não funciona.
2. **Contagem errada.** "Pronto para treinar" no lugar de "6 exercícios"; o foco
   da Home também usa `exercicios.length` (0).
3. **Números inventados.** "~Xmin" = exercícios × 4; "N vídeos" conta GIFs.
4. **"Fiz o treino" inventa carga.** Preenche séries com a última sessão ou a
   prescrição; entra em volume, força e recorde (pode gerar recorde falso com
   push). Fica ao lado de Iniciar com o mesmo peso.
5. **Abrir = iniciar.** Não dá para ver os exercícios sem criar sessão; a sessão
   esquecida bloqueia outro treino e gera push de abandono depois de 2 h.
6. **Sem hierarquia.** Cards gigantes iguais; não escala com muitas fichas.
7. **Ordem aleatória.** O próximo no app pode divergir do push das 17:30.
8. **Dois fetches** da mesma lista ao abrir a aba.
9. **Texto fora do ARB** e sem acento ("Em preparacao", "ja reservou").
10. Card inteiro como `InkWell` com botões dentro, sem rótulo semântico.

## 7. Duplicações

Consistência (semana, meta, volume, ritmo) repete "Sua semana" da Home.
`meus-treinos` repete a lista de treinos do agregado.

## 8. Oportunidades

Destaque único por estado; plano compacto; últimos treinos com contexto real;
prévia sem sessão; contagem e ordem vindas do servidor; um fetch a menos.

## 9. Alternativas avaliadas

| Opção | Resumo | Veredito |
|---|---|---|
| A | Hub sobre o agregado da Home + campos aditivos + prévia | **Escolhida**: zero request ao abrir, mesma regra de próximo que a Home, remove código |
| B | Hub sobre `meus-treinos` enriquecido + `historico?size=3` | 2 requests por abertura; próximo calculado em dois lugares |
| C | Só interface | Não corrige contagem, ordem nem prévia |

## 10. Solução (fatia 1)

### 10.1 Anatomia (topo → base)

App bar "Treinos" + frescor (`FxHubFreshness`). Sem contagem, sem botão
Histórico, sem refresh (pull-to-refresh). Cada bloco some sem dado e traz o
próprio espaçamento. Só o destaque tem `emphasize: true`.

1. **Destaque.** Estado pela prioridade:

| Estado | Condição | Conteúdo | Ação |
|---|---|---|---|
| Em andamento | treino com status `EM_ANDAMENTO` | eyebrow "Em andamento", nome, "4 de 6 exercícios" + barra | **Continuar treino** → execução |
| Concluído hoje | `treinoConcluidoHoje(historico)` e nada em andamento | "✓ Concluído hoje", nome, duração real | "Ver treino" → `/checkin/historico/{id}` |
| Próximo | `proximoTreinoParaHoje` | "Próximo treino", nome, "6 exercícios", prazo | **Iniciar treino** → execução |
| Em preparação | só fichas `AGUARDANDO_LIBERACAO` | "Em preparação", nome, "Seu personal está montando os exercícios." | nenhuma |

   "N de M": N = `exerciciosConcluidos` do item `EM_ANDAMENTO` do histórico
   resumido; M = `exerciciosCount` do treino. Sem o item, só "M exercícios".
   Toque no corpo do destaque abre a prévia (em andamento e próximo) ou o
   detalhe (concluído hoje). O botão inicia ou continua direto.
2. **Depois.** Só no estado concluído hoje: o próximo do rodízio em linha
   compacta com "Iniciar".
3. **Seu plano.** Todas as fichas na ordem do rodízio, menos as que já estão no
   destaque ou em "Depois". Linha: nome (até 2 linhas), "6 exercícios" ou "Em
   preparação", prazo (`TreinoPrazoBadge`) e seta. Toque → prévia; em
   preparação → sheet de status. Sem botão por linha.
4. **Últimos treinos.** Até 3 execuções `CONCLUIDO` do histórico resumido, sem a
   que está no destaque. Linha: data ("Hoje", "Ontem", "12 set"), nome e um
   detalhe: duração real; senão "N exercícios" (`exerciciosConcluidos > 0`);
   senão "Sem séries registradas". Toque → detalhe. Link "Ver histórico" →
   `/checkin/historico`.

**Duração real:** `concluidoEm − iniciadoEm` entre 5 min e 8 h; fora disso não
aparece. Formato "52 min" / "1 h 10 min".

### 10.2 Estados da tela

- Sem fichas: `FxEmptyState` "Seu personal ainda não liberou treinos." +
  "Falar com seu personal" → `/chat/aluno`.
- Sem histórico: bloco 4 some.
- Carregando: esqueleto (destaque + 3 linhas).
- Erro sem cache: `FxErrorState` + retry. Offline com cache: mostra o último
  agregado e avisa (mesmo padrão da Home).
- Virada do dia: o memo da view vale até a meia-noite; ao voltar para a aba ou
  do background, recalcula (mesmo relógio da Home, `now` passado de cima).

### 10.3 Prévia `/checkin/treino/:treinoId`

Tela empilhada (fora do shell, sem dock), só ALUNO (`isAlunoOnlyLocation`,
`isAlunoPath`).

- Cabeçalho: nome e "6 exercícios · Até 23/10".
- Lista: número, nome, "3 × 10–12 · 20 kg · descanso 60 s", miniatura 48 px
  quando houver, observação do personal inteira.
- Rodapé fixo. A situação vem do agregado da Home (status do treino e
  `treinoConcluidoHoje`), não da prévia:

| Situação | Principal | Secundária |
|---|---|---|
| Disponível | Iniciar treino | Já fiz este treino |
| Em andamento | Continuar treino | — |
| Concluído hoje | Iniciar treino | — |

- Outra sessão aberta: Iniciar segue para a execução, que já trata o 409
  (`CheckinSessaoAbertaState`).
- Carregando: esqueleto. Erro: `FxErrorState`. 404: "Este treino não está mais
  no seu plano." + voltar; recarrega o agregado.

### 10.4 "Já fiz este treino"

1. `showFxConfirmSheet`: "Registrar sem séries?" / "Conta para sua semana e
   sequência. Sem cargas registradas, não entra no volume nem nos recordes." /
   "Registrar" · "Voltar".
2. Confirmar → `POST /api/checkin/confirmar-plano` → overlay "Treino
   registrado" → volta ao hub → `invalidateAlunoDashboardHome`.
3. Erro → `FeedbackHelper` com `friendlyError`; botão destrava.

### 10.5 Backend

- `mapMeusTreinos` (alimenta o agregado da Home):
  - `exerciciosCount` (Integer) em cada treino.
  - Status `EM_ANDAMENTO` no treino com sessão aberta do aluno (uma query).
  - Ordem por `AlunoTreino.id` crescente (a mesma do `PROXIMO_TREINO_AT_ID`).
- Histórico resumido: `exerciciosConcluidos` (exercícios com `concluido =
  true`), aditivo.
- `GET /api/checkin/treinos/{treinoId}/previa`: `@PreAuthorize ALUNO`, aluno do
  token, mesma checagem de atribuição do `iniciar` (treino ativo, mesmo
  personal, atribuição ativa); senão 404. Só leitura. Resposta
  `TreinoPreviaResponse(treinoId, treinoNome, dataFim, exercicios[])` com
  `treinoExercicioId`, `exercicioNome`, `series`, `repeticoes`, `cargaKg`,
  `descansoSegundos`, `observacoes`, `thumbnailUrl`, `gifUrl`, `temVideo`.
  Sem `@RateLimit` até a correção do limitador por aluno (fatia de segurança).
- `confirmarPlano`: inicia (ou retoma a mesma sessão) e conclui, **sem**
  `confirmarRestante`. Limite de 1× por treino por dia mantido. A mensagem
  automática do chat não pode afirmar séries ou carga.
- Sai `GET /api/checkin/meus-treinos` (paginado) e `meusTreinosPagina`: sem
  consumidor. Sai `historicoRecente` / `HUB_HISTORICO_SIZE` (sem chamador).
- Sem migration, sem tabela nova.

### 10.6 App — estrutura

- Regra pura: `lib/features/checkin/utils/treinos_hub_view.dart`
  (`buildTreinosHubView(bundle, now)` → destaque, depois, plano, últimos).
  Reusa `proximoTreinoParaHoje`, `treinoConcluidoHoje`, `treinoSessaoEmAndamento`.
- Widgets em `lib/features/checkin/widgets/` (destaque, linha do plano, linha
  de último treino). Tela só compõe.
- Prévia: `treino_previa_screen.dart`, `CheckinRepository.previa`, modelo
  `TreinoPrevia` (parse na borda).
- Foco da Home: `exerciseCount` passa a vir de `exerciciosCount`.
- Todo texto novo ou tocado em `app_pt.arb`.
- Acessibilidade: destaque com rótulo agregado ("Próximo treino: Treino de
  força, 6 exercícios, até 23 de outubro") e botão separado; linhas ≥ 48 dp com
  `Semantics(button:)`; estado nunca só por cor (ícone + texto); nomes até 2
  linhas sem corte com fonte 2x; movimento só na entrada (`FxMotion`), nada em
  loop.

### 10.7 Limpeza no mesmo ship

App: `ProgressoSemanalWidget`, `alunoConsistenciaCaption` (se sem outro
chamador), `_treinosInsightLine`, `_WeekProgressStrip`, `_TrainingPlanCard`,
`_RetomarTreinoBanner`, `meusTreinosCountLabel`, `meusTreinosProvider`,
`MeusTreinosMemCache` (e o save da Home, a limpeza no `SessionInvalidator` e o
teste dele), `historicoCheckinProvider` (e as invalidações),
`CheckinRepository.meusTreinosPagina`. Backend: itens de 10.5. Grep de cada
símbolo; zero chamadores → apaga. Testes do contrato velho atualizados.

## 11. Contrato fechado (fatia 1)

| # | Critério | Prova |
|---|---|---|
| T1 | Ordem: destaque, depois, seu plano, últimos treinos; bloco sem dado some | widget |
| T2 | Destaque na prioridade em andamento → concluído hoje → próximo → em preparação | unit |
| T3 | Em andamento mostra "N de M exercícios" e "Continuar treino" | unit + widget |
| T4 | Concluído hoje: "Ver treino" abre o detalhe; próximo em "Depois" com Iniciar | unit + widget |
| T5 | Próximo do hub = próximo do foco da Home (mesma função, mesmos dados) | unit |
| T6 | Contagem real de exercícios no hub, na prévia e no foco da Home | unit + widget |
| T7 | Sem "~min", sem "vídeos", sem Consistência, sem aderência, sem volume | widget + grep |
| T8 | Duração só entre 5 min e 8 h | unit |
| T9 | Últimos: até 3 concluídos, sem repetir o destaque; "Sem séries registradas" quando cabe | unit |
| T10 | Toque na linha abre a prévia; nada inicia sem o botão | widget |
| T11 | Prévia: estados disponível, em andamento, concluído hoje, carregando, erro, 404 | widget |
| T12 | "Já fiz" só na prévia, com confirmação; grava sem séries; conta na semana | widget + gradle |
| T13 | BE: `exerciciosCount`, `EM_ANDAMENTO`, ordem do rodízio, `exerciciosConcluidos` | gradle |
| T14 | BE: prévia 404 para treino de outro aluno, não atribuído ou inativo; 403 para PERSONAL | gradle |
| T15 | Abrir a aba não faz request além do agregado da Home | contrato |
| T16 | Rota da prévia só ALUNO; pós-login aceita a rota | unit |
| T17 | Texto em `app_pt.arb`, com acento | `arb_parity_test` + grep |
| T18 | Alvos ≥ 48 dp, leitura agrupada, fonte 2x sem corte, estado não só por cor | widget |
| T19 | Mortos de 10.7 apagados; `dart analyze --fatal-warnings --fatal-infos`, órfãos, `flutter test`, `gradlew test`, gitleaks verdes | comandos |

## 12. Riscos

- Agregado da Home maior: +1 inteiro por treino e por item do histórico (baixo).
- Builds antigos do TestFlight chamam `meus-treinos`: a aba deles quebra depois
  do deploy. Pedir aos testers o build novo junto com o deploy.
- "Já fiz" antigo gravou séries estimadas; o histórico passado não muda.
- Push "Novo treino disponível" continua abrindo a execução (cria sessão).

## 13. Fora desta fatia

- **Fatia 2, histórico:** sessões do mesmo plano acessíveis (hoje agrupadas e
  só a mais recente abre); linha com duração/volume; data de conclusão; texto
  escrito para o personal; filtro por período se fizer sentido.
- **Fatia 3, execução:** confirmar ao finalizar incompleto; rascunho offline;
  alvos < 48 dp; aviso de fim do descanso; caminho "Demonstração" morto.
- **Fatia 4, evolução do aluno** (spec 3b).
- **Segurança (commit à parte):** `RateLimitAspect` por aluno (hoje por
  personal); `IdempotencyFilter` com o ator na chave; caches de histórico
  limpos no logout; limites de `cargaKg`.
- Push de treino novo abrir a prévia.
- Agenda por dia da semana (não existe no backend).

## 14. Fatia 2: histórico

### 14.1 Auditoria (antes)

- Lista `/checkin/historico` (540 linhas): sessões da mesma ficha viram uma
  linha ("3 sessões · data") e só a mais recente abre; linha só com data de
  início e chip de status; busca por texto e chips Todos/Concluído/Em
  andamento; ajuda escrita para o personal ("Treinos que o aluno já
  fechou."); textos fixos no código; 3 requests de detalhe em prefetch a cada
  abertura; estado manual + `HistoricoMemCache`; botão "Carregar mais".
- Detalhe `/checkin/historico/:id` (596 linhas): eyebrow "Sinal"; tile que
  alterna "Recordes"/"Exerc."; abas Exercícios/Recordes/Notas; "Treinar de
  novo" abre a execução direto (sessão sem prévia, 409 com outra aberta);
  duração vira "—"; textos fixos; estado manual + `HistoricoDetalheMemCache`.
- Evolução hoje: peso, medidas, recordes. Tendência de volume e força é da
  fatia 4, então o histórico é um diário de sessões, sem gráfico de período.

### 14.2 Decisões aprovadas

| Tema | Decisão |
|---|---|
| Escopo | Lista + detalhe da sessão |
| Organização | Uma linha por sessão, agrupada por semana ISO (segunda a domingo) |
| Filtro | Chips das fichas atuais (vindas do agregado da Home); sai a busca |
| Status | Só sessões concluídas; a sessão aberta vive no hub |
| Linha | Igual aos Últimos do hub: nome, dia de conclusão, duração real ou "N exercícios feitos" / "Sem séries registradas" |
| Treinar de novo | Abre a prévia |
| Abordagem | A: endpoint atual + `treinoId` + `exerciciosConcluidos`; semanas no app |

### 14.3 Solução

**Lista.** App bar "Histórico" com frescor, sem ajuda. Chips "Todos · Treino A
· …" só com 2+ fichas. Cabeçalhos "Esta semana", "Semana passada", "Semana de
14 set"; "· N treinos" só quando a semana veio inteira (a última semana
carregada, com página seguinte, fica sem número). Linha =
`TreinoRecenteRow`. Próxima página carrega perto do fim (linha de skeleton).
Estados: skeleton com leitura própria, erro com retry, vazio sem filtro
("Ver treinos"), vazio com filtro ("Ver todos"), puxar para atualizar.

**Detalhe.** Subtítulo "Concluído · qua, 24 de set" (data de conclusão).
Resumo: status ("Concluído" / "Concluído sem séries"), duração só se
confiável, frase de comparação do backend quando houver. Tiles fixos: Volume
(só > 0), Séries "N de M", Exercícios "N de M". Uma rolagem: Exercícios,
Recordes (se houver), Notas (se houver). Botão fixo: concluída → "Treinar de
novo" abre a prévia, some se a ficha saiu do plano; aberta (link antigo ou
push) → "Continuar treino". Estados: skeleton, erro, 404 ("Voltar ao
histórico").

**Backend.** `GET /api/checkin/historico?cursor&size&status&treinoId`: sai
`q` (Spring ignora parâmetro desconhecido; builds antigos só perdem a busca).
Item da lista ganha `exerciciosConcluidos` (uma query agrupada por página).
Dono continua pelo `alunoId` do token.

**App.** Lista em provider de paginação por ficha; detalhe e evolução da
sessão em providers `family`. Regra pura em `utils/`
(`agruparHistoricoPorSemana`, textos). Texto novo só em `app_pt.arb`.

**Mortos.** `historico_mem_cache.dart` (as duas caches), prefetch, busca,
chips de status, `historicoCollapseSamePlan`, `historicoGroupByStatus`,
`HistoricoStatusChip`, `historicoStatusQuery`, `historicoClusterSubtitle`,
abas do detalhe, os dois botões de ajuda e widgets privados do layout antigo.

### 14.4 Contrato fechado (fatia 2)

| # | Critério | Prova |
|---|---|---|
| H1 | Cada sessão concluída tem a própria linha e abre o próprio detalhe | widget |
| H2 | Semana ISO local; "Esta semana" / "Semana passada" / "Semana de d MMM" | unit |
| H3 | Contagem da semana só quando completa | unit + widget |
| H4 | Linha igual aos Últimos do hub (dia de conclusão, duração 5 min–8 h, exercícios) | widget |
| H5 | Chips das fichas só com 2+ fichas; filtro vai como `treinoId` | widget + gradle |
| H6 | Só concluídas na lista | widget + gradle |
| H7 | Próxima página carrega sozinha; sem "Carregar mais" | widget |
| H8 | Estados da lista: carregando, erro, vazio, vazio filtrado | widget |
| H9 | Detalhe sem "Sinal" e sem abas; Recordes e Notas somem sem dado | widget |
| H10 | "Treinar de novo" abre a prévia; some com a ficha fora do plano | widget |
| H11 | Detalhe: carregando, erro, 404 | widget |
| H12 | BE: `treinoId` filtra; ficha de outro aluno volta vazio; `exerciciosConcluidos` certo; `q` antigo não quebra | gradle |
| H13 | Texto em `app_pt.arb`; alvos ≥ 48 dp; fonte 2x sem corte | widget + grep |
| H14 | Mortos de 14.3 apagados; analyze, órfãos, `flutter test`, `gradlew test`, gitleaks verdes | comandos |
