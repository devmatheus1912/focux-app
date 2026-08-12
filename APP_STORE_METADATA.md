# App Store Connect — metadados (sem secrets)

Preencha no App Store Connect. **Senhas e shared secrets só no Railway / vault do time.**

## URLs obrigatórias

| Campo | Valor |
|---|---|
| Privacy Policy URL | `https://focuxpersonal.com/privacidade` |
| Support URL | `https://focuxpersonal.com/suporte` |
| Terms of Use (EULA) | `https://focuxpersonal.com/termos` |
| Marketing URL | `https://focuxpersonal.com` |

## Identidade

- **Name:** Focux Personal — Gestão de Alunos
- **Bundle ID:** `com.focux.focuxApp`
- **Subtitle / keywords:** conforme copy aprovada (PT-BR)
- **Categoria:** Health & Fitness / Productivity (escolha a principal no Connect)

## App Review Information

- **Demo account:** usuário de review provisionado no backend (env no Railway). **Não** coloque a senha neste arquivo.
- **Notas para o reviewer (cole no Connect):**

```text
Focux Personal — app para personal trainers e alunos.

Login: use a conta de review informada neste formulário (senha só no campo senha do Review Information).

Fluxo sugerido:
1) Login como personal
2) Dashboard / alunos / treinos
3) Perfil → Configurações → caminho de exclusão de conta (LGPD)
4) Paywall / assinatura: sandbox App Store; botão Restaurar compras

URLs legais (estáticas, sem JS obrigatório):
- Privacidade: https://focuxpersonal.com/privacidade
- Termos (IAP auto-renovável / cancelamento Apple): https://focuxpersonal.com/termos
- Suporte + exclusão: https://focuxpersonal.com/suporte
- Empresa: https://focuxpersonal.com/empresa

White-label = personalização DENTRO do app Focux Personal (nome/cores/logo). Não publica app separado na App Store em nome do personal.
HealthKit / Health Connect só com consentimento do usuário.
```

## Checklist antes de enviar

- [ ] Privacy / Support / Terms no Connect = URLs acima
- [ ] Conta review ativa no backend de produção
- [ ] IAP sandbox + Shared Secret no backend
- [ ] Screenshots e descrição sem claims de loja “já publicada” se ainda não estiver
- [ ] Site focuxpersonal.com no ar com as quatro páginas legais HTTP 200
