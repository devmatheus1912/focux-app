# Focux App - Status Atual

Atualizado em: 25/04/2026  
Estado geral: 🟢 Front-end validado nesta rodada

## Painel rápido

- Base de planos alinhada ao backend novo: 🟢
- Paywall conectado ao estado real: 🟢
- Trial Enterprise integrado: 🟢
- Assinatura com `initialPlan` e sincronização Enterprise: 🟢
- Tela `Perfil` finalizada: 🟢
- `Migracao Magica` conectada e navegável: 🟢
- Dashboard com entradas novas: 🟢
- Fluxo de autenticação alinhado ao handoff do zip: 🟢
- Preview local web sem crash de Firebase: 🟢
- Dashboard com fallback visual local quando a API não responde: 🟢
- `flutter analyze`: 🟢
- `flutter test`: 🟢
- `flutter build web`: 🟢
- Commit e push desta rodada: 🔴

## Entregas concluídas

### Fluxo de entrada

- `lib/features/auth/screens/splash_screen.dart` - 🟢
- `lib/features/auth/screens/login_screen.dart` - 🟢
- `lib/features/auth/screens/esqueci_senha_screen.dart` - 🟢
- `lib/features/auth/screens/register_screen.dart` - 🟢
- `lib/features/auth/widgets/auth_shell.dart` - 🟢
- `lib/main.dart` - 🟢

Feito:

- splash simplificada para bater com a arte do zip
- login reconstruído no layout do handoff
- recuperar senha reconstruída no layout do handoff
- cadastro reconstruído no layout do handoff com seletor visual de plano
- base visual compartilhada criada para as telas de auth
- inicialização web protegida para não quebrar por Firebase sem configuração web

### Dashboard

- `lib/features/dashboard/screens/personal_dashboard_screen.dart` - 🟢
- `lib/features/dashboard/providers/dashboard_provider.dart` - 🟢

Feito:

- atalho `Planos`
- atalho `Migracao`
- drawer com `Migracao Magica`
- fallback local para preview visual quando o backend não responde
- dashboard validado visualmente em build web local

### Assinatura, planos e trial

- `lib/features/subscription/models/subscription_plan.dart` - 🟢
- `lib/core/widgets/feature_gate.dart` - 🟢
- `lib/features/subscription/providers/subscription_provider.dart` - 🟢
- `lib/features/planos/data/planos_repository.dart` - 🟢
- `lib/features/subscription/screens/paywall_screen.dart` - 🟢
- `lib/features/assinatura/screens/assinatura_screen.dart` - 🟢
- `lib/features/planos/screens/planos_screen.dart` - 🟢
- `lib/features/planos/screens/enterprise_promo_screen.dart` - 🟢

Feito:

- padronização para `FREE`, `PREMIUM` e `ENTERPRISE`
- compatibilidade com retorno legado `PRO`
- `getTrialStatus()`, `startTrial()`, `previewEnterpriseUpgrade()` e `activateEnterprise()`
- Premium abre assinatura com plano inicial
- Enterprise ativa trial quando disponível
- promo Enterprise salva dismiss e usa contrato novo

### Perfil e navegação comercial

- `lib/features/perfil/screens/perfil_screen.dart` - 🟢
- `lib/features/growth/screens/migracao_magica_screen.dart` - 🟢

Feito:

- hero com gradiente, avatar, plano e stats
- atalhos para planos, paywall, identidade visual, migração e logout
- upload de foto mantido

## Validação executada

- `flutter analyze` - 🟢 Sem issues
- `flutter test` - 🟢 Todos os testes passaram
- `flutter build web` - 🟢 Build gerada com sucesso
- validação visual local:
  - `/login` - 🟢
  - `/register` - 🟢
  - `/esqueci-senha` - 🟢
  - `/dashboard/personal` com fallback local - 🟢

## O que ainda falta manualmente

Estas pendências não são de implementação do front. São checkpoints manuais antes de distribuição:

1. Testar compra `PREMIUM` em dispositivo real com App Store / Google Play configurada
2. Testar compra `ENTERPRISE` em dispositivo real para validar:
   - retorno real do `purchaseStream`
   - token/metadados vindos da loja
   - sincronização backend após compra
3. Testar trial Enterprise ponta a ponta com usuário limpo
4. Navegar manualmente pelos fluxos:
   - `/planos`
   - `/paywall`
   - `/assinatura`
   - `/perfil`
   - `/migracao-magica`
5. **Restaurar Segurança (CORS):** 🔴 **MUITO IMPORTANTE:** `localhost` está temporariamente liberado no backend para testes Flutter Web. Remover antes de submeter às Lojas.

## Resumo final

O front do `focux-app` segue entregue com os fluxos principais ajustados ao handoff e com validação local rodada. O que resta agora é validação manual de loja e o ajuste final de segurança no backend antes da publicação.
