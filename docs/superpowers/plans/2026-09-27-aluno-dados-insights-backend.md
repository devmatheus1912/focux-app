# Aluno — dados corretos + Focux Insights (backend) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Corrigir força, sequência, prontidão, PRs, volume e exposição de dados no BFF `GET /api/dashboard/aluno/home` e adicionar o motor determinístico Focux Insights.

**Architecture:** Cálculos puros e pequenos no pacote `com.focux.modules.dashboard` (`AlunoHomeSerie`, `AlunoHomeForca`, `AlunoHomeVolume`, `AlunoHomeRecovery`, `AlunoHomeInsightInputs`), motor em `com.focux.modules.dashboard.insights` (Java puro, sem Spring) e o `AlunoDashboardService` reorganizado em 4 grupos paralelos read-only. Contrato só aditivo, exceto o DTO do aluno, que perde os campos internos do personal.

**Tech Stack:** Java 21, Spring Boot 4.1.1, JPA/Hibernate, Caffeine, JUnit 5, AssertJ, MockMvc, JaCoCo.

**Spec:** `focux-app/docs/superpowers/specs/2026-09-25-aluno-dados-insights-design.md`
**Repo:** `D:\Focux Personal\focux-backend` (todos os caminhos abaixo relativos a ele).

## Global Constraints

- Repo público: nenhum secret, `.env`, PII de QA ou dump no diff; rodar `gitleaks protect --staged --no-banner` antes de cada commit.
- Commit: `git -c user.name="Matheus Oliveira" -c user.email="matheusos1912@icloud.com" commit -m "<msg curta pt>"`; sem `Co-authored-by`, sem menção a IA/Cursor, sem "10/10".
- Não apagar, enfraquecer ou comentar testes. Só atualizar assertions cujo contrato a spec muda (listadas em cada task).
- Sem dependência nova. Sem tabela nova (sem migration).
- Logs nunca levam sono, passos, FC, carga ou 1RM.
- Tempo: sempre `FocuxClock.today()` / `FocuxClock.now()` (America/Sao_Paulo); semana começa na segunda.
- Testes: `.\gradlew.bat test --console=plain` (sequencial; não rodar dois Gradle ao mesmo tempo). Não criar combinação nova de `@MockitoBean`/`@TestPropertySource` em `@SpringBootTest` (OOM de contexto) — reusar `@SpringBootTest @AutoConfigureMockMvc @ActiveProfiles("test") @Transactional`.
- Pisos JaCoCo: `com.focux.modules.dashboard` ≥ 0.80 (existente); novo `com.focux.modules.dashboard.insights` ≥ 0.90.

---

### Task 1: Parser único de repetições

**Files:**
- Create: `src/main/java/com/focux/modules/checkin/RepeticoesParser.java`
- Modify: `src/main/java/com/focux/modules/checkin/CheckinEvolucaoAnalyzer.java:133-178`
- Modify: `src/main/java/com/focux/modules/alunos/EvolucaoInteligenteService.java:276-297`
- Test: `src/test/java/com/focux/modules/checkin/RepeticoesParserTest.java`

**Interfaces:**
- Produces: `public static Integer RepeticoesParser.primeiroInteiro(String raw)` — primeiro inteiro do texto; `null` se vazio/sem dígito.

- [ ] **Step 1: Write the failing test**

```java
package com.focux.modules.checkin;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class RepeticoesParserTest {

    @Test
    void faixaUsaOPrimeiroNumero() {
        assertThat(RepeticoesParser.primeiroInteiro("8-12")).isEqualTo(8);
        assertThat(RepeticoesParser.primeiroInteiro(" 10 ")).isEqualTo(10);
        assertThat(RepeticoesParser.primeiroInteiro("12x")).isEqualTo(12);
    }

    @Test
    void semDigitoDevolveNull() {
        assertThat(RepeticoesParser.primeiroInteiro(null)).isNull();
        assertThat(RepeticoesParser.primeiroInteiro("")).isNull();
        assertThat(RepeticoesParser.primeiroInteiro("   ")).isNull();
        assertThat(RepeticoesParser.primeiroInteiro("até a falha")).isNull();
    }

    @Test
    void numeroGiganteNaoEstoura() {
        assertThat(RepeticoesParser.primeiroInteiro("99999999999")).isNull();
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `.\gradlew.bat test --console=plain --tests "com.focux.modules.checkin.RepeticoesParserTest"`
Expected: FAIL — `cannot find symbol: class RepeticoesParser`.

- [ ] **Step 3: Write the implementation**

```java
package com.focux.modules.checkin;

import java.util.regex.Pattern;

/** Regra única de repetições: "8-12" conta 8; texto sem número não conta. */
public final class RepeticoesParser {

    private static final Pattern PRIMEIRO_INTEIRO = Pattern.compile("\\d+");

    private RepeticoesParser() {}

    public static Integer primeiroInteiro(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        var matcher = PRIMEIRO_INTEIRO.matcher(raw);
        if (!matcher.find()) {
            return null;
        }
        try {
            return Integer.parseInt(matcher.group());
        } catch (NumberFormatException ignored) {
            return null;
        }
    }
}
```

- [ ] **Step 4: Adotar o parser no analyzer**

Em `CheckinEvolucaoAnalyzer.java`, trocar `.map(this::primeiroNumero)` (linha ~137) por `.map(RepeticoesParser::primeiroInteiro)` e `var reps = primeiroNumero(serie.getRepeticoes());` (linha ~146) por `var reps = RepeticoesParser.primeiroInteiro(serie.getRepeticoes());`. Apagar o método `public Integer primeiroNumero(String value)` inteiro (linhas ~165-178). O único outro caller (`AlunoHomeVolume`) é reescrito na Task 2 — até lá o build quebra; faça a Task 2 no mesmo commit se preferir compilar entre tasks, ou troque temporariamente a linha 58 de `AlunoHomeVolume` por `Integer reps = RepeticoesParser.primeiroInteiro(linha[1] == null ? null : linha[1].toString());` (import `com.focux.modules.checkin.RepeticoesParser`).

- [ ] **Step 5: Adotar o parser na evolução inteligente (personal)**

Em `EvolucaoInteligenteService.java`, substituir `volumeSerie` e apagar `parseReps`:

```java
    private static double volumeSerie(SerieCtx s) {
        Integer reps = RepeticoesParser.primeiroInteiro(s.repeticoes());
        if (s.cargaKg() == null || reps == null) {
            return 0;
        }
        return s.cargaKg().doubleValue() * reps;
    }
```

Import: `import com.focux.modules.checkin.RepeticoesParser;`. Efeito aceito pela spec: série sem repetição deixa de contar como 10 no painel do personal.

- [ ] **Step 6: Run tests**

Run: `.\gradlew.bat test --console=plain --tests "com.focux.modules.checkin.*" --tests "com.focux.modules.alunos.EvolucaoInteligenteServiceTest" --tests "com.focux.modules.dashboard.AlunoHomeVolumeTest"`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add src/main/java/com/focux/modules/checkin/RepeticoesParser.java src/main/java/com/focux/modules/checkin/CheckinEvolucaoAnalyzer.java src/main/java/com/focux/modules/alunos/EvolucaoInteligenteService.java src/main/java/com/focux/modules/dashboard/AlunoHomeVolume.java src/test/java/com/focux/modules/checkin/RepeticoesParserTest.java
git -c user.name="Matheus Oliveira" -c user.email="matheusos1912@icloud.com" commit -m "fix(checkin): uma regra só para contar repetições"
```

---

### Task 2: Força por 1RM estimado + volume tipado

**Files:**
- Create: `src/main/java/com/focux/modules/dashboard/AlunoHomeSerie.java`
- Create: `src/main/java/com/focux/modules/dashboard/AlunoHomeForca.java`
- Modify (rewrite): `src/main/java/com/focux/modules/dashboard/AlunoHomeVolume.java`
- Modify: `src/main/java/com/focux/modules/checkin/ExecucaoSerieRepository.java:84-97`
- Test: `src/test/java/com/focux/modules/dashboard/AlunoHomeForcaTest.java`
- Test (update): `src/test/java/com/focux/modules/dashboard/AlunoHomeVolumeTest.java`

**Interfaces:**
- Consumes: `RepeticoesParser.primeiroInteiro(String)` (Task 1).
- Produces:
  - `record AlunoHomeSerie(Long exercicioId, double cargaKg, int reps, LocalDateTime quando)` + `static AlunoHomeSerie fromRow(Object[] row)` (null se inválida).
  - `AlunoHomeForca.calcular(List<AlunoHomeSerie>, LocalDate semanaAtualSegunda) -> Resultado(List<Double> porSemana, Double deltaPercent, int exerciciosComuns)`; `static double e1rm(double, int)`.
  - `AlunoHomeVolume.somar(List<AlunoHomeSerie> series, LocalDateTime inicioSemana, LocalDateTime inicioMes, LocalDate semanaAtualSegunda) -> Resumo(double semanaKg, double mesKg, List<Double> volumePorSemana, List<Double> forcaPorSemana, Double forcaDeltaPercent, int forcaExerciciosComuns)`; `emptyResumo()`; `weekBucket(...)` inalterado; `WEEKS = 8`.
  - Query `findVolumeLinhasDesde` passa a devolver `[cargaKg, repeticoes, quando, exercicioId]`.

- [ ] **Step 1: Write the failing tests**

`AlunoHomeForcaTest.java`:

```java
package com.focux.modules.dashboard;

import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

class AlunoHomeForcaTest {

    private static final LocalDate SEGUNDA = LocalDate.of(2026, 9, 14);

    private static AlunoHomeSerie serie(long exercicioId, double carga, int reps, LocalDate dia) {
        return new AlunoHomeSerie(exercicioId, carga, reps, dia.atTime(10, 0));
    }

    @Test
    void e1rmUsaEpley() {
        assertThat(AlunoHomeForca.e1rm(100, 10)).isCloseTo(133.33, within(0.01));
    }

    @Test
    void comparaSoExerciciosComunsComMelhorSerieDaSemana() {
        var atual = SEGUNDA.plusDays(1);
        var anterior = SEGUNDA.minusWeeks(1).plusDays(1);
        var resultado = AlunoHomeForca.calcular(List.of(
            serie(1, 100, 5, atual),
            serie(1, 90, 8, atual),
            serie(2, 50, 10, atual),
            serie(1, 100, 3, anterior),
            serie(2, 50, 8, anterior),
            serie(3, 200, 5, anterior)
        ), SEGUNDA);

        assertThat(resultado.exerciciosComuns()).isEqualTo(2);
        assertThat(resultado.deltaPercent()).isEqualTo(5.7);
        assertThat(resultado.porSemana()).hasSize(AlunoHomeVolume.WEEKS);
        assertThat(resultado.porSemana().get(7)).isEqualTo(91.7);
    }

    @Test
    void ignoraSeriesComMaisDe12RepsOuSemCarga() {
        var resultado = AlunoHomeForca.calcular(List.of(
            serie(1, 60, 15, SEGUNDA),
            serie(1, 60, 15, SEGUNDA.minusWeeks(1)),
            serie(2, 0, 10, SEGUNDA)
        ), SEGUNDA);

        assertThat(resultado.porSemana()).containsOnly(0.0);
        assertThat(resultado.deltaPercent()).isNull();
        assertThat(resultado.exerciciosComuns()).isZero();
    }

    @Test
    void menosDeDoisExerciciosComunsNaoGeraVariacao() {
        var resultado = AlunoHomeForca.calcular(List.of(
            serie(1, 100, 5, SEGUNDA),
            serie(1, 90, 5, SEGUNDA.minusWeeks(1))
        ), SEGUNDA);

        assertThat(resultado.exerciciosComuns()).isEqualTo(1);
        assertThat(resultado.deltaPercent()).isNull();
    }

    @Test
    void listaNulaDevolveSerieZerada() {
        var resultado = AlunoHomeForca.calcular(null, SEGUNDA);
        assertThat(resultado.porSemana()).hasSize(8).containsOnly(0.0);
        assertThat(resultado.deltaPercent()).isNull();
    }
}
```

Substituir o conteúdo de `AlunoHomeVolumeTest.java` (contrato muda: sem analyzer, força vira 1RM estimado):

