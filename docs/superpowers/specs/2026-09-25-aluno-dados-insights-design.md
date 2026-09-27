# Aluno — verdade dos dados + Focux Insights (spec 1 de 4)

Data: 2026-09-25 · Repos: `focux-backend`, `focux-app` · Auditoria de base:
`docs/FOCUX_STUDENT_EXPERIENCE_AUDIT.md`.

## Contexto e decomposição

O prompt "Elevar a experiência do aluno" foi dividido em quatro partes. Esta
spec cobre as partes 1 e 2; as partes 3 e 4 terão specs próprias, cada uma com
seu ciclo spec → plano → implementação:

1. Dados corretos no BFF `GET /api/dashboard/aluno/home` (**esta spec**).
2. Motor determinístico Focux Insights no backend, com consumo mínimo no app
   (**esta spec**).
3. Redesenho da Home do aluno em torno de "o que tenho hoje / como estou /
   estou evoluindo / próximo passo" e tela de Evolução.
4. Acabamento transversal (a11y, estados, analytics gerais).

Capítulos de system design citados: `docs/system/03-dados.md` (tenant por
`alunoId`), `04-api.md` (contrato aditivo), `05-cache.md` (Caffeine 60s),
`08-seguranca-sistema.md`.

## Decisões aprovadas

| Tema | Decisão |
|---|---|
| Força | 1RM estimado (Epley) da melhor série por exercício; variação só entre exercícios presentes nas duas semanas |
| Sequência | Calculada ao ler, no BFF, a partir das datas de treino concluído |
| Dados internos do personal | DTO próprio do aluno sem campos de CRM; `inadimplente` fica |
| Prontidão | Válida só se `dataReferencia` for hoje ou ontem (São Paulo) |
| Motor de insights | Backend, dentro do BFF, um insight por vez |
| Insight na UI | Substitui a linha de ritmo do `_TodayFocusCard` já nesta entrega |

## Parte 1 — Dados corretos no BFF (`focux-backend`)

### 1.1 Força (`AlunoHomeForca`, classe pura nova ao lado de `AlunoHomeVolume`)

- Entrada: linhas de série concluída com `exercicioId`, `cargaKg`, `repeticoes`,
  data. A consulta `ExecucaoSerieRepository.findVolumeLinhasDesde` passa a
  selecionar também `exercicioId` (continua 1 consulta).
- Série válida: `cargaKg > 0` e repetições entre 1 e 12 (parser da seção 1.5).
  Acima de 12 a estimativa perde precisão e a série é descartada da força
  (continua no volume).
- `e1rm = carga × (1 + reps / 30)`.
- Por semana (segunda 00:00, `FocuxClock`, São Paulo) e exercício: maior `e1rm`.
- `forcaPorSemana[i]` = média dos e1RM dos exercícios da semana `i`; 8 buckets,
  índice 7 = semana atual; semana sem série válida = `0.0` (mesmo formato de hoje).
- `forcaDeltaPercent` (novo, `Double` nullable): semana atual vs anterior, só
  exercícios presentes nas duas; média das variações percentuais por exercício,
  arredondada a 1 casa. `null` se houver menos de 2 exercícios em comum.
- `forcaExerciciosComuns` (int, interno ao input do motor; não vai no payload).

### 1.2 Sequência

- `streakAtual` = `CheckinStreakWeeks.countFromDates(FocuxClock.today(), datasConcluidas)`
  calculado no BFF. A semana ISO atual sem treino não quebra a sequência; ela só
  quebra quando termina sem treino (comportamento já existente de `countFromDates`;
  o plano confirma com teste de virada de semana).
- `countFromDates` hoje devolve 0 se a semana atual ainda não tem treino. Novo
  `CheckinStreakWeeks.countAtivo(hoje, datas)`: se a semana atual está vazia,
  conta a partir da semana anterior.
- Gamificação (`GET /api/gamificacao`) usa o mesmo `countAtivo` na leitura; o
  `aluno_streaks` gravado vale só para `streakMaximo` e badge `STREAK_10`. No hub
  do personal, "alunos em sequência" exige último treino na semana ISO atual ou
  anterior (`CheckinStreakWeeks.ativo`).
- As datas vêm da consulta existente `ExecucaoTreinoRepository.findConcluidoEmByAlunoId`
  (a mesma da gamificação), reaproveitada pelo motor (seção 2.2).
- A tabela `aluno_streaks` segue alimentando a gamificação; o BFF deixa de lê-la.

### 1.3 Prontidão

- `recovery` só é enviado se `dataReferencia ∈ {hoje, ontem}` (São Paulo).
- Campo novo `recoveryStale` (boolean): `true` quando existe snapshot mas ele é
  mais antigo que ontem; `false` caso contrário (inclui "nunca teve wearable").

