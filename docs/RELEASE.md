# Release nas lojas

Como uma versão do app sai para a App Store e o Google Play. Branches e fluxo diário em [`CONTRIBUTING.md`](../CONTRIBUTING.md).

## Versão

- A versão e o build ficam em `pubspec.yaml` (`version: 1.2.5+241`).
- Cada envio às lojas sobe a versão (`1.2.5` → `1.2.6`) e o build (`+241` → `+242`). Depois que a Apple aprova uma versão, ela fecha para envios novos: a recusa "train version is closed" quer dizer que falta subir a versão.
- Cada versão publicada ganha uma tag `vX.Y.Z` e uma seção no [`CHANGELOG.md`](../CHANGELOG.md).

## Passo a passo

1. Na `develop`: `dart analyze --fatal-warnings --fatal-infos lib test` e `flutter test --no-pub` verdes.
2. Suba a versão e o build no `pubspec.yaml` e feche a seção do `CHANGELOG.md`.
3. Mescle a `develop` na `main` e envie.
4. **iOS:** dispare o build e o envio ao TestFlight a partir da `main`:

   ```bash
   gh workflow run ios-release.yml --ref main -f upload_testflight=true
   ```

   O mesmo workflow sobe os símbolos (dSYM) para o Sentry. Para testar antes do lançamento, use `--ref develop`.
5. **Android:** gere o app bundle assinado (`flutter build appbundle`) com a chave de upload (`android/key.properties`, fora do Git) e envie ao Google Play Console.
6. Teste no aparelho pelo TestFlight e pela faixa de teste interno da Play antes de mandar para revisão.
7. Depois da aprovação: crie a tag `vX.Y.Z` na `main` e atualize a versão das lojas no mapa do projeto.

## Antes de enviar ao Google Play

- **Health Connect:** a declaração de permissões no Play Console não pode marcar HRV (`READ_HEART_RATE_VARIABILITY`), que foi recusada por escopo mínimo.
- **Chave de API do Firebase:** o `google-services.json` (fora do Git) e o `GoogleService-Info.plist` (secret `GOOGLE_SERVICE_INFO_PLIST_BASE64` do CI) levam a chave de API compilada no app. Rotação de chave no Google Cloud expira a anterior: baixe os dois arquivos de novo no Firebase e confira que a chave Android aceita os SHA-1 da assinatura da Play e de upload (Google Cloud > Credenciais > chave Android > Restrições). Chave expirada ou SHA-1 fora da lista = sem token do FCM e sem push (foi o caso da 1.2.5).
- **Login com Google:** toda troca de chave de assinatura ou de upload exige cadastrar o SHA-1 novo no Firebase no mesmo dia. Sem isso o Google devolve o erro 10 (`DEVELOPER_ERROR`). Não apague os SHA-1 antigos: Android abaixo do 13 ainda recebe o app assinado pela chave anterior.

## Depois do lançamento

- Quando a versão nova estiver aprovada nas duas lojas, suba `FOCUX_APP_VERSAO_RECOMENDADA_IOS` e `_ANDROID` na Railway: o app mostra a folha "Nova versão disponível" e o servidor manda o push uma vez por aparelho (na hora cheia seguinte, às :15). A mínima (`FOCUX_APP_VERSAO_MINIMA_*`) só sobe quando a versão antiga quebra de verdade.

- Acompanhe o Sentry (org `focux-personal`, projeto `flutter`). Travamento de tela aparece como "App Hang", sem mensagem do Dart; os breadcrumbs mostram as últimas telas e toques.
- O app publicado continua chamando a API por semanas. O backend só remove campo ou endpoint quando a versão nova já tiver a maioria dos usuários.

## Bug em produção

Crie `hotfix/<nome>` a partir da `main`, corrija com teste, suba versão e build, mescle na `main` e de volta na `develop`, e siga o passo a passo a partir do item 4.