```java
package com.focux.modules.dashboard;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class AlunoHomeVolumeTest {

    @Test
    void weekBucketMapsCurrentAndPastWeeks() {
        LocalDate monday = LocalDate.of(2026, 9, 14); // Monday
        assertThat(AlunoHomeVolume.weekBucket(monday, monday))
            .isEqualTo(AlunoHomeVolume.WEEKS - 1);
        assertThat(AlunoHomeVolume.weekBucket(monday.minusWeeks(1), monday))
            .isEqualTo(AlunoHomeVolume.WEEKS - 2);
        assertThat(AlunoHomeVolume.weekBucket(monday.minusWeeks(8), monday))
            .isEqualTo(-1);
    }

    @Test
    void somarBuildsWeeklySeries() {
        LocalDate monday = LocalDate.of(2026, 9, 14);
        LocalDateTime inicioSemana = monday.atStartOfDay();
        LocalDateTime inicioMes = LocalDate.of(2026, 9, 1).atStartOfDay();
        var series = List.of(
            new AlunoHomeSerie(1L, 40, 10, monday.atTime(10, 0)),
            new AlunoHomeSerie(1L, 50, 8, monday.minusWeeks(1).atTime(10, 0))
        );
        var resumo = AlunoHomeVolume.somar(series, inicioSemana, inicioMes, monday);

        assertThat(resumo.semanaKg()).isEqualTo(400.0);
        assertThat(resumo.mesKg()).isEqualTo(800.0);
        assertThat(resumo.volumePorSemana()).hasSize(8);
        assertThat(resumo.volumePorSemana().get(7)).isEqualTo(400.0);
        assertThat(resumo.volumePorSemana().get(6)).isEqualTo(400.0);
        assertThat(resumo.forcaPorSemana().get(7)).isEqualTo(53.3);
        assertThat(resumo.forcaPorSemana().get(6)).isEqualTo(63.3);
        assertThat(resumo.forcaDeltaPercent()).isNull();
        assertThat(resumo.forcaExerciciosComuns()).isEqualTo(1);
    }

    @Test
    void fromRowLeProjecaoDaQuery() {
        LocalDateTime quando = LocalDateTime.of(2026, 9, 15, 9, 0);
        var ok = AlunoHomeSerie.fromRow(new Object[] {BigDecimal.valueOf(82.5), "8-12", quando, 7L});
        assertThat(ok).isEqualTo(new AlunoHomeSerie(7L, 82.5, 8, quando));
        assertThat(AlunoHomeSerie.fromRow(new Object[] {BigDecimal.TEN, "", quando, 7L})).isNull();
        assertThat(AlunoHomeSerie.fromRow(new Object[] {null, "10", quando, 7L})).isNull();
        assertThat(AlunoHomeSerie.fromRow(new Object[] {BigDecimal.TEN, "10", quando})).extracting(AlunoHomeSerie::exercicioId).isNull();
        assertThat(AlunoHomeSerie.fromRow(null)).isNull();
    }

    @Test
    void emptyResumoTemOitoSemanasZeradas() {
        var vazio = AlunoHomeVolume.emptyResumo();
        assertThat(vazio.volumePorSemana()).hasSize(8).containsOnly(0.0);
        assertThat(vazio.forcaPorSemana()).hasSize(8).containsOnly(0.0);
        assertThat(vazio.forcaDeltaPercent()).isNull();
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `.\gradlew.bat test --console=plain --tests "com.focux.modules.dashboard.AlunoHomeForcaTest" --tests "com.focux.modules.dashboard.AlunoHomeVolumeTest"`
Expected: FAIL — `cannot find symbol: class AlunoHomeSerie`.

- [ ] **Step 3: Create `AlunoHomeSerie.java`**

```java
package com.focux.modules.dashboard;

import com.focux.infra.time.FocuxClock;
import com.focux.modules.checkin.RepeticoesParser;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** Série concluída já tipada, a partir de uma linha de {@code findVolumeLinhasDesde}. */
record AlunoHomeSerie(Long exercicioId, double cargaKg, int reps, LocalDateTime quando) {

    /** Null quando falta carga, repetição legível ou data. */
    static AlunoHomeSerie fromRow(Object[] row) {
        if (row == null || row.length < 3) {
            return null;
        }
        Double carga = toDouble(row[0]);
        Integer reps = RepeticoesParser.primeiroInteiro(row[1] == null ? null : row[1].toString());
        LocalDateTime quando = toLocalDateTime(row[2]);
        if (carga == null || reps == null || quando == null) {
            return null;
        }
        Long exercicioId = row.length > 3 && row[3] instanceof Number n ? n.longValue() : null;
        return new AlunoHomeSerie(exercicioId, carga, reps, quando);
    }

    private static Double toDouble(Object value) {
        if (value instanceof BigDecimal bd) {
            return bd.doubleValue();
        }
        if (value instanceof Number number) {
            return number.doubleValue();
        }
        return null;
    }

    private static LocalDateTime toLocalDateTime(Object value) {
        if (value instanceof LocalDateTime ldt) {
            return ldt;
        }
        if (value instanceof java.sql.Timestamp ts) {
            return ts.toLocalDateTime();
        }
        if (value instanceof java.time.Instant instant) {
            return LocalDateTime.ofInstant(instant, FocuxClock.zone());
        }
        return null;
    }
}
```

- [ ] **Step 4: Create `AlunoHomeForca.java`**

```java
package com.focux.modules.dashboard;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** Força = 1RM estimado (Epley) da melhor série por exercício e semana. */
final class AlunoHomeForca {

    static final int REPS_MAX_EPLEY = 12;
    static final int MIN_EXERCICIOS_COMUNS = 2;

    record Resultado(List<Double> porSemana, Double deltaPercent, int exerciciosComuns) {}

    private AlunoHomeForca() {}

    static double e1rm(double cargaKg, int reps) {
        return cargaKg * (1 + reps / 30.0);
    }

    static Resultado calcular(List<AlunoHomeSerie> series, LocalDate semanaAtualSegunda) {
        int weeks = AlunoHomeVolume.WEEKS;
        List<Map<Long, Double>> melhores = new ArrayList<>(weeks);
        for (int i = 0; i < weeks; i++) {
            melhores.add(new HashMap<>());
        }
        if (series != null) {
            for (var s : series) {
                if (!valida(s)) {
                    continue;
                }
                int w = AlunoHomeVolume.weekBucket(s.quando().toLocalDate(), semanaAtualSegunda);
                if (w < 0) {
                    continue;
                }
                melhores.get(w).merge(s.exercicioId(), e1rm(s.cargaKg(), s.reps()), Math::max);
            }
        }
        List<Double> porSemana = new ArrayList<>(weeks);
        for (var semana : melhores) {
            porSemana.add(semana.isEmpty()
                ? 0.0
                : round1(semana.values().stream().mapToDouble(Double::doubleValue).average().orElse(0)));
        }
        var atual = melhores.get(weeks - 1);
        var anterior = melhores.get(weeks - 2);
        var comuns = atual.keySet().stream().filter(anterior::containsKey).toList();
        if (comuns.size() < MIN_EXERCICIOS_COMUNS) {
            return new Resultado(porSemana, null, comuns.size());
        }
        double media = comuns.stream()
            .mapToDouble(id -> (atual.get(id) - anterior.get(id)) / anterior.get(id) * 100.0)
            .average()
            .orElse(0);
        return new Resultado(porSemana, round1(media), comuns.size());
    }

    private static boolean valida(AlunoHomeSerie s) {
        return s != null
            && s.exercicioId() != null
            && s.cargaKg() > 0
            && s.reps() >= 1
            && s.reps() <= REPS_MAX_EPLEY;
    }

    static double round1(double v) {
        return Math.round(v * 10.0) / 10.0;
    }
}
```

- [ ] **Step 5: Rewrite `AlunoHomeVolume.java`**

```java
package com.focux.modules.dashboard;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/** Volume carga×reps e força (1RM estimado) por semana, a partir de séries tipadas. */
final class AlunoHomeVolume {

    static final int WEEKS = 8;

    record Resumo(
        double semanaKg,
        double mesKg,
        List<Double> volumePorSemana,
        List<Double> forcaPorSemana,
        Double forcaDeltaPercent,
        int forcaExerciciosComuns
    ) {
        Resumo {
            volumePorSemana = volumePorSemana == null ? List.of() : List.copyOf(volumePorSemana);
            forcaPorSemana = forcaPorSemana == null ? List.of() : List.copyOf(forcaPorSemana);
        }
    }

    private AlunoHomeVolume() {}

    static Resumo somar(
        List<AlunoHomeSerie> series,
        LocalDateTime inicioSemana,
        LocalDateTime inicioMes,
        LocalDate semanaAtualSegunda
    ) {
        if (series == null) {
            return emptyResumo();
        }
        double semana = 0;
        double mes = 0;
        double[] vol = new double[WEEKS];
        for (var s : series) {
            if (s == null) {
                continue;
            }
            double add = s.cargaKg() * s.reps();
            if (!s.quando().isBefore(inicioMes)) {
                mes += add;
            }
            if (!s.quando().isBefore(inicioSemana)) {
                semana += add;
            }
            int weekIndex = weekBucket(s.quando().toLocalDate(), semanaAtualSegunda);
            if (weekIndex >= 0) {
                vol[weekIndex] += add;
            }
        }
        var forca = AlunoHomeForca.calcular(series, semanaAtualSegunda);
        List<Double> volumeSeries = new ArrayList<>(WEEKS);
        for (double v : vol) {
            volumeSeries.add(v);
        }
        return new Resumo(
            semana, mes, volumeSeries, forca.porSemana(), forca.deltaPercent(), forca.exerciciosComuns()
        );
    }

    static Resumo emptyResumo() {
        return new Resumo(
            0, 0, Collections.nCopies(WEEKS, 0.0), Collections.nCopies(WEEKS, 0.0), null, 0
        );
    }

    /** 0 = semana mais antiga (WEEKS-1 atrás); WEEKS-1 = semana atual. */
    static int weekBucket(LocalDate quando, LocalDate semanaAtualSegunda) {
        LocalDate segunda = quando.with(DayOfWeek.MONDAY);
        long weeksAgo = ChronoUnit.WEEKS.between(segunda, semanaAtualSegunda);
        if (weeksAgo < 0 || weeksAgo >= WEEKS) {
            return -1;
        }
        return (int) (WEEKS - 1 - weeksAgo);
    }
}
```

- [ ] **Step 6: Incluir `exercicioId` na query**

Em `ExecucaoSerieRepository.java`, substituir a `@Query` de `findVolumeLinhasDesde`:

```java
    @Query("""
        select s.cargaKg, s.repeticoes, coalesce(ex.concluidoEm, ex.iniciadoEm), te.exercicio.id
        from ExecucaoSerie s
        join s.execucaoExercicio ee
        join ee.execucaoTreino ex
        join ee.treinoExercicio te
        where ex.aluno.id = :alunoId
          and ex.status = 'CONCLUIDO'
          and coalesce(ex.concluidoEm, ex.iniciadoEm) >= :desde
        """)
```

- [ ] **Step 7: Ajustar o caller temporário no service**

Em `AlunoDashboardService.volumeResumo` (reescrito por completo na Task 6), trocar o corpo do `return` para compilar agora:

```java
        var series = execucaoSerieRepo.findVolumeLinhasDesde(alunoId, desdeSeries).stream()
            .map(AlunoHomeSerie::fromRow)
            .filter(java.util.Objects::nonNull)
            .toList();
        return AlunoHomeVolume.somar(series, inicioSemana, inicioMes, semanaSegunda);
```

Remover o campo/parâmetro `CheckinEvolucaoAnalyzer evolucaoAnalyzer` do construtor do service e o import (não há outro uso no arquivo).

- [ ] **Step 8: Run tests**

Run: `.\gradlew.bat test --console=plain --tests "com.focux.modules.dashboard.*"`
Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add src/main/java/com/focux/modules/dashboard/AlunoHomeSerie.java src/main/java/com/focux/modules/dashboard/AlunoHomeForca.java src/main/java/com/focux/modules/dashboard/AlunoHomeVolume.java src/main/java/com/focux/modules/dashboard/AlunoDashboardService.java src/main/java/com/focux/modules/checkin/ExecucaoSerieRepository.java src/test/java/com/focux/modules/dashboard/AlunoHomeForcaTest.java src/test/java/com/focux/modules/dashboard/AlunoHomeVolumeTest.java
git -c user.name="Matheus Oliveira" -c user.email="matheusos1912@icloud.com" commit -m "feat(dashboard): força do aluno por 1RM estimado"
```

---

### Task 3: Sequência que não congela + prontidão com idade