### 1.4 PRs

- Campo `recordes` no BFF: 5 mais recentes de `recordes_pessoais` do aluno,
  ordenados por `data DESC`, com `exercicioNome`, `cargaKg`, `data`.
- `AlunoDashboardHomeSurface.RECORDES_CAP` passa a ser usada, valor 5.

### 1.5 Volume — parser único

- `RepeticoesParser.primeiroInteiro(String)` substitui `CheckinEvolucaoAnalyzer.primeiroNumero`
  e o `parseReps` de `EvolucaoInteligenteService`.
- Regra única: primeiro número inteiro ("8-12" → 8); vazio/sem dígito → série
  ignorada.
- Efeito colateral aceito: o volume do painel do personal deixa de contar série
  sem repetição como 10. Registrar no commit.

### 1.6 Minimização de dados (LGPD)

- Novo `AlunoSelfResponse` usado pelo BFF do aluno e por `GET /api/aluno/me`.
- Remove: `emRisco`, `riscoNivel`, `proximoContato`, `snoozedUntil`,
  `ultimoContato`, `operacaoFocusMode`, `statusFinanceiro`.
- `inadimplente` do DTO do aluno = `inadimplente || statusFinanceiro == INADIMPLENTE`,
  porque o app da loja usa os dois sinais para o foco `financialHold`.
- Mantém: identidade, contato, objetivo, corpo, `inadimplente`,
  `aderenciaPercent` (significado inalterado: dias distintos com treino
  concluído nos últimos 30 dias × 100 / 30), `diasSemTreino`, `scoreProntidao`.
- Endpoints do personal continuam com `AlunoResponse` completo.

### 1.7 Performance do BFF

- Substituir os 14 `CompletableFuture` por 4 grupos paralelos (perfil, treino,
  social, saúde), cada um em um `TransactionTemplate` read-only (limite do
  Hikari = 5).
- O grupo perfil (aluno, marca, medidas, recordes) roda numa transação só, então
  as várias buscas do aluno por id saem do cache de primeiro nível do Hibernate
  (hoje ~4 cargas).
- Upsell: `JOIN FETCH` em `AlunoOferta.oferta` (remove N+1 de até 5); recordes
  com `@EntityGraph` em `exercicio`.
- `CheckinService.iniciar` passa a chamar o evictor da Home (a sessão em
  andamento aparece no `historicoResumo`). `registrarSerie` não: série de sessão
  em andamento não muda nenhum campo da Home, e evictar a cada série só geraria
  cache miss.
- Perfil de teste continua serial.

## Parte 2 — Motor Focux Insights (`focux-backend`)

### 2.1 Estrutura

Pacote `com.focux.modules.dashboard.insights`, Java puro, sem Spring:

- `AlunoInsightInput` (record) — dados já calculados pelo BFF.
- `AlunoInsightRule` — `Optional<AlunoInsight> avaliar(AlunoInsightInput in)`.
- `AlunoInsightRegras` — uma função estática nomeada por regra (tabela 2.3),
  cada uma testável isoladamente.
- `AlunoInsightEngine` — lista ordenada; devolve a primeira regra que dispara;
  a última regra sempre dispara.
- `AlunoInsightLimites` — constantes numéricas.
- `AlunoInsight` (record), `InsightTipo`, `InsightConfianca` (HIGH/MEDIUM/LOW).

O `AlunoDashboardService` monta o input e chama o engine; exceção no engine →
`log.warn` com `alunoId` e nome da regra (sem valores) e `insight = null`. A regra
que lança sai em `AlunoInsightEngine.RegraFalhou.regra()`; falha ao montar o input
loga `regra=montar`.

### 2.2 Entrada (`AlunoInsightInput`)

| Campo | Origem |
|---|---|
| `totalConcluidos` | datas concluídas (1.2) |
| `concluidosSemanaIso` | datas concluídas, semana ISO atual |
| `concluidos7d`, `concluidos28dAnteriores` | datas concluídas (últimos 7 dias; dias 8–35) |
| `diasSemTreino` | `aluno.diasSemTreino` (dias de calendário, `AlertasService.diasDeCalendario`) |
| `frequenciaDias` | `FocuxScoreCalculator.metaDiasSemanaPlano` |
| `streakSemanas` | 1.2 |
| `recoveryScore` | snapshot válido (1.3) ou `null` |
| `ultimoRecorde` | primeiro de `recordes` (1.4) ou `null` |
| `forcaDeltaPercent`, `forcaExerciciosComuns` | 1.1 |
| `volumePorSemana` | já existente (8 buckets) |
| `hoje` | `FocuxClock.today()` |

