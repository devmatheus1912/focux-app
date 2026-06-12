# Padrões de código — Focux App

## Princípios

1. **Lógica fora da UI** — regras de negócio, estado derivado e formatação em `utils/`, `domain/` e services. Widgets renderizam e delegam.
2. **Responsabilidade única** — extrair quando o arquivo passar de ~150 linhas úteis ou misturar layout com regra.
3. **Tipos explícitos** — parsear na borda (API → model/DTO); evitar `Map<String, dynamic>` em telas hub.
4. **Composição** — reutilizar tokens (`Aluno360Layout`, design system) antes de criar abstrações novas.
5. **Testabilidade** — funções puras com testes unitários; widgets com testes de contrato quando relevante.

## Flutter

- Providers finos; estado derivado em `utils/`.
- Widgets reutilizáveis em `widgets/`.
- Telas hub gateadas: `personal_dashboard`, `aluno_detail`, `alunos_list`, `treinos_list`, `financeiro`, `ia_copiloto`.

## Checklist antes de merge

- [ ] Regra de negócio testável sem widget?
- [ ] Nomes autoexplicativos
- [ ] Escopo mínimo; convenções do arquivo respeitadas
- [ ] Testes passando nos caminhos alterados