**Files:**
- Modify: `src/main/java/com/focux/modules/checkin/CheckinStreakWeeks.java` (novo método)
- Create: `src/main/java/com/focux/modules/dashboard/AlunoHomeRecovery.java`
- Test: `src/test/java/com/focux/modules/checkin/CheckinStreakWeeksTest.java` (adicionar testes)
- Test: `src/test/java/com/focux/modules/dashboard/AlunoHomeRecoveryTest.java`

**Interfaces:**
- Produces:
  - `public static int CheckinStreakWeeks.countAtivo(LocalDate today, Iterable<LocalDate> workoutDates)`.
  - `AlunoHomeRecovery.avaliar(RecoverySnapshotResponse latest, LocalDate hoje) -> Estado(RecoverySnapshotResponse snapshot, boolean stale)`.

- [ ] **Step 1: Write the failing tests**

Adicionar ao final da classe `CheckinStreakWeeksTest` (imports já existentes: `LocalDate`, `List`, `assertThat` — confira e adicione os que faltarem):

```java
    @Test
    void countAtivoNaoQuebraNaSemanaAtualAindaVazia() {
        LocalDate quarta = LocalDate.of(2026, 9, 16);
        var datas = List.of(LocalDate.of(2026, 9, 8), LocalDate.of(2026, 9, 1));
        assertThat(CheckinStreakWeeks.countFromDates(quarta, datas)).isZero();
        assertThat(CheckinStreakWeeks.countAtivo(quarta, datas)).isEqualTo(2);
    }

    @Test
    void countAtivoContaSemanaAtualQuandoTemTreino() {
        LocalDate quarta = LocalDate.of(2026, 9, 16);
        var datas = List.of(
            LocalDate.of(2026, 9, 15), LocalDate.of(2026, 9, 8), LocalDate.of(2026, 9, 1)
        );
        assertThat(CheckinStreakWeeks.countAtivo(quarta, datas)).isEqualTo(3);
    }

    @Test
    void countAtivoZeraQuandoPassouUmaSemanaInteiraSemTreino() {
        LocalDate quarta = LocalDate.of(2026, 9, 16);
        assertThat(CheckinStreakWeeks.countAtivo(quarta, List.of(LocalDate.of(2026, 8, 31)))).isZero();
        assertThat(CheckinStreakWeeks.countAtivo(null, List.of())).isZero();
    }
```

`AlunoHomeRecoveryTest.java`:

```java
package com.focux.modules.dashboard;

import com.focux.modules.health.dto.RecoverySnapshotResponse;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

class AlunoHomeRecoveryTest {

    private static final LocalDate HOJE = LocalDate.of(2026, 9, 16);

    private static RecoverySnapshotResponse snap(LocalDate data) {
        return new RecoverySnapshotResponse(data, 8000, 400, 60, 7.5, 80, "Pronto para pesar", "Dica", HOJE.atStartOfDay());
    }

    @Test
    void hojeEOntemValem() {
        assertThat(AlunoHomeRecovery.avaliar(snap(HOJE), HOJE).snapshot()).isNotNull();
        var ontem = AlunoHomeRecovery.avaliar(snap(HOJE.minusDays(1)), HOJE);
        assertThat(ontem.snapshot()).isNotNull();
        assertThat(ontem.stale()).isFalse();
    }

    @Test
    void anteontemViraStale() {
        var estado = AlunoHomeRecovery.avaliar(snap(HOJE.minusDays(2)), HOJE);
        assertThat(estado.snapshot()).isNull();
        assertThat(estado.stale()).isTrue();
    }

    @Test
    void semSnapshotNaoEStale() {
        var estado = AlunoHomeRecovery.avaliar(null, HOJE);
        assertThat(estado.snapshot()).isNull();
        assertThat(estado.stale()).isFalse();
    }

    @Test
    void snapshotSemDataViraStale() {
        var estado = AlunoHomeRecovery.avaliar(snap(null), HOJE);
        assertThat(estado.snapshot()).isNull();
        assertThat(estado.stale()).isTrue();
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `.\gradlew.bat test --console=plain --tests "com.focux.modules.checkin.CheckinStreakWeeksTest" --tests "com.focux.modules.dashboard.AlunoHomeRecoveryTest"`
Expected: FAIL — `cannot find symbol: method countAtivo` / `class AlunoHomeRecovery`.

- [ ] **Step 3: Implement `countAtivo`**

Adicionar em `CheckinStreakWeeks.java`, logo após `countFromDates`:

```java
    /** Como {@link #countFromDates}, mas a semana ISO atual sem treino ainda não quebra a sequência. */
    public static int countAtivo(LocalDate today, Iterable<LocalDate> workoutDates) {
        if (today == null) {
            return 0;
        }
        int atual = countFromDates(today, workoutDates);
        return atual > 0 ? atual : countFromDates(today.minusWeeks(1), workoutDates);
    }
```

- [ ] **Step 4: Create `AlunoHomeRecovery.java`**

```java
package com.focux.modules.dashboard;

import com.focux.modules.health.dto.RecoverySnapshotResponse;

import java.time.LocalDate;

/** Prontidão só vale se o dado for de hoje ou de ontem. */
final class AlunoHomeRecovery {

    record Estado(RecoverySnapshotResponse snapshot, boolean stale) {}

    private AlunoHomeRecovery() {}

    static Estado avaliar(RecoverySnapshotResponse latest, LocalDate hoje) {
        if (latest == null) {
            return new Estado(null, false);
        }
        LocalDate data = latest.dataReferencia();
        if (data == null || data.isBefore(hoje.minusDays(1))) {
            return new Estado(null, true);
        }
        return new Estado(latest, false);
    }
}
```

- [ ] **Step 5: Run tests**

Run: `.\gradlew.bat test --console=plain --tests "com.focux.modules.checkin.CheckinStreakWeeksTest" --tests "com.focux.modules.dashboard.AlunoHomeRecoveryTest"`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add src/main/java/com/focux/modules/checkin/CheckinStreakWeeks.java src/main/java/com/focux/modules/dashboard/AlunoHomeRecovery.java src/test/java/com/focux/modules/checkin/CheckinStreakWeeksTest.java src/test/java/com/focux/modules/dashboard/AlunoHomeRecoveryTest.java
git -c user.name="Matheus Oliveira" -c user.email="matheusos1912@icloud.com" commit -m "fix(dashboard): sequência e prontidão sem dado velho"
```

---

### Task 4: Motor Focux Insights

**Files:**
- Create: `src/main/java/com/focux/modules/dashboard/insights/InsightTipo.java`
- Create: `src/main/java/com/focux/modules/dashboard/insights/InsightConfianca.java`
- Create: `src/main/java/com/focux/modules/dashboard/insights/AlunoInsight.java`
- Create: `src/main/java/com/focux/modules/dashboard/insights/AlunoInsightInput.java`
- Create: `src/main/java/com/focux/modules/dashboard/insights/AlunoInsightLimites.java`
- Create: `src/main/java/com/focux/modules/dashboard/insights/AlunoInsightRule.java`
- Create: `src/main/java/com/focux/modules/dashboard/insights/AlunoInsightRegras.java`
- Create: `src/main/java/com/focux/modules/dashboard/insights/AlunoInsightEngine.java`
- Modify: `build.gradle` (regra JaCoCo, após a regra de `com.focux.modules.dashboard`)
- Test: `src/test/java/com/focux/modules/dashboard/insights/AlunoInsightEngineTest.java`

**Interfaces:**
- Produces (todos `public`, pacote `com.focux.modules.dashboard.insights`):
  - `enum InsightTipo { NOVO, RECUPERACAO, PR, RETORNO, META_ATINGIDA, FORCA_SUBINDO, VOLUME_SUBINDO, CONSISTENTE, RITMO_CAIU, DADOS_INSUFICIENTES }`
  - `enum InsightConfianca { HIGH, MEDIUM, LOW }`
  - `record AlunoInsight(InsightTipo tipo, InsightConfianca confianca, String chave, Map<String, String> params, String titulo, String mensagem, String evidencia, Acao acao)` com `record Acao(String rota, String cta)`.
  - `record AlunoInsightInput(LocalDate hoje, int totalConcluidos, int concluidosSemanaIso, int concluidos7d, int concluidos28dAnteriores, Long diasSemTreino, Integer frequenciaDias, int streakSemanas, Integer recoveryScore, UltimoRecorde ultimoRecorde, Double forcaDeltaPercent, int forcaExerciciosComuns, List<Double> volumePorSemana)` com `record UltimoRecorde(String exercicioNome, BigDecimal cargaKg, LocalDate data)`.
  - `AlunoInsightEngine.avaliar(AlunoInsightInput) -> AlunoInsight` (nunca null).
- Chaves e params (contrato com o app): `insightNovo` {}, `insightRecuperacao` {score}, `insightPr` {exercicio, cargaKg, dias}, `insightRetorno` {dias}, `insightMetaAtingida` {feitos, meta}, `insightForcaSubindo` {pct, n}, `insightVolumeSubindo` {pct}, `insightConsistente` {feitos}, `insightSequencia` {semanas}, `insightRitmoCaiu` {feitos}, `insightDadosInsuficientes` {}. Números em params: sem locale (ponto decimal).

- [ ] **Step 1: Write the failing test**

