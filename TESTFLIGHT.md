# TestFlight — único passo manual após conta Apple aprovada

Tudo no código/CI já está pronto. Siga esta ordem **uma vez** quando a Apple Developer Program estiver ativa.

**Tempo estimado:** 2–3 horas na primeira vez.

---

## Pré-requisitos (você)

- [ ] Conta **Apple Developer Program** aprovada (US$ 99/ano)
- [ ] Mac com **Xcode 15+** e **Flutter** instalados
- [ ] Backend em produção com:
  - `FOCUX_REVIEW_ACCOUNT_PASSWORD` (conta `review@focux.app` para reviewers)
  - `FOCUX_IAP_APPLE_SHARED_SECRET` (App Store Connect → In-App Purchase → Shared Secret)

---

## Passo 1 — App Store Connect (30 min)

1. Acesse [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. **Apps → +** → New App
   - Platform: iOS
   - Name: `Focux Personal — Gestão de Alunos`
   - Bundle ID: `com.focux.focuxApp` (crie em Certificates, Identifiers & Profiles se não existir)
   - SKU: `focux-personal-ios`
3. **In-App Purchases → Subscriptions** — crie o grupo e **6 produtos** (auto-renewable):

| Product ID | Plano |
|------------|-------|
| `focux_premium_monthly` | Premium mensal |
| `focux_premium_yearly` | Premium anual |
| `focux_enterprise_monthly` | Enterprise mensal |
| `focux_enterprise_yearly` | Enterprise anual |
| `focux_enterprise_pro_monthly` | Enterprise Pro mensal |
| `focux_enterprise_pro_yearly` | Enterprise Pro anual |

4. Copie o **App-Specific Shared Secret** → configure no Railway: `FOCUX_IAP_APPLE_SHARED_SECRET`
5. Cole metadados de `APP_STORE_METADATA.md` (descrição, keywords, URLs de privacidade/termos)
6. Em **App Review Information**:
   - Demo: `review@focux.app` / senha do env `FOCUX_REVIEW_ACCOUNT_PASSWORD`
   - Notas: copie a seção "App Store Review Notes" de `APP_STORE_METADATA.md`

---

## Passo 2 — Signing no Xcode (15 min)

```bash
cd focux-app
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

No Xcode:

1. Selecione target **Runner** → **Signing & Capabilities**
2. Marque **Automatically manage signing**
3. Selecione seu **Team** (Apple Developer)
4. Confirme Bundle Identifier: `com.focux.focuxApp`
5. Conecte um iPhone e rode **Product → Run** para validar build debug

---

## Passo 3 — Teste no iPhone (45 min)

Com o app instalado via Xcode:

- [ ] Login com `review@focux.app`
- [ ] Navegar: dashboard → alunos → treinos → financeiro → chat → check-in → suporte
- [ ] **VoiceOver** (Ajustes → Acessibilidade → VoiceOver): percorrer as 8 telas
- [ ] Paywall: compra **sandbox** (Settings → App Store → Sandbox Account no iPhone)
- [ ] Restaurar compras na tela de planos

Marque a issue `[Audit Q2_2026] TalkBack/VoiceOver` no GitHub quando concluir.

---

## Passo 4 — Gerar IPA (10 min)

No Mac:

```bash
cd focux-app
./tools/release/build-ios.sh
```

Ou manualmente:

```bash
flutter build ipa --release \
  --dart-define=API_URL=https://focux-backend-production.up.railway.app \
  --dart-define=PUBLIC_WEB_URL=https://focux.app \
  --export-options-plist=ios/ExportOptions.plist
```

Saída: `build/ios/ipa/focux_app.ipa`

> **ExportOptions.plist:** substitua `YOUR_APPLE_TEAM_ID` pelo seu Team ID (Membership details na Apple).

---

## Passo 5 — Upload TestFlight (15 min)

### Opção A — Xcode (recomendado)

1. **Window → Organizer**
2. Selecione o archive → **Distribute App**
3. **App Store Connect** → Upload
4. Aguarde processamento (~10–30 min)

### Opção B — Transporter

1. Abra **Transporter** (Mac App Store)
2. Arraste `build/ios/ipa/focux_app.ipa`
3. Deliver

---

## Passo 6 — TestFlight interno (10 min)

1. App Store Connect → seu app → **TestFlight**
2. Preencha **Export Compliance** (geralmente "No" para criptografia padrão HTTPS)
3. **Internal Testing** → adicione você como tester
4. Instale pelo app **TestFlight** no iPhone

---

## Passo 7 — Submeter para review (quando estiver satisfeito)

1. App Store Connect → **App Store** tab
2. Screenshots (tamanhos em `APP_STORE_METADATA.md`)
3. Selecione o build do TestFlight
4. **Submit for Review**

---

## Troubleshooting

| Problema | Solução |
|----------|---------|
| IAP não valida | Confirme `FOCUX_IAP_APPLE_SHARED_SECRET` no Railway |
| Review account vazia | Confirme `FOCUX_REVIEW_ACCOUNT_PASSWORD` no Railway e reinicie deploy |
| Archive falha signing | Team ID no Xcode + ExportOptions.plist |
| Firebase warning no iOS | Opcional: adicione `ios/Runner/GoogleService-Info.plist` (veja `.example`) |

---

## Checklist final

- [ ] 6 IAPs criados no Connect
- [ ] Shared secret no Railway
- [ ] Review password no Railway
- [ ] VoiceOver nos 8 hubs
- [ ] IPA no TestFlight
- [ ] Screenshots + submit

**Próximo trimestre:** repetir apenas TalkBack + k6 + backup drill (`docs/MANUAL-TRIMESTRAL.md`).