Contagens de treino contam **sessões** concluídas (não dias distintos), para
casar com "treinou 4 vezes". A aderência continua em dias distintos.

### 2.3 Regras (ordem = prioridade)

| # | Tipo | Dispara quando | Confiança | Ação |
|---|---|---|---|---|
| 1 | `NOVO` | `totalConcluidos == 0` | HIGH | `/checkin/treinos` · "Ver treinos" |
| 2 | `RECUPERACAO` | `recoveryScore != null && < 45` | MEDIUM | `/saude` · "Ver prontidão" |
| 3 | `PR` | `ultimoRecorde.data >= hoje − 7` | HIGH | `/checkin/historico` · "Ver histórico" |
| 4 | `RETORNO` | `totalConcluidos > 0 && diasSemTreino >= 7` | HIGH | `/checkin/treinos` · "Ver treinos" |
| 5 | `META_ATINGIDA` | `frequenciaDias != null && concluidosSemanaIso >= frequenciaDias` | HIGH | `/checkin/treinos` · "Ver treinos" |
| 6 | `FORCA_SUBINDO` | `forcaDeltaPercent != null && >= 3.0` | HIGH se `forcaExerciciosComuns >= 4`, senão MEDIUM | `/checkin/historico` |
| 7 | `VOLUME_SUBINDO` | semana completa anterior (índice 6) `>= 1.10 ×` média dos índices 0–5 com volume > 0, exigindo `>= 4` desses 6 com volume > 0 | MEDIUM | `/checkin/historico` |
| 8 | `CONSISTENTE` | `concluidos7d >= 3 || streakSemanas >= 3` | HIGH | `/checkin/treinos` |
| 9 | `RITMO_CAIU` | `concluidos28dAnteriores >= 8 && concluidos7d <= (concluidos28dAnteriores / 4) / 2` | MEDIUM | `/checkin/treinos` |
| 10 | `DADOS_INSUFICIENTES` | sempre (fallback) | LOW | `null` |

Textos pt de referência (o app usa as chaves ARB; o servidor manda pt como
fallback):

| Tipo | Título | Mensagem / evidência |
|---|---|---|
| NOVO | Seu histórico começa aqui | Complete seu primeiro treino. |
| RECUPERACAO | Dia para ir mais leve | Seu sono e atividade sugerem um dia mais leve. Alinhe com seu personal. |
| PR | Novo recorde | `{exercicio}: {cargaKg} kg` · Registrado há `{dias}` dias |
| RETORNO | Bora retomar | `{dias}` dias sem treinar. Que tal retomar hoje? |
| META_ATINGIDA | Meta da semana atingida | `{feitos}` treinos nesta semana (meta: `{meta}`) |
| FORCA_SUBINDO | Sua força está subindo | `+{pct}%` vs semana passada (`{n}` exercícios) |
| VOLUME_SUBINDO | Seu volume está subindo | `+{pct}%` vs média das 6 semanas anteriores |
| CONSISTENTE | Ritmo forte | `{feitos}` treinos nos últimos 7 dias (chave `insightConsistente`); se disparou só pela sequência: `{semanas}` semanas seguidas treinando (chave `insightSequencia`) |
| RITMO_CAIU | Seu ritmo caiu esta semana | `{feitos}` treinos nos últimos 7 dias |
| DADOS_INSUFICIENTES | Continue treinando | Continue treinando para ver novos sinais aqui. |

Salvaguardas: a v1 não emite queda de força nem de volume; a semana em
andamento nunca entra na comparação de volume; LOW só no fallback, sem números;
recuperação sem linguagem médica.

### 2.4 Contrato (campo aditivo `insight` no BFF)

```json
"insight": {
  "tipo": "PR",
  "confianca": "HIGH",
  "chave": "insightPr",
  "params": {"exercicio": "Supino", "cargaKg": "80", "dias": "3"},
  "titulo": "Novo recorde",
  "mensagem": "Supino: 80 kg",
  "evidencia": "Registrado há 3 dias",
  "acao": {"rota": "/checkin/historico", "cta": "Ver histórico"}
}
```

`params` são strings já formatadas (sem locale-sensitive no cliente além da
tradução). `acao` pode ser `null`. O `insight` entra no cache de 60s junto com
o resto do payload e na ETag.

## Parte 3 — App (`focux-app`)

1. `AlunoDashboardHomeBundle` lê `forcaDeltaPercent`, `recoveryStale`,
   `recordes` (já tinha parser), `insight` → `AlunoHomeInsight` (classe imutável,
   enums `AlunoInsightTipo`, `AlunoInsightConfianca`, `AlunoInsightAcao?`).
   Tipo desconhecido ou payload malformado → `insight = null`.