```java
package com.focux.modules.dashboard.insights;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class AlunoInsightEngineTest {

    private static final LocalDate HOJE = LocalDate.of(2026, 9, 16);

    /** Aluno "neutro": nenhuma regra específica dispara. */
    private static final class In {
        int total = 2;
        int semana = 1;
        int c7 = 1;
        int ant28 = 0;
        Long dias = 2L;
        Integer meta = 3;
        int streak = 1;
        Integer recovery = null;
        AlunoInsightInput.UltimoRecorde recorde = null;
        Double forca = null;
        int comuns = 0;
        List<Double> volume = new ArrayList<>(Collections.nCopies(8, 0.0));

        AlunoInsightInput build() {
            return new AlunoInsightInput(HOJE, total, semana, c7, ant28, dias, meta, streak,
                recovery, recorde, forca, comuns, volume);
        }
    }

    private static AlunoInsight avaliar(In in) {
        return AlunoInsightEngine.avaliar(in.build());
    }

    private static AlunoInsightInput.UltimoRecorde recorde(int diasAtras) {
        return new AlunoInsightInput.UltimoRecorde("Supino", new BigDecimal("82.50"), HOJE.minusDays(diasAtras));
    }

    // Cenários do prompt (1–7)

    @Test
    void cenario1_alunoNovo() {
        var in = new In();
        in.total = 0; in.semana = 0; in.c7 = 0; in.dias = null;
        var insight = avaliar(in);
        assertThat(insight.tipo()).isEqualTo(InsightTipo.NOVO);
        assertThat(insight.confianca()).isEqualTo(InsightConfianca.HIGH);
        assertThat(insight.acao().rota()).isEqualTo("/checkin/treinos");
    }

    @Test
    void cenario2_quatroTreinosComMetaDois() {
        var in = new In();
        in.total = 10; in.semana = 4; in.c7 = 4; in.meta = 2;
        var insight = avaliar(in);
        assertThat(insight.tipo()).isEqualTo(InsightTipo.META_ATINGIDA);
        assertThat(insight.mensagem()).isEqualTo("4 de 2 treinos nesta semana");
        assertThat(insight.params()).containsEntry("feitos", "4").containsEntry("meta", "2");
    }

    @Test
    void cenario3_volumeSubiu() {
        var in = new In();
        in.volume = List.of(100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 130.0, 20.0);
        var insight = avaliar(in);
        assertThat(insight.tipo()).isEqualTo(InsightTipo.VOLUME_SUBINDO);
        assertThat(insight.confianca()).isEqualTo(InsightConfianca.MEDIUM);
        assertThat(insight.params()).containsEntry("pct", "30");
    }

    @Test
    void cenario4_novoPr() {
        var in = new In();
        in.recorde = recorde(2);
        var insight = avaliar(in);
        assertThat(insight.tipo()).isEqualTo(InsightTipo.PR);
        assertThat(insight.mensagem()).isEqualTo("Supino: 82,5 kg");
        assertThat(insight.evidencia()).isEqualTo("Registrado há 2 dias");
        assertThat(insight.params()).containsEntry("cargaKg", "82.5").containsEntry("dias", "2");
        assertThat(insight.acao().rota()).isEqualTo("/checkin/historico");
    }

    @Test
    void cenario5_variosDiasSemTreino() {
        var in = new In();
        in.dias = 10L; in.c7 = 0; in.semana = 0;
        var insight = avaliar(in);
        assertThat(insight.tipo()).isEqualTo(InsightTipo.RETORNO);
        assertThat(insight.evidencia()).isEqualTo("10 dias sem treinar");
    }

    @Test
    void cenario6_dadosInsuficientesNaoGeraNumero() {
        var insight = avaliar(new In());
        assertThat(insight.tipo()).isEqualTo(InsightTipo.DADOS_INSUFICIENTES);
        assertThat(insight.confianca()).isEqualTo(InsightConfianca.LOW);
        assertThat(insight.params()).isEmpty();
        assertThat(insight.evidencia()).isNull();
        assertThat(insight.acao()).isNull();
        assertThat(insight.mensagem()).doesNotContainPattern("\\d");
    }

    @Test
    void cenario7_multiplosSinaisMostraSoPr() {
        var in = new In();
        in.recorde = recorde(1);
        in.semana = 4; in.c7 = 4; in.meta = 2; in.total = 20;
        in.forca = 6.0; in.comuns = 5;
        in.volume = List.of(100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 150.0, 0.0);
        assertThat(avaliar(in).tipo()).isEqualTo(InsightTipo.PR);
    }

    // Limites por regra

    @Test
    void recuperacaoAbaixoDe45VenceOPr() {
        var in = new In();
        in.recovery = 44; in.recorde = recorde(1);
        var insight = avaliar(in);
        assertThat(insight.tipo()).isEqualTo(InsightTipo.RECUPERACAO);
        assertThat(insight.confianca()).isEqualTo(InsightConfianca.MEDIUM);
        assertThat(insight.acao().rota()).isEqualTo("/saude");
        in.recovery = 45;
        assertThat(avaliar(in).tipo()).isEqualTo(InsightTipo.PR);
    }

    @Test
    void prValeAteSeteDias() {
        var in = new In();
        in.recorde = recorde(7);
        assertThat(avaliar(in).tipo()).isEqualTo(InsightTipo.PR);
        in.recorde = recorde(8);
        assertThat(avaliar(in).tipo()).isEqualTo(InsightTipo.DADOS_INSUFICIENTES);
        in.recorde = recorde(0);
        assertThat(avaliar(in).evidencia()).isEqualTo("Registrado hoje");
        in.recorde = recorde(1);
        assertThat(avaliar(in).evidencia()).isEqualTo("Registrado ontem");
    }

    @Test
    void retornoComecaEmSeteDias() {
        var in = new In();
        in.dias = 7L;
        assertThat(avaliar(in).tipo()).isEqualTo(InsightTipo.RETORNO);
        in.dias = 6L;
        assertThat(avaliar(in).tipo()).isEqualTo(InsightTipo.DADOS_INSUFICIENTES);
    }

    @Test
    void metaExigeMetaDefinidaEAtingida() {
        var in = new In();
        in.meta = 1; in.semana = 1;
        assertThat(avaliar(in).tipo()).isEqualTo(InsightTipo.META_ATINGIDA);
        in.meta = null;
        assertThat(avaliar(in).tipo()).isEqualTo(InsightTipo.DADOS_INSUFICIENTES);
    }

    @Test
    void forcaConfiancaDependeDosExerciciosComuns() {
        var in = new In();
        in.forca = 3.0; in.comuns = 4;
        var alta = avaliar(in);
        assertThat(alta.tipo()).isEqualTo(InsightTipo.FORCA_SUBINDO);
        assertThat(alta.confianca()).isEqualTo(InsightConfianca.HIGH);
        assertThat(alta.params()).containsEntry("pct", "3").containsEntry("n", "4");
        in.comuns = 2; in.forca = 4.5;
        var media = avaliar(in);
        assertThat(media.confianca()).isEqualTo(InsightConfianca.MEDIUM);
        assertThat(media.mensagem()).isEqualTo("+4,5% vs semana passada (2 exercícios)");
        in.forca = 2.9;
        assertThat(avaliar(in).tipo()).isEqualTo(InsightTipo.DADOS_INSUFICIENTES);
    }

    @Test
    void volumeExigeQuatroSemanasComparaveisEIgnoraSemanaAtual() {
        var in = new In();
        in.volume = List.of(0.0, 0.0, 0.0, 100.0, 100.0, 100.0, 200.0, 0.0);
        assertThat(avaliar(in).tipo()).isEqualTo(InsightTipo.DADOS_INSUFICIENTES);
        in.volume = List.of(0.0, 0.0, 100.0, 100.0, 100.0, 100.0, 110.0, 0.0);
        assertThat(avaliar(in).tipo()).isEqualTo(InsightTipo.VOLUME_SUBINDO);
        in.volume = List.of(0.0, 0.0, 100.0, 100.0, 100.0, 100.0, 109.0, 0.0);
        assertThat(avaliar(in).tipo()).isEqualTo(InsightTipo.DADOS_INSUFICIENTES);
        in.volume = List.of(100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 90.0, 900.0);
        assertThat(avaliar(in).tipo()).isEqualTo(InsightTipo.DADOS_INSUFICIENTES);
        in.volume = List.of();
        assertThat(avaliar(in).tipo()).isEqualTo(InsightTipo.DADOS_INSUFICIENTES);
    }

    @Test
    void consistentePorTreinosOuPorSequencia() {
        var in = new In();
        in.c7 = 3; in.meta = 5;
        var porTreinos = avaliar(in);
        assertThat(porTreinos.tipo()).isEqualTo(InsightTipo.CONSISTENTE);
        assertThat(porTreinos.chave()).isEqualTo("insightConsistente");
        assertThat(porTreinos.mensagem()).isEqualTo("3 treinos nos últimos 7 dias");
        in.c7 = 1; in.streak = 3;
        var porSequencia = avaliar(in);
        assertThat(porSequencia.chave()).isEqualTo("insightSequencia");
        assertThat(porSequencia.mensagem()).isEqualTo("3 semanas seguidas treinando");
    }

    @Test
    void ritmoCaiuSoComBaseSuficiente() {
        var in = new In();
        in.ant28 = 8; in.c7 = 1;
        var caiu = avaliar(in);
        assertThat(caiu.tipo()).isEqualTo(InsightTipo.RITMO_CAIU);
        assertThat(caiu.mensagem()).isEqualTo("1 treino nos últimos 7 dias");
        in.c7 = 2;
        assertThat(avaliar(in).tipo()).isEqualTo(InsightTipo.DADOS_INSUFICIENTES);
        in.ant28 = 7; in.c7 = 0;
        assertThat(avaliar(in).tipo()).isEqualTo(InsightTipo.DADOS_INSUFICIENTES);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `.\gradlew.bat test --console=plain --tests "com.focux.modules.dashboard.insights.AlunoInsightEngineTest"`
Expected: FAIL — package `com.focux.modules.dashboard.insights` does not exist.

- [ ] **Step 3: Create the types**

`InsightTipo.java`:

```java
package com.focux.modules.dashboard.insights;

public enum InsightTipo {
    NOVO, RECUPERACAO, PR, RETORNO, META_ATINGIDA,
    FORCA_SUBINDO, VOLUME_SUBINDO, CONSISTENTE, RITMO_CAIU, DADOS_INSUFICIENTES
}
```

`InsightConfianca.java`:

```java
package com.focux.modules.dashboard.insights;

public enum InsightConfianca { HIGH, MEDIUM, LOW }
```

`AlunoInsight.java`:

```java
package com.focux.modules.dashboard.insights;

import java.util.Map;

/**
 * Um insight por vez para a Home do aluno. {@code chave} + {@code params} deixam o app
 * traduzir; {@code titulo}/{@code mensagem}/{@code evidencia} são o fallback em pt.
 */
public record AlunoInsight(
    InsightTipo tipo,
    InsightConfianca confianca,
    String chave,
    Map<String, String> params,
    String titulo,
    String mensagem,
    String evidencia,
    Acao acao
) {
    public record Acao(String rota, String cta) {}

    public AlunoInsight {
        params = params == null ? Map.of() : Map.copyOf(params);
    }
}
```

`AlunoInsightInput.java`:

```java
package com.focux.modules.dashboard.insights;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/** Contagens de treino contam sessões concluídas, não dias distintos. */
public record AlunoInsightInput(
    LocalDate hoje,
    int totalConcluidos,
    int concluidosSemanaIso,
    int concluidos7d,
    int concluidos28dAnteriores,
    Long diasSemTreino,
    Integer frequenciaDias,
    int streakSemanas,
    Integer recoveryScore,
    UltimoRecorde ultimoRecorde,
    Double forcaDeltaPercent,
    int forcaExerciciosComuns,
    List<Double> volumePorSemana
) {
    public record UltimoRecorde(String exercicioNome, BigDecimal cargaKg, LocalDate data) {}

    public AlunoInsightInput {
        volumePorSemana = volumePorSemana == null ? List.of() : List.copyOf(volumePorSemana);
    }
}
```

`AlunoInsightLimites.java`:

```java
package com.focux.modules.dashboard.insights;

public final class AlunoInsightLimites {

    private AlunoInsightLimites() {}

    public static final int RECUPERACAO_BAIXA = 45;
    public static final int PR_JANELA_DIAS = 7;
    public static final int RETORNO_DIAS_SEM_TREINO = 7;
    public static final double FORCA_ALTA_PCT = 3.0;
    public static final int FORCA_EXERCICIOS_HIGH = 4;
    public static final double VOLUME_ALTA_FATOR = 1.10;
    public static final int VOLUME_SEMANAS_BASE = 6;
    public static final int VOLUME_SEMANAS_BASE_MIN = 4;
    public static final int CONSISTENTE_TREINOS_7D = 3;
    public static final int CONSISTENTE_SEMANAS = 3;
    public static final int RITMO_BASE_MIN_28D = 8;
}
```

`AlunoInsightRule.java`:

```java
package com.focux.modules.dashboard.insights;

import java.util.Optional;

@FunctionalInterface
public interface AlunoInsightRule {
    Optional<AlunoInsight> avaliar(AlunoInsightInput in);
}
```

- [ ] **Step 4: Create `AlunoInsightRegras.java`**

```java
package com.focux.modules.dashboard.insights;

import java.math.BigDecimal;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

import static com.focux.modules.dashboard.insights.AlunoInsightLimites.*;
import static com.focux.modules.dashboard.insights.InsightConfianca.*;

/** Regras determinísticas; cada função devolve vazio quando não se aplica. */
public final class AlunoInsightRegras {

    static final AlunoInsight.Acao TREINOS = new AlunoInsight.Acao("/checkin/treinos", "Ver treinos");
    static final AlunoInsight.Acao HISTORICO = new AlunoInsight.Acao("/checkin/historico", "Ver histórico");
    static final AlunoInsight.Acao SAUDE = new AlunoInsight.Acao("/saude", "Ver prontidão");

    private AlunoInsightRegras() {}

    public static Optional<AlunoInsight> novo(AlunoInsightInput in) {
        if (in.totalConcluidos() > 0) {
            return Optional.empty();
        }
        return Optional.of(new AlunoInsight(InsightTipo.NOVO, HIGH, "insightNovo", Map.of(),
            "Seu histórico começa aqui", "Complete seu primeiro treino.", null, TREINOS));
    }

    public static Optional<AlunoInsight> recuperacao(AlunoInsightInput in) {
        Integer score = in.recoveryScore();
        if (score == null || score >= RECUPERACAO_BAIXA) {
            return Optional.empty();
        }
        return Optional.of(new AlunoInsight(InsightTipo.RECUPERACAO, MEDIUM, "insightRecuperacao",
            Map.of("score", String.valueOf(score)),
            "Dia para ir mais leve",
            "Seu sono e atividade sugerem um dia mais leve. Alinhe com seu personal.",
            "Prontidão " + score + "/100", SAUDE));
    }

    public static Optional<AlunoInsight> pr(AlunoInsightInput in) {
        var r = in.ultimoRecorde();
        if (r == null || r.data() == null || r.cargaKg() == null
            || r.data().isBefore(in.hoje().minusDays(PR_JANELA_DIAS))) {
            return Optional.empty();
        }
        long dias = Math.max(0, ChronoUnit.DAYS.between(r.data(), in.hoje()));
        String nome = r.exercicioNome() == null || r.exercicioNome().isBlank() ? "Exercício" : r.exercicioNome();
        String kg = kg(r.cargaKg());
        return Optional.of(new AlunoInsight(InsightTipo.PR, HIGH, "insightPr",
            Map.of("exercicio", nome, "cargaKg", kg, "dias", String.valueOf(dias)),
            "Novo recorde", nome + ": " + pt(kg) + " kg", registrado(dias), HISTORICO));
    }

