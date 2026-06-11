# Auditoria manual trimestral (app)

O guia completo dos 3 itens está no monorepo: veja também `focux-backend/docs/MANUAL-TRIMESTRAL.md`.

## Item deste repo: TalkBack / VoiceOver

Teste manual de leitor de tela nos **8 hubs** do personal. Os testes automáticos (`a11y_controls_contract_test`) já passam no CI — este passo confirma a experiência real.

### Rotas

1. `/login`
2. Dashboard (home após login)
3. `/alunos`
4. `/treinos`
5. `/financeiro`
6. `/chat/inbox`
7. `/checkin/treinos`
8. `/suporte`

### Como fazer (resumo)

1. Ative TalkBack (Android) ou VoiceOver (iOS).
2. Login como personal de teste.
3. Visite cada rota; swipe para ouvir cada elemento.
4. Anote botões sem nome e ordem estranha.

Abra issue: **GitHub → New Issue → "Auditoria trimestral — TalkBack/VoiceOver"**.

**Tempo:** ~30 min.
