# Assinaturas — App Store e Google Play

**Objetivo:** evitar rejeição por pagamento externo de conteúdo digital (Apple 3.1.1 / Google Play Billing).

## Estado no código (Flutter)

| Canal | Quando | Implementação |
|-------|--------|----------------|
| **iOS / Android** | App nativo | `in_app_purchase` → SKUs → `POST /api/iap/verify` |
| **Web** | `kIsWeb` | Mercado Pago via `AssinaturaRepository.criarPreferencia` |

**Arquivos principais**

- `lib/features/subscription/store_subscription_policy.dart` — política “só loja” no mobile
- `lib/features/planos/screens/planos_screen.dart` — comparação; CTAs → `/assinatura`; restaurar compras
- `lib/features/assinatura/screens/assinatura_screen.dart` — compra IAP ou checkout web
- `lib/features/subscription/services/iap_service.dart` — verify no backend

## SKUs obrigatórios nas consoles

| Plano | Product ID | Tipo na loja |
|-------|------------|--------------|
| Premium | `focux_premium_monthly` | Assinatura auto-renovável mensal |
| Premium | `focux_premium_yearly` | Assinatura auto-renovável anual (oferta principal no app) |
| Enterprise | `focux_enterprise_monthly` | Assinatura auto-renovável mensal |
| Enterprise | `focux_enterprise_yearly` | Assinatura auto-renovável anual |
| Enterprise Pro | `focux_enterprise_pro_monthly` | Assinatura auto-renovável mensal |
| Enterprise Pro | `focux_enterprise_pro_yearly` | Assinatura auto-renovável anual |

### App Store Connect

1. Criar **Subscription Group** (ex.: Focux Premium).
2. Adicionar os dois produtos com os IDs acima.
3. Configurar preço, localização (BRL) e **Introductory Offer** (ex.: 7 dias grátis no Enterprise) se desejado.
4. Vincular ao app; enviar para revisão junto com o binário.
5. Sandbox: conta de teste para validar compra e restore.

### Google Play Console

1. **Monetização → Produtos → Assinaturas** com os mesmos IDs.
2. Base plan + ofertas (trial) conforme política Google.
3. Ativar licenciamento; publicar em faixa de teste interna/fechada antes da produção.

## O que NÃO fazer no app mobile

- Trial Enterprise via API (`PlanosRepository.startTrial`) sem passar pela loja.
- Links para Mercado Pago, PIX ou checkout web dentro do fluxo de assinatura digital.
- Textos prometendo “5 dias grátis com cartão” fora do fluxo da loja.

**Exceção:** versão **web** (`kIsWeb`) pode manter trial/checkout externo.

## Fluxo do usuário

1. **Planos** (`/planos`) — comparar recursos; banner de conformidade; CTA “Assinar na loja”.
2. **Assinatura** (`/assinatura`) — iniciar compra IAP; sincronizar com backend após verify.
3. **Gerenciar** — abre configurações da App Store ou Google Play (`openNativeSubscriptionManagement`).
4. **Restaurar** — Planos e Paywall chamam `restoreAndVerifyPurchases`.

## Backend

- Endpoint: `POST /api/iap/verify` (receipt Apple / token Google).
- Fonte de verdade do plano: perfil após verify bem-sucedido.

## Checklist antes de enviar à revisão

- [ ] SKUs criados e **Approved** nas duas lojas
- [ ] Teste sandbox: compra Premium + Enterprise + restore
- [ ] Tela Planos sem `startTrial` no mobile
- [ ] Promo Enterprise redireciona para `/assinatura` no mobile
- [ ] Metadados `APP_STORE_METADATA.md` alinhados (sem RevenueCat)
- [ ] Política de privacidade e termos com assinatura recorrente

---

*Focux Personal · Maio/2026*