    public static Optional<AlunoInsight> retorno(AlunoInsightInput in) {
        Long dias = in.diasSemTreino();
        if (in.totalConcluidos() == 0 || dias == null || dias < RETORNO_DIAS_SEM_TREINO) {
            return Optional.empty();
        }
        return Optional.of(new AlunoInsight(InsightTipo.RETORNO, HIGH, "insightRetorno",
            Map.of("dias", String.valueOf(dias)),
            "Bora retomar", "Seu próximo treino está pronto.", dias + " dias sem treinar", TREINOS));
    }

    public static Optional<AlunoInsight> metaAtingida(AlunoInsightInput in) {
        Integer meta = in.frequenciaDias();
        int feitos = in.concluidosSemanaIso();
        if (meta == null || meta <= 0 || feitos < meta) {
            return Optional.empty();
        }
        return Optional.of(new AlunoInsight(InsightTipo.META_ATINGIDA, HIGH, "insightMetaAtingida",
            Map.of("feitos", String.valueOf(feitos), "meta", String.valueOf(meta)),
            "Meta da semana atingida", feitos + " de " + meta + " treinos nesta semana", null, TREINOS));
    }

    public static Optional<AlunoInsight> forcaSubindo(AlunoInsightInput in) {
        Double delta = in.forcaDeltaPercent();
        if (delta == null || delta < FORCA_ALTA_PCT) {
            return Optional.empty();
        }
        int n = in.forcaExerciciosComuns();
        String pct = num(delta);
        return Optional.of(new AlunoInsight(InsightTipo.FORCA_SUBINDO,
            n >= FORCA_EXERCICIOS_HIGH ? HIGH : MEDIUM, "insightForcaSubindo",
            Map.of("pct", pct, "n", String.valueOf(n)),
            "Sua força está subindo", "+" + pt(pct) + "% vs semana passada (" + n + " exercícios)",
            null, HISTORICO));
    }

    public static Optional<AlunoInsight> volumeSubindo(AlunoInsightInput in) {
        List<Double> v = in.volumePorSemana();
        int janela = VOLUME_SEMANAS_BASE + 2;
        if (v.size() < janela) {
            return Optional.empty();
        }
        double ultimaCompleta = v.get(v.size() - 2);
        var base = v.subList(v.size() - janela, v.size() - 2).stream().filter(x -> x > 0).toList();
        if (base.size() < VOLUME_SEMANAS_BASE_MIN || ultimaCompleta <= 0) {
            return Optional.empty();
        }
        double media = base.stream().mapToDouble(Double::doubleValue).average().orElse(0);
        if (media <= 0 || ultimaCompleta < media * VOLUME_ALTA_FATOR - 1e-9) {
            return Optional.empty();
        }
        String pct = String.valueOf(Math.round((ultimaCompleta / media - 1) * 100));
        return Optional.of(new AlunoInsight(InsightTipo.VOLUME_SUBINDO, MEDIUM, "insightVolumeSubindo",
            Map.of("pct", pct),
            "Seu volume está subindo", "+" + pct + "% vs média das 6 semanas anteriores", null, HISTORICO));
    }

    public static Optional<AlunoInsight> consistente(AlunoInsightInput in) {
        if (in.concluidos7d() >= CONSISTENTE_TREINOS_7D) {
            int feitos = in.concluidos7d();
            return Optional.of(new AlunoInsight(InsightTipo.CONSISTENTE, HIGH, "insightConsistente",
                Map.of("feitos", String.valueOf(feitos)),
                "Ritmo forte", treinos(feitos) + " nos últimos 7 dias", null, TREINOS));
        }
        if (in.streakSemanas() >= CONSISTENTE_SEMANAS) {
            int semanas = in.streakSemanas();
            return Optional.of(new AlunoInsight(InsightTipo.CONSISTENTE, HIGH, "insightSequencia",
                Map.of("semanas", String.valueOf(semanas)),
                "Ritmo forte", semanas + " semanas seguidas treinando", null, TREINOS));
        }
        return Optional.empty();
    }

    public static Optional<AlunoInsight> ritmoCaiu(AlunoInsightInput in) {
        int anteriores = in.concluidos28dAnteriores();
        if (anteriores < RITMO_BASE_MIN_28D) {
            return Optional.empty();
        }
        double mediaSemanal = anteriores / 4.0;
        int feitos = in.concluidos7d();
        if (feitos > mediaSemanal / 2.0) {
            return Optional.empty();
        }
        return Optional.of(new AlunoInsight(InsightTipo.RITMO_CAIU, MEDIUM, "insightRitmoCaiu",
            Map.of("feitos", String.valueOf(feitos)),
            "Seu ritmo caiu esta semana", treinos(feitos) + " nos últimos 7 dias", null, TREINOS));
    }

    public static AlunoInsight dadosInsuficientes() {
        return new AlunoInsight(InsightTipo.DADOS_INSUFICIENTES, LOW, "insightDadosInsuficientes", Map.of(),
            "Continue treinando", "Continue treinando para construirmos seu histórico.", null, null);
    }

    private static String registrado(long dias) {
        if (dias == 0) {
            return "Registrado hoje";
        }
        if (dias == 1) {
            return "Registrado ontem";
        }
        return "Registrado há " + dias + " dias";
    }

    private static String treinos(int n) {
        return n == 1 ? "1 treino" : n + " treinos";
    }

    private static String kg(BigDecimal carga) {
        return carga.stripTrailingZeros().toPlainString();
    }

    private static String num(double v) {
        return v == Math.rint(v) ? String.valueOf((long) v) : String.format(Locale.ROOT, "%.1f", v);
    }

    private static String pt(String numero) {
        return numero.replace('.', ',');
    }
}
```

- [ ] **Step 5: Create `AlunoInsightEngine.java`**

```java
package com.focux.modules.dashboard.insights;

import java.util.List;

/** Primeira regra que dispara vence; sem regra, mensagem neutra (LOW). */
public final class AlunoInsightEngine {

    private static final List<AlunoInsightRule> REGRAS = List.of(
        AlunoInsightRegras::novo,
        AlunoInsightRegras::recuperacao,
        AlunoInsightRegras::pr,
        AlunoInsightRegras::retorno,
        AlunoInsightRegras::metaAtingida,
        AlunoInsightRegras::forcaSubindo,
        AlunoInsightRegras::volumeSubindo,
        AlunoInsightRegras::consistente,
        AlunoInsightRegras::ritmoCaiu
    );

    private AlunoInsightEngine() {}

    public static AlunoInsight avaliar(AlunoInsightInput in) {
        for (AlunoInsightRule regra : REGRAS) {
            var resultado = regra.avaliar(in);
            if (resultado.isPresent()) {
                return resultado.get();
            }
        }
        return AlunoInsightRegras.dadosInsuficientes();
    }
}
```

- [ ] **Step 6: Piso de cobertura**

Em `build.gradle`, logo após o bloco `rule { ... includes = ['com.focux.modules.dashboard'] ... }`:

```groovy
        rule {
            element = 'PACKAGE'
            includes = ['com.focux.modules.dashboard.insights']
            limit { counter = 'LINE'; minimum = 0.90 }
        }
```

- [ ] **Step 7: Run tests**

Run: `.\gradlew.bat test --console=plain --tests "com.focux.modules.dashboard.insights.*"`
Expected: PASS (17 testes).

- [ ] **Step 8: Commit**

```bash
git add src/main/java/com/focux/modules/dashboard/insights src/test/java/com/focux/modules/dashboard/insights build.gradle
git -c user.name="Matheus Oliveira" -c user.email="matheusos1912@icloud.com" commit -m "feat(dashboard): motor de insights do aluno"
```

---

### Task 5: DTO do aluno sem dados internos do personal

**Files:**
- Create: `src/main/java/com/focux/modules/alunos/dto/AlunoSelfResponse.java`
- Modify: `src/main/java/com/focux/modules/alunos/AlunoAppController.java:62-70,121-125`
- Modify: `src/main/java/com/focux/modules/alunos/dto/AlunoPerfilHomeResponse.java:13-14`
- Modify: `src/main/java/com/focux/modules/alunos/AlunoPerfilHomeService.java:25-32`
- Test: `src/test/java/com/focux/modules/alunos/dto/AlunoSelfResponseTest.java`
- Test (update): `src/test/java/com/focux/modules/alunos/AlunoPerfilHomeServiceTest.java:46`
- Test (update): `src/test/java/com/focux/modules/alunos/dto/AlunoPerfilHomeResponseTest.java:30`

**Interfaces:**
- Produces: `public record AlunoSelfResponse(...)` + `public static AlunoSelfResponse from(AlunoResponse r)`; `inadimplente = r.inadimplente() || "INADIMPLENTE".equalsIgnoreCase(r.statusFinanceiro())`.

- [ ] **Step 1: Write the failing test**

```java
package com.focux.modules.alunos.dto;

import com.focux.modules.alunos.StatusAluno;
import org.junit.jupiter.api.Test;

