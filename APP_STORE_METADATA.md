# Focux Personal — App Store Metadata

## App Name
Focux Personal — Gestão de Alunos

## Subtitle (30 chars)
Personal Trainer Inteligente

## Promotional Text (170 chars)
Gerencie seus alunos, treinos e finanças em um só lugar. IA integrada para progressão de carga e copiloto inteligente. O app mais completo para Personal Trainers do Brasil.

## Description
O Focux Personal é a plataforma completa para Personal Trainers que querem profissionalizar sua gestão e escalar seu negócio.

**Para o Personal Trainer:**
• Cadastre alunos ilimitados com perfil completo, anamnese e objetivos
• Monte treinos personalizados com biblioteca de exercícios e vídeos
• Acompanhe a evolução de cada aluno com métricas de aderência e check-ins
• Controle financeiro completo: mensalidades, inadimplência e relatórios
• IA Copiloto: gere treinos, dietas e insights automáticos baseados no histórico
• Progressão de carga inteligente com detecção automática de evolução
• Chat direto com alunos para comunicação rápida
• Perfil profissional público compartilhável na bio
• Agenda integrada com horários e compromissos
• Ranking de personais e gamificação para engajamento
• White-label: personalize cores e logo do seu negócio

**Para o Aluno:**
• Visualize seus treinos do dia com instruções detalhadas
• Faça check-in durante o treino e registre séries, cargas e repetições
• Acompanhe sua evolução com gráficos e recordes pessoais
• Receba notificações sobre novos treinos e mensagens do personal
• Conquiste badges e suba no ranking de consistência

**Diferenciais:**
✓ IA brasileira que entende treino
✓ Detecção automática de evolução de carga
✓ LGPD compliant com exportação e exclusão de dados
✓ Funciona offline para check-in
✓ Design premium e responsivo

Baixe agora e transforme sua carreira como Personal Trainer.

## Keywords (100 chars)
personal,trainer,treino,alunos,gestão,fitness,academia,exercício,dieta,IA,musculação,saúde,ficha

## Category
Health & Fitness

## Secondary Category
Productivity

## Privacy Policy URL
https://focuxpersonal.com/privacidade

## Terms of Service URL
https://focuxpersonal.com/termos

## Support URL
https://focux.app/suporte

## Marketing URL
https://focux.app

---

## App Store Review Notes

Demo Account for Review:
- Email: review@focux.app
- Password: set via `FOCUX_REVIEW_ACCOUNT_PASSWORD` on the backend (provide only in App Store Connect review notes, not in git).
- This account has pre-populated data: 3 students, 3 training programs, and 9 exercises.
- The app requires an internet connection to load data from the API.

In-App Purchases:
- Subscriptions use Flutter `in_app_purchase` (StoreKit / Google Play Billing).
- Product IDs (auto-renewing, criar todos no App Store Connect):
  - `focux_premium_monthly`, `focux_premium_yearly`
  - `focux_enterprise_monthly`, `focux_enterprise_yearly`
  - `focux_enterprise_pro_monthly`, `focux_enterprise_pro_yearly`
- Annual is the default offer in-app (−20% vs 12× monthly).
- Local StoreKit config for Xcode: `ios/Products.storekit`
- Server validates receipts via `POST /api/iap/verify`.
- Free tier includes up to 5 students.
- Premium and Enterprise unlock more students, AI, finance, white-label, etc.
- "Restore Purchases" is on the Paywall and Planos screens.
- No external payment links for digital subscriptions inside the iOS/Android app (Guideline 3.1.1).

Account Deletion:
- Available in Profile → Settings → "Excluir Conta"
- Complies with Apple's account deletion requirements
- Data is anonymized per LGPD regulations

## Screenshots Required
- iPhone 6.7" (iPhone 15 Pro Max): 1290 x 2796 px
- iPhone 5.5" (iPhone 8 Plus): 1242 x 2208 px

### Suggested Screenshots (6 screens):
1. Dashboard — Command Center with metrics
2. Alunos — Student list with status badges
3. Treino — Workout builder with exercises
4. Check-in — Live workout execution with timer
5. IA Copiloto — AI chat generating insights
6. Financeiro — Financial dashboard with charts
