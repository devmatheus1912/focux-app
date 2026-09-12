# 08 — Segurança de sistema

**Normativo.** Complementa §20 do FOCUX_DESIGN_REFERENCE. Primer: security overview.

## Regras

1. **Webhooks MP/Terra:** HMAC fail-closed em prod; amount guard em pagamento.
2. **JWT:** secret forte; type gate; MFA confirmação revoga refresh.
3. **Tenant/RLS lógico:** sempre filtrar por ownership; alunoId antes de personalId em paths dual-role.
4. **Secrets:** só env/Railway — nunca no app tree (só client ids públicos).
5. **App release:** `API_CERT_PINS` obrigatório; cleartext bloqueado; Keystore/Keychain.
6. **OwnerGuard** em billing, LGPD, backup, white-label, wallet, IAP, identidade.
7. **AdminInitializer** opt-in + senha fraca bloqueada.

## Por quê

Superfície grande (Personal+Aluno+webhooks). Defesa em profundidade: rede (TLS/pin), auth, authZ, validação, auditoria.

## Onde no código

- `JwtFilter`, `TenantContext`, `RbacGuard`
- Webhooks + `WebhookSignatureReplayGuard`
- App: `focux_security.dart`, network security config
- Owner guards nos controllers listados em audits Slack

## Gate

- [ ] §20 + pilares 52–68 verdes ou P0 aceito por escrito.
- [ ] Sideload sem pin ≠ binário da loja (§39).
- [ ] Achado HIGH de scanner fechado com teste + commit (ex.: billing capture).