2. `alunoPerformanceForcaDeltaInsight` usa só `forcaDeltaPercent`; `null` →
   "Volume e força nas últimas semanas". Remove a comparação primeira/última
   semana e o texto "no último PR". Legenda do gráfico: "Força (1RM est.)";
   `alunoHomeComoCalculamos` explica Epley e a regra de exercícios em comum.
3. `AlunoRecoveryCard`: `recoveryStale == true` → estado honesto "Sincronize a
   Saúde para ver a prontidão de hoje" com ação para `/saude`.
4. `_TodayFocusCard`: a linha de ritmo (`_WorkoutInsightPill`) passa a mostrar
   `insight` (título + evidência) com o CTA da ação quando houver. Sem insight →
   `rhythmLabel` atual.
5. Limpeza no mesmo ship: `AlunoPerformanceEvolutionView.score`/`scoreLabel`,
   `alunoPerformanceScoreLabel` e o parâmetro `score` do card de evolução, que
   ficam sem caller. `FocuxScore.value` e `AlunoObjectiveLens` continuam: alimentam
   `_mainHomeAction` e as narrativas. A pill de ritmo (`score.rhythmLabel`) fica
   como fallback quando não há insight.
6. i18n: chaves `insight*` em `app_pt.arb`, `app_en.arb`, `app_es.arb`;
   corrigir "Recuperacao parcial" e "hidratacao" em `lib/core/health/recovery_score.dart`.
7. Analytics (`ProductEvents`): `aluno_insight_viewed` (1× por sessão por tipo)
   e `aluno_insight_action_tapped`; props só `tipo` e `confianca`.
8. `Aluno.fromJson` já tolera ausência dos campos de CRM (defaults `false`/`null`);
   teste de contrato garante isso.

## Erros e estados

- Engine falha → `insight: null`, Home intacta.
- Força incalculável → `forcaDeltaPercent: null`; prontidão velha →
  `recovery: null` + `recoveryStale: true`. Nada vira zero fingindo dado.
- App: campo novo malformado é ignorado; loading/erro/vazio/offline como hoje.

## Segurança

- `alunoId` só do token (`TenantContext`); sem id em path/query no BFF.
- Teste novo: aluno A recebe 404 em `/api/checkin/{id}` e
  `/api/checkin/{id}/evolucao-sessao` de uma sessão do aluno B.
- Logs sem sono, passos, FC, carga ou 1RM.
- Sem tabela nova; se o plano exigir índice, a migration segue o contrato de RLS.

## Compatibilidade e rollout

- Tudo aditivo; o app da loja (1.2.1+116) ignora `insight` e aceita a ausência
  dos campos de CRM.
- Backend primeiro; o app sai no próximo build de loja, quando o dono mandar.

## Testes

Backend (JUnit):
- `AlunoHomeForcaTest`: mix de exercícios, reps > 12, < 2 comuns → `null`,
  semana vazia, arredondamento.
- `RepeticoesParserTest`; sequência ao ler (virada de semana, semana atual vazia);
  idade da prontidão (hoje, ontem, anteontem, nunca).
- `AlunoInsightEngineTest` com os 7 cenários do prompt:
  1. aluno novo → `NOVO`;
  2. 4 treinos com meta 2 → `META_ATINGIDA`;
  3. volume +10% ou mais vs média comparável → `VOLUME_SUBINDO`;
  4. PR nos últimos 7 dias → `PR`;
  5. 7+ dias sem treino → `RETORNO`;
  6. poucos dados → `DADOS_INSUFICIENTES`, sem números;
  7. PR + meta + volume + treino disponível → só `PR`.
- Um teste por regra: dispara, não dispara, limite exato; confiança de `FORCA_SUBINDO`.
- `AlunoDashboardControllerTest`: payload sem CRM, com `recordes`,
  `recoveryStale`, `insight`; teste de IDOR.
- JaCoCo: `dashboard` ≥ 0.80 (existente); novo piso `dashboard.insights` ≥ 0.90.

App (flutter test):
- Parse do insight (válido, desconhecido, ausente) e fallback.
- Texto da força com e sem `forcaDeltaPercent`; estado de prontidão desatualizada.
- `Aluno.fromJson` sem campos de CRM.
- Contratos existentes da Home seguem verdes.

Verificação antes do commit: `.\gradlew.bat test --console=plain`,
`flutter analyze --fatal-warnings --fatal-infos --no-pub`,
`flutter test --no-pub -r failures-only`, gitleaks no diff.

## Fora de escopo

- Redesenho da Home e tela de Evolução do aluno (spec 3).
- Acabamento de a11y, estados e analytics gerais (spec 4).
- Insights de queda de força/volume, PR de repetições, notificações de insight.
- Mudar a fórmula da aderência.
