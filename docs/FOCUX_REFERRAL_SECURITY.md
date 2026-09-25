# Focux Referral Security

Modelo de ameaça e controles do Indique e Ganhe. Operação e fluxo em `FOCUX_REFERRAL_SYSTEM.md`.

## Princípios

- **Servidor decide tudo.** O app só exibe o que `GET /api/referral` devolve. Nenhuma regra,
  valor ou limite existe no Flutter.
- **Só pagamento verificado converte.** Webhook Mercado Pago com assinatura validada, recibo de
  loja verificado no servidor ou ativação Enterprise. Trial, valor zero e cobrança sem referência
  nunca contam.
- **Falha fechada.** Transição fora da máquina de estados lança erro; conflito de gravação faz o
  gateway reenviar em vez de engolir o pagamento.
- **Auditável.** Todo passo gera evento em `referral_eventos`, lançamento no ledger append-only e
  registro em `auditoria`.

## Ameaças e controles

| Ameaça | Controle | Onde |
|---|---|---|
| Autoindicação (mesma conta) | Código do próprio personal é ignorado; CHECK `indicador_id <> indicado_id` | `ReferralAttributionService`, V179 |
| Mesma pessoa com outro e-mail | E-mail normalizado (sem `+alias`; Gmail sem pontos) igual = `INVALID` | `ReferralRiskAssessor` |
| Mesma pessoa com outro cadastro | Telefone normalizado (últimos 11 dígitos) igual = `INVALID` | `ReferralRiskAssessor` |
| Fazenda de contas no mesmo IP | IP repetido para o mesmo indicador em 24h = risco `HIGH` (retenção com carência) | `ReferralRiskAssessor` |
| Rajada de cadastros | ≥ `rajada_max_24h` indicações em 24h = `HIGH` | `ReferralRiskAssessor` |
| Pagar e estornar para ganhar dias | Reembolso remove os dias; chargeback remove os dias, mantém a vaga e eleva o risco das próximas | `ReferralConversionService` |
| Trial para ganhar dias | Trial nunca converte (MP, Apple `is_trial_period`, Google `paymentState=2`) | `PagamentoConfirmado`, `IapVerifier` |
| Webhook repetido / replay | Claim de evento do webhook + estado da indicação + UNIQUE do ledger | `WebhookController`, `ReferralJournal` |
| Corrida para estourar o limite | Trava pessimista no código do indicador + UNIQUE `(indicador_id, posicao_recompensa)` | `ReferralConversionService`, V179 |
| Desconto forjado no checkout | Preço calculado no servidor; webhook só aceita valor com desconto com marcador `:ind` **e** indicação autorizando | `PagamentoService`, `ReferralWebhookBridge` |
| Desconto repetido na recorrência | Preço cheio restaurado após a 1ª cobrança; cobrança seguinte com desconto é recusada | `ReferralDiscountService` |
| Enumeração de códigos | Códigos de 10 caracteres Crockford (~50 bits, `SecureRandom`); `validar` responde só booleano, exige login e tem rate limit (10/min) | `ReferralCodeGenerator`, `ReferralController` |
| Entrada maliciosa no código | Normalização aceita só `[0-9A-Z]{6,20}`; o resto é descartado antes de consultar | `ReferralCodeGenerator` |
| Vazamento entre tenants | Painel lê só indicações com `indicador_id` do token; nome do indicado mascarado ("Maria L.") | `ReferralService`, `ReferralIndicacaoItem` |
| Exposição de antifraude | Risco, motivo e hash de IP nunca saem na API | `ReferralIndicacaoItem` |
| Acesso direto ao banco pelo PostgREST | RLS habilitado nas 4 tabelas novas, `REVOKE` de `anon`/`authenticated` e policies restritivas | V179, `MigrationRlsContractTest` |

## Dados pessoais (LGPD)

- **IP:** guardado só como HMAC-SHA256 do IP, com chave derivada do segredo do servidor
  (rótulo `focux-referral-ip:`). Sem a chave não dá para recuperar o IP; serve só para comparar
  igualdade no mesmo indicador.
- **E-mail e telefone:** usados só em memória na atribuição; não são copiados para as tabelas de
  indicação.
- **Nome do indicado:** exibido ao indicador apenas mascarado.
- **Push:** a notificação ao indicador sai só depois do commit e não cita o indicado.
- Logs registram ids e resultado, nunca e-mail, telefone, IP, token ou valor pago.

## Riscos e ações manuais

- Risco `HIGH`/`REVIEW` fica retido pela carência da campanha e é liberado pelo job.
- Sinal forte de mesma pessoa vira `INVALID` na hora.
- Revisão manual (bloquear ou antecipar liberação) só por SQL, seguindo o runbook em
  `FOCUX_REFERRAL_SYSTEM.md`. Nunca editar ledger ou status diretamente.

## Repositório público

- Nenhum segredo neste módulo. O HMAC do IP usa `app.jwt.secret`, que vem do ambiente.
- Testes usam dados fictícios (`@teste.focux.local`, IPs `10.0.x.x`).

## Pendências de segurança

- Estorno em loja (Apple/Google) sem notificação servidor-a-servidor ainda: a recompensa de uma
  compra estornada na loja não é revertida automaticamente (ciclo 3).
- `validar` exige login de personal; se um dia for aberto ao cadastro anônimo, manter o rate limit
  e a resposta só booleana.
