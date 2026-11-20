# Política de segurança

O app do Focux Personal está nas lojas e trata dado pessoal e dado de saúde de personais e alunos (LGPD). Segurança tem prioridade sobre qualquer funcionalidade.

## Como relatar uma vulnerabilidade

- Escreva para **contato@focuxpersonal.com** com o assunto `Segurança`.
- Descreva o problema, como reproduzir, a versão do app e o aparelho.
- **Não** abra issue, PR ou discussão com detalhes da falha: este repositório é público.
- **Não** teste contra contas de outras pessoas nem acesse dado que não seja seu.

O retorno vem pelo mesmo e-mail. Falha confirmada recebe correção com teste que prova o comportamento e sai pelo fluxo de hotfix (ver [`docs/RELEASE.md`](docs/RELEASE.md#bug-em-produção)).

## Versões atendidas

Só a versão publicada nas lojas (branch `main`) recebe correções de segurança.

## O que nunca entra no Git

- `.env*` (exceto `.env.local.example`), `key.properties`, keystores (`*.jks`, `*.keystore`, `*.p12`, `*.pem`).
- `google-services.json` e `GoogleService-Info.plist` reais (versione só os `*.example`).
- Chaves da Apple (`AuthKey_*.p8`), perfis de provisionamento e contas de serviço.
- `e2e/.auth/`, capturas e dumps de QA com dado pessoal.

Segredo encontrado no histórico é tratado como vazado: revogue no provedor, troque o valor e registre o incidente. Não faça `push --force` sem alinhamento.

## Controles automáticos

- `security.yml`: varredura de segredos (gitleaks) em todo push e PR.
- `semgrep.yml` e `codeql.yml`: análise estática.
- Dependabot: atualizações semanais do pub, do npm do E2E e das Actions.

## Dado pessoal no app

- Token só em secure storage; o logout apaga sessão, rascunhos, cache offline e vídeos guardados.
- Sentry sem corpo de requisição, sem argumentos de rota e sem token. Amplitude sem texto livre, e-mail ou token.
- Nenhum dado do aluno vai para a IA sem aceite registrado, revogável em Perfil > Privacidade.