import java.lang.reflect.RecordComponent;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class AlunoSelfResponseTest {

    private static AlunoResponse aluno(boolean inadimplente, String statusFinanceiro) {
        return new AlunoResponse(
            7L, "Aluno QA", "aluno@focux.test", "Hipertrofia", StatusAluno.ATIVO, null,
            inadimplente, true,
            null, null, null, null, statusFinanceiro,
            88, null,
            80.5, 1.78,
            LocalDate.of(1995, 3, 12), 31,
            60, 3L, "ALTO",
            LocalDate.of(2026, 9, 20), null, LocalDate.of(2026, 9, 1),
            List.of("halteres"), true, List.of());
    }

    @Test
    void mantemDadosDoProprioAluno() {
        var self = AlunoSelfResponse.from(aluno(false, "ATIVO"));
        assertThat(self.id()).isEqualTo(7L);
        assertThat(self.nome()).isEqualTo("Aluno QA");
        assertThat(self.aderenciaPercent()).isEqualTo(60);
        assertThat(self.diasSemTreino()).isEqualTo(3L);
        assertThat(self.scoreProntidao()).isEqualTo(88);
        assertThat(self.equipamentosDisponiveis()).containsExactly("halteres");
        assertThat(self.inadimplente()).isFalse();
    }

    @Test
    void naoTemCamposInternosDoPersonal() {
        var nomes = Arrays.stream(AlunoSelfResponse.class.getRecordComponents())
            .map(RecordComponent::getName)
            .toList();
        assertThat(nomes).doesNotContain(
            "emRisco", "riscoNivel", "proximoContato", "snoozedUntil",
            "ultimoContato", "operacaoFocusMode", "statusFinanceiro");
    }

    @Test
    void statusFinanceiroInadimplenteViraInadimplente() {
        assertThat(AlunoSelfResponse.from(aluno(false, "INADIMPLENTE")).inadimplente()).isTrue();
        assertThat(AlunoSelfResponse.from(aluno(true, "ATIVO")).inadimplente()).isTrue();
        assertThat(AlunoSelfResponse.from(aluno(false, null)).inadimplente()).isFalse();
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `.\gradlew.bat test --console=plain --tests "com.focux.modules.alunos.dto.AlunoSelfResponseTest"`
Expected: FAIL — `cannot find symbol: class AlunoSelfResponse`.

- [ ] **Step 3: Create `AlunoSelfResponse.java`**

```java
package com.focux.modules.alunos.dto;

import com.focux.modules.alunos.StatusAluno;

import java.time.LocalDate;
import java.util.List;

/**
 * Perfil do aluno para o próprio aluno. Sem os campos de CRM do personal
 * (risco, próximo contato, snooze, foco operacional, status financeiro interno).
 */
public record AlunoSelfResponse(
    Long id, String nome, String email,
    String objetivo, StatusAluno status, String fotoUrl,
    boolean inadimplente,
    String telefone, String whatsapp, String genero, String tipoConsultoria,
    Integer scoreProntidao,
    String senhaProvisoria,
    Double peso,
    Double altura,
    LocalDate dataNascimento,
    Integer idade,
    Integer aderenciaPercent,
    Long diasSemTreino,
    List<String> equipamentosDisponiveis,
    List<Double> aderenciaSparkline
) {
    public static AlunoSelfResponse from(AlunoResponse r) {
        boolean inadimplente = r.inadimplente() || "INADIMPLENTE".equalsIgnoreCase(r.statusFinanceiro());
        return new AlunoSelfResponse(
            r.id(), r.nome(), r.email(),
            r.objetivo(), r.status(), r.fotoUrl(),
            inadimplente,
            r.telefone(), r.whatsapp(), r.genero(), r.tipoConsultoria(),
            r.scoreProntidao(),
            r.senhaProvisoria(),
            r.peso(),
            r.altura(),
            r.dataNascimento(),
            r.idade(),
            r.aderenciaPercent(),
            r.diasSemTreino(),
            r.equipamentosDisponiveis(),
            r.aderenciaSparkline()
        );
    }
}
```

- [ ] **Step 4: Usar o DTO nas bordas do aluno**

`AlunoAppController.java` (import `com.focux.modules.alunos.dto.AlunoSelfResponse`; remover o import de `AlunoResponse` se ficar sem uso):

```java
    @GetMapping("/me")
    public AlunoSelfResponse me() {
        return AlunoSelfResponse.from(alunoService.getAlunoLogado());
    }

    @PutMapping("/me")
    public AlunoSelfResponse atualizarMe(@Valid @RequestBody AtualizarAlunoRequest req) {
        return AlunoSelfResponse.from(alunoService.atualizarAlunoLogado(req));
    }
```

e no upload:

```java
    public AlunoSelfResponse atualizarFoto(@RequestParam("file") MultipartFile file) {
        validateAlunoFoto(file);
        String url = cloudinaryService.upload(file, tenantScopedPerfilFolder(), "image");
        return AlunoSelfResponse.from(alunoService.atualizarFotoLogado(url));
    }
```

`AlunoPerfilHomeResponse.java`: trocar `AlunoResponse aluno,` por `AlunoSelfResponse aluno,`.

`AlunoPerfilHomeService.getHome`:

```java
        var aluno = alunoService.getAlunoPorIdProprio(alunoId);
        return new AlunoPerfilHomeResponse(
            AlunoSelfResponse.from(aluno),
            evolucaoService.listarMedidasComoAluno(alunoId),
            AlunoPerfilCompletion.percent(aluno)
        );
```

(import `com.focux.modules.alunos.dto.AlunoSelfResponse`).

- [ ] **Step 5: Atualizar os dois testes cujo contrato mudou**

`AlunoPerfilHomeServiceTest.java:46`: `assertThat(response.aluno()).isSameAs(aluno);` → `assertThat(response.aluno()).isEqualTo(AlunoSelfResponse.from(aluno));` (import `com.focux.modules.alunos.dto.AlunoSelfResponse`).

`AlunoPerfilHomeResponseTest.java:30`: `new AlunoPerfilHomeResponse(aluno, List.of(medida), 71);` → `new AlunoPerfilHomeResponse(AlunoSelfResponse.from(aluno), List.of(medida), 71);`.

- [ ] **Step 6: Run tests**

Run: `.\gradlew.bat test --console=plain --tests "com.focux.modules.alunos.*"`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add src/main/java/com/focux/modules/alunos src/test/java/com/focux/modules/alunos
git -c user.name="Matheus Oliveira" -c user.email="matheusos1912@icloud.com" commit -m "fix(alunos): aluno não recebe dados internos do personal"
```

---

### Task 6: BFF em 4 grupos + campos novos + insight

**Files:**
- Create: `src/main/java/com/focux/modules/dashboard/AlunoHomeInsightInputs.java`
- Modify (rewrite): `src/main/java/com/focux/modules/dashboard/AlunoDashboardService.java`
- Modify: `src/main/java/com/focux/modules/dashboard/dto/AlunoDashboardHomeResponse.java`
- Modify: `src/main/java/com/focux/modules/dashboard/AlunoDashboardHomeSurface.java:13`
- Modify: `src/main/java/com/focux/modules/monetizacao/AlunoOfertaRepository.java:10-15`
- Modify: `src/main/java/com/focux/modules/evolucao/RecordePessoalRepository.java`
- Modify: `src/main/java/com/focux/modules/evolucao/EvolucaoService.java` (método novo após `listarRecordesComoAluno`)
- Modify: `src/main/java/com/focux/modules/checkin/CheckinService.java:207-210`
- Test: `src/test/java/com/focux/modules/dashboard/AlunoHomeInsightInputsTest.java`
- Test (update): `src/test/java/com/focux/modules/dashboard/AlunoDashboardHomeResponseTest.java:30-50,102-107`
- Test (add): `src/test/java/com/focux/modules/dashboard/AlunoDashboardControllerTest.java`
- Test (add): `src/test/java/com/focux/modules/checkin/CheckinControllerTest.java`

**Interfaces:**
- Consumes: Tasks 2–5 (`AlunoHomeSerie`, `AlunoHomeVolume.Resumo`, `CheckinStreakWeeks.countAtivo`, `AlunoHomeRecovery`, `AlunoInsightEngine`, `AlunoSelfResponse`).
- Produces (JSON do BFF): `aluno` (shape `AlunoSelfResponse`), e no fim do payload `recoveryStale: boolean`, `forcaDeltaPercent: number|null`, `recordes: RecordeResponse[]` (≤5), `insight: AlunoInsight|null`. `forcaPorSemana` passa a ser 1RM estimado médio.

- [ ] **Step 1: Write the failing tests**

`AlunoHomeInsightInputsTest.java`:

```java
package com.focux.modules.dashboard;

import com.focux.modules.evolucao.dto.RecordeResponse;
import com.focux.modules.health.dto.RecoverySnapshotResponse;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class AlunoHomeInsightInputsTest {

    private static final LocalDate HOJE = LocalDate.of(2026, 9, 16); // quarta

    @Test
    void contaSessoesPorJanela() {
        var datas = List.of(
            HOJE, LocalDate.of(2026, 9, 14), LocalDate.of(2026, 9, 12),
            LocalDate.of(2026, 9, 9), LocalDate.of(2026, 8, 13), LocalDate.of(2026, 8, 12)
        );
        var in = AlunoHomeInsightInputs.montar(HOJE, datas, 2L, 3, 4, null, List.of(),
            AlunoHomeVolume.emptyResumo());

        assertThat(in.totalConcluidos()).isEqualTo(6);
        assertThat(in.concluidosSemanaIso()).isEqualTo(2);
        assertThat(in.concluidos7d()).isEqualTo(3);
        assertThat(in.concluidos28dAnteriores()).isEqualTo(2);
        assertThat(in.streakSemanas()).isEqualTo(4);
        assertThat(in.recoveryScore()).isNull();
        assertThat(in.ultimoRecorde()).isNull();
        assertThat(in.volumePorSemana()).hasSize(8);
    }

    @Test
    void levaRecoveryValidoEPrimeiroRecorde() {
        var recovery = new RecoverySnapshotResponse(HOJE, 0, 0, 0, 4, 40, "Descanso recomendado", "", HOJE.atStartOfDay());
        var recordes = List.of(
            new RecordeResponse(1L, 9L, "Supino", HOJE.minusDays(1), new BigDecimal("80"), null),
            new RecordeResponse(2L, 9L, "Supino", HOJE.minusDays(20), new BigDecimal("75"), null)
        );
        var in = AlunoHomeInsightInputs.montar(HOJE, List.of(), null, null, 0, recovery, recordes,
            AlunoHomeVolume.emptyResumo());

        assertThat(in.recoveryScore()).isEqualTo(40);
        assertThat(in.ultimoRecorde().exercicioNome()).isEqualTo("Supino");
        assertThat(in.ultimoRecorde().data()).isEqualTo(HOJE.minusDays(1));
    }
}
```

Adicionar em `AlunoDashboardControllerTest`:

```java
    @Test
    void home_semCamposInternosDoPersonalEComInsightDeAlunoNovo() throws Exception {
        mvc.perform(get(HOME_PATH)
                .header("Authorization", "Bearer " + MvcAuthTestSupport.bearer(sessions, "ALUNO")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.aluno.id").exists())
            .andExpect(jsonPath("$.aluno.inadimplente").value(false))
            .andExpect(jsonPath("$.aluno.emRisco").doesNotExist())
            .andExpect(jsonPath("$.aluno.riscoNivel").doesNotExist())
            .andExpect(jsonPath("$.aluno.proximoContato").doesNotExist())
            .andExpect(jsonPath("$.aluno.snoozedUntil").doesNotExist())
            .andExpect(jsonPath("$.aluno.ultimoContato").doesNotExist())
            .andExpect(jsonPath("$.aluno.operacaoFocusMode").doesNotExist())
            .andExpect(jsonPath("$.aluno.statusFinanceiro").doesNotExist())
            .andExpect(jsonPath("$.recordes").isArray())
            .andExpect(jsonPath("$.recoveryStale").value(false))
            .andExpect(jsonPath("$.streakAtual").value(0))
            .andExpect(jsonPath("$.forcaPorSemana.length()").value(8))
            .andExpect(jsonPath("$.insight.tipo").value("NOVO"))
            .andExpect(jsonPath("$.insight.confianca").value("HIGH"))
            .andExpect(jsonPath("$.insight.chave").value("insightNovo"))
            .andExpect(jsonPath("$.insight.acao.rota").value("/checkin/treinos"));
    }

    @Test
    void me_semCamposInternosDoPersonal() throws Exception {
        mvc.perform(get("/api/aluno/me")
                .header("Authorization", "Bearer " + MvcAuthTestSupport.bearer(sessions, "ALUNO")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").exists())
            .andExpect(jsonPath("$.inadimplente").exists())
            .andExpect(jsonPath("$.emRisco").doesNotExist())
            .andExpect(jsonPath("$.riscoNivel").doesNotExist())
            .andExpect(jsonPath("$.proximoContato").doesNotExist())
            .andExpect(jsonPath("$.operacaoFocusMode").doesNotExist())
            .andExpect(jsonPath("$.statusFinanceiro").doesNotExist());
    }
```

Adicionar em `CheckinControllerTest` (teste de IDOR/BOLA):

```java
    @Test
    void alunoNaoAcessaSessaoDeOutroAluno() throws Exception {
        var personalToken = registrarPersonal("personal-idor@focux.com");
        var dono = registrarAluno(personalToken, "aluno-idor-dono@focux.com");
        var intruso = registrarAluno(personalToken, "aluno-idor-intruso@focux.com");
        var treinoId = criarTreino(personalToken);
        var exercicioId = criarExercicio(personalToken);
        adicionarExercicio(personalToken, treinoId, exercicioId);
        mvc.perform(post("/api/treinos/" + treinoId + "/alunos/" + dono.id())
                .header("Authorization", "Bearer " + personalToken))
            .andExpect(status().isNoContent());
        entityManager.flush();
        entityManager.clear();
        var execucao = iniciarTreino(dono.token(), treinoId);

        mvc.perform(get("/api/checkin/" + execucao.execucaoId())
                .header("Authorization", "Bearer " + intruso.token()))
            .andExpect(status().isNotFound());
        mvc.perform(get("/api/checkin/" + execucao.execucaoId() + "/evolucao-sessao")
                .header("Authorization", "Bearer " + intruso.token()))
            .andExpect(status().isNotFound());
        mvc.perform(put("/api/checkin/" + execucao.execucaoId() + "/concluir")
                .header("Authorization", "Bearer " + intruso.token()))
            .andExpect(status().isNotFound());
    }
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `.\gradlew.bat test --console=plain --tests "com.focux.modules.dashboard.AlunoHomeInsightInputsTest" --tests "com.focux.modules.dashboard.AlunoDashboardControllerTest"`
Expected: FAIL — `cannot find symbol: class AlunoHomeInsightInputs` (compilação). O teste de IDOR já deve passar quando compilar (guarda de regressão).

- [ ] **Step 3: Create `AlunoHomeInsightInputs.java`**

```java
package com.focux.modules.dashboard;

import com.focux.modules.dashboard.insights.AlunoInsightInput;
import com.focux.modules.evolucao.dto.RecordeResponse;
import com.focux.modules.health.dto.RecoverySnapshotResponse;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.List;

/** Monta a entrada do motor a partir do que o BFF já carregou. */
final class AlunoHomeInsightInputs {

    private AlunoHomeInsightInputs() {}

    static AlunoInsightInput montar(
        LocalDate hoje,
        List<LocalDate> datasConcluidas,
        Long diasSemTreino,
        Integer frequenciaDias,
        int streakSemanas,
        RecoverySnapshotResponse recoveryValido,
        List<RecordeResponse> recordes,
        AlunoHomeVolume.Resumo volume
    ) {
        LocalDate segunda = hoje.with(DayOfWeek.MONDAY);
        LocalDate inicio7d = hoje.minusDays(6);
        LocalDate inicioAnteriores = hoje.minusDays(34);
        int total = 0;
        int semana = 0;
        int ultimos7 = 0;
        int anteriores = 0;
        for (var data : datasConcluidas) {
            if (data == null) {
                continue;
            }
            total++;
            if (!data.isBefore(segunda)) {
                semana++;
            }
            if (!data.isBefore(inicio7d)) {
                ultimos7++;
            } else if (!data.isBefore(inicioAnteriores)) {
                anteriores++;
            }
        }
        return new AlunoInsightInput(
            hoje, total, semana, ultimos7, anteriores,
            diasSemTreino, frequenciaDias, streakSemanas,
            recoveryValido == null ? null : recoveryValido.recoveryScore(),
            ultimoRecorde(recordes),
            volume.forcaDeltaPercent(), volume.forcaExerciciosComuns(), volume.volumePorSemana()
        );
    }

    private static AlunoInsightInput.UltimoRecorde ultimoRecorde(List<RecordeResponse> recordes) {
        if (recordes == null || recordes.isEmpty()) {
            return null;
        }
        var r = recordes.getFirst();
        return new AlunoInsightInput.UltimoRecorde(r.exercicioNome(), r.cargaKg(), r.data());
    }
}
```

- [ ] **Step 4: Repositórios e recordes do aluno**

`AlunoOfertaRepository.java` — substituir o método derivado (único caller é o BFF) por:

```java
    /** Home BFF: pendentes mais recentes com a oferta já carregada (sem N+1). */
    @Query("""
        select ao from AlunoOferta ao
        join fetch ao.oferta
        where ao.alunoId = :alunoId and ao.status = :status
        order by ao.dataOferta desc
        """)
    List<AlunoOferta> findPendentesComOferta(
        @Param("alunoId") Long alunoId,
        @Param("status") String status,
        Pageable pageable
    );
```

(imports `org.springframework.data.jpa.repository.Query`, `org.springframework.data.repository.query.Param`).

`RecordePessoalRepository.java` — adicionar:

```java
    @EntityGraph(attributePaths = "exercicio")
    List<RecordePessoal> findByAlunoIdOrderByDataDescIdDesc(Long alunoId, Pageable pageable);
```

(import `org.springframework.data.jpa.repository.EntityGraph`).

`EvolucaoService.java` — adicionar após `listarRecordesComoAluno(Long alunoId)`:

```java
    /** Home BFF: {@code limit} recordes mais recentes, exercício já carregado. */
    public List<RecordeResponse> listarRecordesComoAluno(Long alunoId, int limit) {
        buscarAlunoDoApp(alunoId);
        return recordeRepo.findByAlunoIdOrderByDataDescIdDesc(alunoId, PageRequest.of(0, limit))
            .stream()
            .map(this::toRecordeResponse)
            .toList();
    }
```

`AlunoDashboardHomeSurface.java:13`: `RECORDES_CAP = 10` → `RECORDES_CAP = 5`. Em `AlunoDashboardHomeResponseTest.capsSaoOsDoContratoApp` adicionar `assertThat(AlunoDashboardHomeSurface.RECORDES_CAP).isEqualTo(5);`.

- [ ] **Step 5: DTO do BFF**

Em `AlunoDashboardHomeResponse.java`:
- import `com.focux.modules.alunos.dto.AlunoSelfResponse`, `com.focux.modules.dashboard.insights.AlunoInsight`, `com.focux.modules.evolucao.dto.RecordeResponse`; remover import de `AlunoResponse`.
- `AlunoResponse aluno,` → `AlunoSelfResponse aluno,` com `@Schema(description = "Perfil do aluno autenticado, sem campos internos do personal — mesmo shape de GET /api/aluno/me.")`.
- `recovery`: descrição → `"Snapshot de recovery de hoje ou ontem. Null se não houver ou se estiver desatualizado."`.
- `streakAtual`: descrição → `"Semanas ISO seguidas com treino concluído, calculada ao ler; a semana atual vazia não quebra."`.
- `forcaPorSemana`: descrição → `"Força por semana: média do 1RM estimado (Epley) da melhor série de cada exercício (8 pontos, mais antigo → atual)."`.
- Após `Integer frequenciaDias` adicionar:

```java
    ,

    @Schema(description = "True se existe snapshot de recovery, mas ele é anterior a ontem.")
    boolean recoveryStale,

    @Schema(description = "Variação % da força vs semana anterior, só exercícios feitos nas duas. Null se < 2 em comum.")
    Double forcaDeltaPercent,

    @Schema(description = "Recordes de carga mais recentes (cap 5).")
    List<RecordeResponse> recordes,

    @Schema(description = "Insight único da Home (Focux Insights). Null se o motor falhar.")
    AlunoInsight insight
```

(escreva a vírgula no fim da linha `Integer frequenciaDias`, não numa linha solta).
- No construtor compacto: `recordes = recordes == null ? List.of() : List.copyOf(recordes);`.

- [ ] **Step 6: Rewrite `AlunoDashboardService.java`**

```java
package com.focux.modules.dashboard;

import com.focux.infra.exception.FocuxException;
import com.focux.infra.time.FocuxClock;
import com.focux.modules.alunos.AlunoRepository;
import com.focux.modules.alunos.AlunoService;
import com.focux.modules.alunos.dto.AlunoResponse;
import com.focux.modules.alunos.dto.AlunoSelfResponse;
import com.focux.modules.chat.ChatMessageRepository;
import com.focux.modules.checkin.CheckinService;
import com.focux.modules.checkin.CheckinStreakWeeks;
import com.focux.modules.checkin.ExecucaoSerieRepository;
import com.focux.modules.checkin.ExecucaoTreinoRepository;
import com.focux.modules.checkin.dto.ExecucaoResponse;
import com.focux.modules.coach.CoachProativoController;
import com.focux.modules.coach.CoachProativoLogRepository;
import com.focux.modules.dashboard.dto.AlunoDashboardChatResumo;
import com.focux.modules.dashboard.dto.AlunoDashboardHomeResponse;
import com.focux.modules.dashboard.dto.HistoricoResumoItem;
import com.focux.modules.dashboard.insights.AlunoInsight;
import com.focux.modules.dashboard.insights.AlunoInsightEngine;
import com.focux.modules.dashboard.insights.AlunoInsightInput;
import com.focux.modules.evolucao.EvolucaoService;
import com.focux.modules.evolucao.dto.MedidaResponse;
import com.focux.modules.evolucao.dto.RecordeResponse;
import com.focux.modules.health.AlunoHealthService;
import com.focux.modules.health.dto.RecoverySnapshotResponse;
import com.focux.modules.monetizacao.AlunoOferta;
import com.focux.modules.monetizacao.AlunoOfertaRepository;
import com.focux.modules.monetizacao.dto.AlunoOfertaResponse;
import com.focux.modules.notificacoes.NotificacaoAppService;
import com.focux.modules.nps.NpsRespostaRepository;
import com.focux.modules.personal.dto.PersonalBrandResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.core.env.Environment;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.DefaultTransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionException;
import java.util.concurrent.Executors;
import java.util.function.Supplier;

/**
 * Home BFF do aluno em uma resposta tipada. Carrega em 4 grupos read-only (perfil, treino,
 * social, saúde) — em paralelo fora do perfil de teste, sem estourar o pool Hikari (5).
 *
 * <p>Ids explícitos em todo lugar: {@code TenantContext} é ThreadLocal e não cruza virtual threads.
 * O grupo perfil roda numa transação só, então as buscas do aluno por id saem do cache de
 * primeiro nível do Hibernate.
 */
@Service
public class AlunoDashboardService {

    private static final Logger log = LoggerFactory.getLogger(AlunoDashboardService.class);
    private static final String REMETENTE_ALUNO = "ALUNO";
    private static final String REMETENTE_PERSONAL = "PERSONAL";
    private static final String UPSELL_PENDENTE = "PENDENTE";

    private final AlunoRepository alunoRepo;
    private final AlunoService alunoService;
    private final CheckinService checkinService;
    private final EvolucaoService evolucaoService;
    private final ChatMessageRepository chatMessageRepo;
    private final NotificacaoAppService notificacaoAppService;
    private final CoachProativoLogRepository coachRepo;
    private final AlunoOfertaRepository alunoOfertaRepo;
    private final NpsRespostaRepository npsRepo;
    private final AlunoHealthService healthService;
    private final ExecucaoSerieRepository execucaoSerieRepo;
    private final ExecucaoTreinoRepository execucaoTreinoRepo;
    private final Environment environment;
    private final TransactionTemplate readOnlyTransactionTemplate;

    public AlunoDashboardService(
        AlunoRepository alunoRepo,
        AlunoService alunoService,
        CheckinService checkinService,
        EvolucaoService evolucaoService,
        ChatMessageRepository chatMessageRepo,
        NotificacaoAppService notificacaoAppService,
        CoachProativoLogRepository coachRepo,
        AlunoOfertaRepository alunoOfertaRepo,
        NpsRespostaRepository npsRepo,
        AlunoHealthService healthService,
        ExecucaoSerieRepository execucaoSerieRepo,
        ExecucaoTreinoRepository execucaoTreinoRepo,
        Environment environment,
        PlatformTransactionManager transactionManager
    ) {
        this.alunoRepo = alunoRepo;
        this.alunoService = alunoService;
        this.checkinService = checkinService;
        this.evolucaoService = evolucaoService;
        this.chatMessageRepo = chatMessageRepo;
        this.notificacaoAppService = notificacaoAppService;
        this.coachRepo = coachRepo;
        this.alunoOfertaRepo = alunoOfertaRepo;
        this.npsRepo = npsRepo;
        this.healthService = healthService;
        this.execucaoSerieRepo = execucaoSerieRepo;
        this.execucaoTreinoRepo = execucaoTreinoRepo;
        this.environment = environment;
        var txDef = new DefaultTransactionDefinition();
        txDef.setReadOnly(true);
        this.readOnlyTransactionTemplate = new TransactionTemplate(transactionManager, txDef);
    }

    private record Perfil(
        AlunoResponse aluno,
        PersonalBrandResponse brand,
        List<MedidaResponse> medidas,
        List<RecordeResponse> recordes
    ) {}

    private record Treino(
        List<ExecucaoResponse> treinos,
        List<HistoricoResumoItem> historico,
        List<LocalDate> datasConcluidas,
        AlunoHomeVolume.Resumo volume
    ) {}

    private record Social(
        AlunoDashboardChatResumo chat,
        Long notificacoes,
        List<CoachProativoController.MensagemResponse> coach,
        List<AlunoOfertaResponse> upsell,
        boolean npsDeveResponder
    ) {}

    private record Saude(RecoverySnapshotResponse latest, boolean wearable) {}

    @Cacheable(value = "aluno-dashboard-home", key = "#alunoId")
    public AlunoDashboardHomeResponse getHome(Long alunoId) {
        if (alunoId == null) {
            throw FocuxException.unauthorized("Aluno não autenticado.");
        }
        Long personalId = readOnly(() -> resolvePersonalId(alunoId));
        Supplier<Perfil> perfil = () -> readOnly(() -> carregarPerfil(alunoId));
        Supplier<Treino> treino = () -> readOnly(() -> carregarTreino(alunoId));
        Supplier<Social> social = () -> readOnly(() -> carregarSocial(alunoId, personalId));
        Supplier<Saude> saude = () -> readOnly(() -> carregarSaude(alunoId));
        if (Arrays.asList(environment.getActiveProfiles()).contains("test")) {
            return montar(alunoId, perfil.get(), treino.get(), social.get(), saude.get());
        }
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            var perfilFuture = CompletableFuture.supplyAsync(perfil, executor);
            var treinoFuture = CompletableFuture.supplyAsync(treino, executor);
            var socialFuture = CompletableFuture.supplyAsync(social, executor);
            var saudeFuture = CompletableFuture.supplyAsync(saude, executor);
            CompletableFuture.allOf(perfilFuture, treinoFuture, socialFuture, saudeFuture).join();
            return montar(alunoId, perfilFuture.join(), treinoFuture.join(), socialFuture.join(), saudeFuture.join());
        } catch (CompletionException e) {
            Throwable cause = e.getCause() != null ? e.getCause() : e;
            if (cause instanceof RuntimeException runtime) {
                throw runtime;
            }
            throw new RuntimeException(cause);
        }
    }

    private <T> T readOnly(Supplier<T> work) {
        return readOnlyTransactionTemplate.execute(status -> work.get());
    }

    private Long resolvePersonalId(Long alunoId) {
        var aluno = alunoRepo.findById(alunoId)
            .orElseThrow(() -> FocuxException.notFound("Aluno não encontrado"));
        return aluno.getPersonal() == null ? null : aluno.getPersonal().getId();
    }

    private Perfil carregarPerfil(Long alunoId) {
        return new Perfil(
            alunoService.getAlunoPorIdProprio(alunoId),
            alunoService.getPersonalBrand(alunoId),
            evolucaoService.listarMedidasComoAluno(alunoId, AlunoDashboardHomeSurface.MEDIDAS_CAP),
            evolucaoService.listarRecordesComoAluno(alunoId, AlunoDashboardHomeSurface.RECORDES_CAP)
        );
    }

    private Treino carregarTreino(Long alunoId) {
        var datas = execucaoTreinoRepo.findConcluidoEmByAlunoId(alunoId).stream()
            .filter(Objects::nonNull)
            .map(LocalDateTime::toLocalDate)
            .toList();
        return new Treino(checkinService.meusTreinos(alunoId), historicoResumo(alunoId), datas, volumeResumo(alunoId));
    }

    private Social carregarSocial(Long alunoId, Long personalId) {
        return new Social(
            chatResumo(alunoId, personalId),
            notificacaoAppService.countNaoLidasAluno(alunoId),
            coachMensagens(alunoId),
            upsellPendentes(alunoId),
            npsDeveResponder(alunoId)
        );
    }

    private Saude carregarSaude(Long alunoId) {
        return new Saude(healthService.getLatestForAluno(alunoId), healthService.hasWearableHistory(alunoId));
    }

    private AlunoDashboardHomeResponse montar(Long alunoId, Perfil perfil, Treino treino, Social social, Saude saude) {
        LocalDate hoje = FocuxClock.today();
        var treinos = treino.treinos() == null ? List.<ExecucaoResponse>of() : treino.treinos();
        var volume = treino.volume() == null ? AlunoHomeVolume.emptyResumo() : treino.volume();
        int streak = CheckinStreakWeeks.countAtivo(hoje, treino.datasConcluidas());
        var recovery = AlunoHomeRecovery.avaliar(saude.latest(), hoje);
        Integer frequencia = FocuxScoreCalculator.metaDiasSemanaPlano(treinos.size());
        var input = AlunoHomeInsightInputs.montar(
            hoje, treino.datasConcluidas(), perfil.aluno().diasSemTreino(), frequencia, streak,
            recovery.snapshot(), perfil.recordes(), volume
        );
        return new AlunoDashboardHomeResponse(
            AlunoSelfResponse.from(perfil.aluno()),
            perfil.brand(),
            treinos,
            List.of(),
            treino.historico(),
            perfil.medidas(),
            social.chat(),
            social.notificacoes(),
            social.coach(),
            social.upsell(),
            social.npsDeveResponder(),
            recovery.snapshot(),
            saude.wearable(),
            streak,
            volume.semanaKg(),
            volume.mesKg(),
            volume.volumePorSemana(),
            volume.forcaPorSemana(),
            frequencia,
            recovery.stale(),
            volume.forcaDeltaPercent(),
            perfil.recordes(),
            avaliarInsight(alunoId, input)
        );
    }

    private AlunoInsight avaliarInsight(Long alunoId, AlunoInsightInput input) {
        try {
            return AlunoInsightEngine.avaliar(input);
        } catch (RuntimeException e) {
            log.warn("aluno_insight_falhou alunoId={} erro={}", alunoId, e.getClass().getSimpleName());
            return null;
        }
    }

    /** Uma query slim + subquery count — zero N+1, sem séries/mídia. */
    private List<HistoricoResumoItem> historicoResumo(Long alunoId) {
        return execucaoTreinoRepo
            .findHistoricoResumoByAlunoId(
                alunoId,
                PageRequest.of(0, AlunoDashboardHomeSurface.HISTORICO_RESUMO_CAP)
            )
            .stream()
            .map(AlunoDashboardService::toHistoricoResumoItem)
            .toList();
    }

    static HistoricoResumoItem toHistoricoResumoItem(Object[] row) {
        if (row == null || row.length < 6) {
            return new HistoricoResumoItem(0L, 0L, "", "", null, null, 0);
        }
        Long id = toLong(row[0]);
        Long treinoId = toLong(row[1]);
        String treinoNome = row[2] == null ? "" : row[2].toString();
        String status = row[3] == null ? "" : row[3].toString();
        LocalDateTime iniciadoEm = toLocalDateTime(row[4]);
        LocalDateTime concluidoEm = toLocalDateTime(row[5]);
        Integer exerciciosCount = row.length > 6 && row[6] != null
            ? ((Number) row[6]).intValue()
            : 0;
        return new HistoricoResumoItem(id, treinoId, treinoNome, status, iniciadoEm, concluidoEm, exerciciosCount);
    }

    private static Long toLong(Object raw) {
        if (raw == null) {
            return 0L;
        }
        return ((Number) raw).longValue();
    }

    private static LocalDateTime toLocalDateTime(Object raw) {
        if (raw == null) {
            return null;
        }
        if (raw instanceof LocalDateTime dateTime) {
            return dateTime;
        }
        if (raw instanceof java.sql.Timestamp timestamp) {
            return timestamp.toLocalDateTime();
        }
        if (raw instanceof java.sql.Date date) {
            return date.toLocalDate().atStartOfDay();
        }
        throw new IllegalArgumentException("Unsupported datetime: " + raw.getClass());
    }

    /**
     * Sinal de chat sem efeito colateral: diferente de {@code historicoAluno}, não marca
     * mensagens do personal como lidas só porque a Home carregou.
     */
    private AlunoDashboardChatResumo chatResumo(Long alunoId, Long personalId) {
        if (personalId == null) {
            return AlunoDashboardChatResumo.vazio();
        }
        var ultimaDoAluno = chatMessageRepo
            .findLastEnviadoEm(personalId, alunoId, REMETENTE_ALUNO)
            .orElse(null);
        long naoLidasDoPersonal = chatMessageRepo
            .countByPersonalIdAndAlunoIdAndRemetenteAndReadAtIsNull(personalId, alunoId, REMETENTE_PERSONAL);
        return new AlunoDashboardChatResumo(ultimaDoAluno != null, ultimaDoAluno, naoLidasDoPersonal);
    }

    /** Cap 5 — pageable, sem carregar inbox inteiro. */
    private List<CoachProativoController.MensagemResponse> coachMensagens(Long alunoId) {
        return coachRepo
            .findByAlunoIdAndLidoFalseOrderByCriadoEmDesc(
                alunoId,
                PageRequest.of(0, AlunoDashboardHomeSurface.COACH_CAP)
            )
            .stream()
            .map(m -> new CoachProativoController.MensagemResponse(
                m.getId(),
                m.getTipoGatilho(),
                m.getMensagem(),
                m.getCriadoEm().toString(),
                m.isLido()
            ))
            .toList();
    }

    /** Cap 5 ofertas pendentes — mais recentes primeiro, oferta já carregada. */
    private List<AlunoOfertaResponse> upsellPendentes(Long alunoId) {
        return alunoOfertaRepo
            .findPendentesComOferta(alunoId, UPSELL_PENDENTE, PageRequest.of(0, AlunoDashboardHomeSurface.UPSELL_CAP))
            .stream()
            .map(AlunoDashboardService::toAlunoOfertaResponse)
            .toList();
    }

    private static AlunoOfertaResponse toAlunoOfertaResponse(AlunoOferta ao) {
        var oferta = ao.getOferta();
        return new AlunoOfertaResponse(
            ao.getId(),
            oferta.getId(),
            oferta.getTitulo(),
            oferta.getDescricao(),
            oferta.getValor(),
            ao.getStatus(),
            ao.getDataOferta()
        );
    }

    /** Mesma regra de {@code NpsController.deveResponder}: sem resposta nos últimos 30 dias. */
    private boolean npsDeveResponder(Long alunoId) {
        return !npsRepo.existsByAlunoIdAndCriadoEmAfter(alunoId, FocuxClock.now().minusDays(30));
    }

    private AlunoHomeVolume.Resumo volumeResumo(Long alunoId) {
        LocalDate hoje = FocuxClock.today();
        LocalDate semanaSegunda = hoje.with(DayOfWeek.MONDAY);
        LocalDateTime inicioMes = hoje.withDayOfMonth(1).atStartOfDay();
        LocalDateTime inicioSemana = semanaSegunda.atStartOfDay();
        LocalDateTime desdeSeries = semanaSegunda
            .minusWeeks(AlunoHomeVolume.WEEKS - 1L)
            .atStartOfDay();
        var series = execucaoSerieRepo.findVolumeLinhasDesde(alunoId, desdeSeries).stream()
            .map(AlunoHomeSerie::fromRow)
            .filter(Objects::nonNull)
            .toList();
        return AlunoHomeVolume.somar(series, inicioSemana, inicioMes, semanaSegunda);
    }
}
```

Mortos desta troca (grep no `src/` antes de seguir; zero callers = apagar): `AlunoStreakRepository`/`AlunoStreak` **não** apagar (gamificação usa); `CheckinEvolucaoAnalyzer` **não** apagar (checkin usa). Confirme que `findByAlunoIdAndStatusOrderByDataOfertaDesc` não tem mais caller: `rg "findByAlunoIdAndStatusOrderByDataOfertaDesc" src` → vazio.

- [ ] **Step 7: Evictar a Home ao iniciar treino**

Em `CheckinService.iniciar(...)` privado, logo antes do `return responseMapper.toResponse(execucao);` final (linha ~210):

```java
        alunoDashboardHomeCacheEvictor.evict(alunoId);
```

- [ ] **Step 8: Atualizar `AlunoDashboardHomeResponseTest` (contrato mudou)**

- import `com.focux.modules.alunos.dto.AlunoSelfResponse`.
- no `new AlunoDashboardHomeResponse(`: primeiro argumento `aluno()` → `AlunoSelfResponse.from(aluno())`; após o último argumento `1` adicionar `, false, 4.5, List.of(), null`.
- após `assertThat(response.frequenciaDias()).isEqualTo(1);` adicionar:

```java
        assertThat(response.recoveryStale()).isFalse();
        assertThat(response.forcaDeltaPercent()).isEqualTo(4.5);
        assertThat(response.recordes()).isEmpty();
        assertThat(response.insight()).isNull();
```

- [ ] **Step 9: Run tests**

Run: `.\gradlew.bat test --console=plain --tests "com.focux.modules.dashboard.*" --tests "com.focux.modules.checkin.CheckinControllerTest" --tests "com.focux.modules.alunos.*" --tests "com.focux.modules.evolucao.*" --tests "com.focux.modules.monetizacao.*"`
Expected: PASS.

- [ ] **Step 10: Commit**

```bash
git add src/main/java/com/focux/modules/dashboard src/main/java/com/focux/modules/monetizacao/AlunoOfertaRepository.java src/main/java/com/focux/modules/evolucao src/main/java/com/focux/modules/checkin/CheckinService.java src/test/java/com/focux/modules/dashboard src/test/java/com/focux/modules/checkin/CheckinControllerTest.java
git -c user.name="Matheus Oliveira" -c user.email="matheusos1912@icloud.com" commit -m "feat(dashboard): home do aluno com insight e dados corretos"
```

---

### Task 7: Verificação completa e push

**Files:** nenhum novo.

- [ ] **Step 1: Suíte completa**

Run: `.\gradlew.bat test --console=plain`
Expected: BUILD SUCCESSFUL, 0 falhas.

- [ ] **Step 2: Cobertura dos pacotes tocados**

Run: `.\gradlew.bat jacocoTestReport jacocoTestCoverageVerification --console=plain`
Expected: sem violação em `com.focux.modules.dashboard` e `com.focux.modules.dashboard.insights`. Violações pré-existentes em `iap`, `checkin` (0.78) e `infra.security` podem aparecer — registrar, não mascarar; se `checkin` cair abaixo do valor anterior, adicionar teste para `countAtivo`/`RepeticoesParser` até voltar.

- [ ] **Step 3: Revisão de segredos**

Run: `git diff origin/main --stat` e `gitleaks detect --no-banner --log-opts "origin/main..HEAD"`
Expected: só arquivos deste plano; `no leaks found`.

- [ ] **Step 4: Push**

```bash
git push origin main
```

Se o auto-review bloquear o push em `main`, repetir o mesmo comando pedindo aprovação.
