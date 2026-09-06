flutter clean 
flutter pub get


flutter build appbundle --release
flutter build apk --release
flutter build linux --release
./scripts/build_linux_appimage.sh


# Como rodar os testes

## 1. Testes da API (rspec)

Não precisa de nada rodando — ele mesmo sobe o banco.

```bash
cd api
RAILS_ENV=test bin/rails db:prepare          # só na primeira vez
bundle exec rspec                            # suíte completa
bundle exec rspec spec/requests/categories   # só um diretório
```

## 2. Testes de widget do app

Rápidos, sem backend.

```bash
cd app
flutter test
flutter analyze
```

## 3. E2E (integration_test + Patrol)

Roda o app de verdade (`main()`) contra uma API Rails de verdade, em
`RAILS_ENV=test`. Vive em `integration_test/`, com os helpers compartilhados em
`integration_test/support/`.

```bash
# terminal 1 — API de teste
cd api
RAILS_ENV=test bin/rails db:prepare
RAILS_ENV=test bin/rails users:create_e2e_admin
RAILS_ENV=test PORT=3000 bin/rails server

# terminal 2 — suíte
cd app
xvfb-run -a ./scripts/run_e2e.sh             # ou sem xvfb-run num desktop com tela
```

Um arquivo só:

```bash
flutter test integration_test/category/category_test.dart -d linux \
  --dart-define=API_BASE_URL=http://localhost:3000 \
  --dart-define=E2E_ADMIN_USERNAME=e2e_admin \
  --dart-define=E2E_ADMIN_PASSWORD=e2e_password123
```

Android (emulador — `10.0.2.2` é o alias do emulador pro localhost do host):

```bash
E2E_DEVICE=<emulator-id> API_BASE_URL=http://10.0.2.2:3000 ./scripts/run_e2e.sh
```

### Armadilhas

- **Use o `scripts/run_e2e.sh`, não `flutter test integration_test`.** Passar o
  diretório inteiro numa invocação só compila tudo, mas falha ao subir o app a
  partir do segundo arquivo (`The log reader stopped unexpectedly, or never
  started`) — o device de desktop só é derrubado entre execuções separadas. O
  script roda um `flutter test` por arquivo e junta o resultado no final.
- **`users:create_e2e_admin`, não `users:create_admin`.** A segunda bootstrapa a
  produção e desiste assim que a tabela tem qualquer usuário
  (`if User.count.zero?`); num banco novo o `db:prepare` roda o `db/seeds.rb`
  antes dela e já cria um usuário, então ela pula em silêncio e você fica sem o
  `e2e_admin`. O sintoma é *todos* os cenários falharem no `setUp`. A task nova
  é idempotente, chaveada pelo username, e só roda em `RAILS_ENV=test`. O
  preflight do `run_e2e.sh` detecta isso antes de compilar qualquer coisa.
- **Reinicie o Rails de verdade depois de mexer na API.** Em `RAILS_ENV=test`
  não há reload de classes, e se o processo antigo continuar vivo o novo falha
  na porta ocupada — sem barulho. Confira com `ps aux | grep puma`.

### Como o estado é limpo

Cada teste chama `POST /test/reset` (rota que só existe com `RAILS_ENV=test`):
loga como `e2e_admin`, apaga tudo — inclusive a linha do próprio admin — e o
recria com o mesmo token. A autorização da API é baseada só no `role` do JWT e
não recarrega o usuário do banco, então o token continua valendo depois do
reset. Por isso dá pra rodar a suíte quantas vezes quiser seguidas, sempre a
partir de um banco limpo, sem nenhum passo manual entre execuções.

O `bootApp` também apaga o token do `flutter_secure_storage` antes de cada
cenário. Sem isso, o token gravado pelo cenário anterior sobrevive ao reset e o
próximo teste começaria já logado, sem nunca ver a tela de login.

### Convenção de `Key`s

O E2E encontra os elementos por `Key`, não por texto ou posição. Ao cobrir uma
feature nova, instrumente seguindo o padrão que já existe:

| Onde | Key |
|---|---|
| Campo de formulário | `<feature>_form_<campo>_field` (ex.: `category_form_name_field`) |
| `FSelect` de formulário | `<feature>_form_<campo>_select` |
| Barra de filtros | `<feature>_filter_toggle`, `<feature>_filter_<campo>_field`, `<feature>_filter_search_button`, `<feature>_filter_clear_button` |
| Linha da tabela | `ValueKey('<feature>_row_<chave natural>')` — exposta por um helper na página, como `categoryRowKey` |
| Compartilhadas (já prontas) | `form_save_button`, `form_cancel_button`, `form_close_button`, `row_action_edit/delete/view/reactivate`, `delete_confirm_button`, `delete_cancel_button` |

### Notas de plataforma

- **Android**: rode num emulador API ≤ 32 (ou dê
  `adb shell pm grant <package> android.permission.POST_NOTIFICATIONS` antes)
  pra evitar o diálogo nativo de notificação interrompendo o teste — o app pede
  essa permissão assim que loga. Em Linux desktop isso não acontece: o registro
  de push faz early-return fora de Android.
- **Web e `patrol test`**: `flutter test` não roda integration_test em Chrome
  (não suportado pelo Flutter). `patrol test` também não roda em Linux — o
  automator nativo do Patrol só suporta Android/iOS/macOS. Por isso a suíte usa
  `patrolWidgetTest` (não `patrolTest`), que funciona em qualquer plataforma.
- **`flutter_secure_storage` em Linux** depende do libsecret; sem um keyring
  ativo ele falha em silêncio e o token simplesmente não persiste. A suíte
  funciona nos dois casos.
