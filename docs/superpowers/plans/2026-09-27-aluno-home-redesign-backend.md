# Aluno — Home "Hoje" (backend) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expor `concluidosSemanaIso` no BFF `GET /api/dashboard/aluno/home`, com o mesmo número que o insight `META_ATINGIDA` usa.

**Architecture:** O `AlunoDashboardService.montar` passa a montar o `AlunoInsightInput` uma vez; o campo novo sai de `input.concluidosSemanaIso()` e o engine recebe o mesmo input. Falha ao montar → campo e insight `null`.

**Tech Stack:** Java 21, Spring Boot 4.1, JUnit 5, AssertJ, MockMvc.

**Spec:** `focux-app/docs/superpowers/specs/2026-09-27-aluno-home-redesign-design.md` §2.1
**Repo:** `D:\Focux Personal\focux-backend`

## Global Constraints

- Repo público: nada sensível no diff; `gitleaks protect --staged --no-banner` antes do commit.
- Commit curto em pt, sem trailer de IA.
- Contrato só aditivo; sem migration; sem dependência nova.
- `.\gradlew.bat test --console=plain` verde antes do commit.

---

### Task 1: Campo `concluidosSemanaIso` no BFF

**Files:**
- Modify: `src/main/java/com/focux/modules/dashboard/dto/AlunoDashboardHomeResponse.java` (novo componente no fim)
- Modify: `src/main/java/com/focux/modules/dashboard/AlunoDashboardService.java:213-273`
- Modify: `src/main/java/com/focux/modules/dashboard/AlunoDashboardController.java` (descrição OpenAPI)
- Test: `src/test/java/com/focux/modules/dashboard/AlunoHomeInsightInputsTest.java`
- Test: `src/test/java/com/focux/modules/dashboard/AlunoDashboardControllerTest.java`
- Test: `src/test/java/com/focux/modules/dashboard/AlunoDashboardHomeResponseTest.java`

**Interfaces:**
- Produces: JSON `concluidosSemanaIso: Integer | null` no payload da Home.

- [ ] **Step 1: Testes que falham**

`AlunoHomeInsightInputsTest`:

```java
    @Test
    void semanaIsoComecaNaSegundaEContaSessoesDoMesmoDia() {
        var segunda = LocalDate.of(2026, 9, 14);
        var datas = List.of(segunda, segunda, LocalDate.of(2026, 9, 13));
        var in = AlunoHomeInsightInputs.montar(segunda, datas, 0L, 3, 1, null, List.of(),
            AlunoHomeVolume.emptyResumo());

        assertThat(in.concluidosSemanaIso()).isEqualTo(2);
    }
```

`AlunoDashboardControllerTest.home_semCamposInternosDoPersonalEComInsightDeAlunoNovo`: acrescentar
`.andExpect(jsonPath("$.concluidosSemanaIso").value(0))`.

`AlunoDashboardHomeResponseTest`: acrescentar o argumento `2` no fim do construtor e
`assertThat(response.concluidosSemanaIso()).isEqualTo(2);`.

- [ ] **Step 2: Rodar e ver falhar** (`.\gradlew.bat test --tests "*AlunoDashboard*" --tests "*AlunoHomeInsightInputs*" --console=plain`): compilação falha no construtor e o jsonPath não existe.

- [ ] **Step 3: Implementar**

Record, depois de `insight`:

```java
    @Schema(description = "Sessões concluídas na semana ISO atual (São Paulo). Mesmo número do insight de meta. Null se o cálculo falhar.")
    Integer concluidosSemanaIso
```

Service: `montar` calcula o input uma vez.

```java
        var input = montarInput(alunoId, hoje, treino.datasConcluidas(), perfil.aluno().diasSemTreino(),
            frequencia, streak, recovery.snapshot(), perfil.recordes(), volume);
        return new AlunoDashboardHomeResponse(
            ...,
            perfil.recordes(),
            input == null ? null : avaliarInsight(alunoId, input),
            input == null ? null : input.concluidosSemanaIso()
        );
```

```java
    private AlunoInsightInput montarInput(Long alunoId, LocalDate hoje, List<LocalDate> datasConcluidas,
        Long diasSemTreino, Integer frequencia, int streak, RecoverySnapshotResponse recoverySnapshot,
        List<RecordeResponse> recordes, AlunoHomeVolume.Resumo volume) {
        try {
            return AlunoHomeInsightInputs.montar(hoje, datasConcluidas, diasSemTreino, frequencia, streak,
                recoverySnapshot, recordes, volume);
        } catch (RuntimeException e) {
            log.warn("aluno_insight_falhou alunoId={} regra=montar erro={}", alunoId, e.getClass().getSimpleName());
            return null;
        }
    }

    private AlunoInsight avaliarInsight(Long alunoId, AlunoInsightInput input) {
        try {
            return AlunoInsightEngine.avaliar(input);
        } catch (AlunoInsightEngine.RegraFalhou e) {
            log.warn("aluno_insight_falhou alunoId={} regra={} erro={}",
                alunoId, e.regra(), e.getCause().getClass().getSimpleName());
            return null;
        } catch (RuntimeException e) {
            log.warn("aluno_insight_falhou alunoId={} regra=engine erro={}", alunoId, e.getClass().getSimpleName());
            return null;
        }
    }
```

Controller: acrescentar `concluidosSemanaIso` na descrição do endpoint.

- [ ] **Step 4: Rodar a suíte inteira** `.\gradlew.bat test --console=plain` → verde.

- [ ] **Step 5: Commit + push**

```bash
git add -A src
gitleaks protect --staged --no-banner
git commit -m "feat(dashboard): sessões da semana na home do aluno"
git push
```
