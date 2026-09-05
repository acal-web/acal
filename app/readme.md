flutter clean 
flutter pub get


flutter build appbundle --release
flutter build apk --release
flutter build linux --release

## Testes E2E (integration_test + Patrol)

1. Subir a API apontando pro banco de teste (`api_test`):
   ```bash
   cd ../api
   docker compose up -d db
   RAILS_ENV=test bin/rails db:prepare
   RAILS_ENV=test ACAL_ADMIN_USERNAME=e2e_admin ACAL_ADMIN_PASSWORD=e2e_password123 bin/rails users:create_admin
   RAILS_ENV=test PORT=3000 bin/rails server
   ```
   `users:create_admin` só faz alguma coisa se o banco estiver vazio (`if User.count.zero?`) — é só pra garantir que existe *algum* admin na primeiríssima vez. Não precisa rodar de novo entre execuções: o próprio teste se encarrega de limpar o banco (ver abaixo).

2. Rodar o teste:
   ```bash
   # Linux (desktop) — mais rápido pra rodar localmente, sem emulador
   flutter test integration_test/create_staff_user_test.dart -d linux \
     --dart-define=API_BASE_URL=http://localhost:3000 \
     --dart-define=E2E_ADMIN_USERNAME=e2e_admin \
     --dart-define=E2E_ADMIN_PASSWORD=e2e_password123

   # Android (emulador) — 10.0.2.2 é o alias do emulador pro localhost do host
   flutter test integration_test/create_staff_user_test.dart -d <emulator-id> \
     --dart-define=API_BASE_URL=http://10.0.2.2:3000 \
     --dart-define=E2E_ADMIN_USERNAME=e2e_admin \
     --dart-define=E2E_ADMIN_PASSWORD=e2e_password123
   ```

O próprio teste reseta o banco de teste antes de rodar, usando o endpoint test-only `POST /test/reset` (só existe com `RAILS_ENV=test`): loga como `e2e_admin`, chama o reset (apaga tudo, inclusive o próprio admin) e recria o admin com o mesmo token — a autorização da API é baseada só no `role` do JWT, não recarrega o usuário do banco, então o token continua valendo mesmo depois do reset apagar a linha dele. Por isso dá pra rodar o teste quantas vezes quiser seguidas, sempre a partir de um banco limpo, sem nenhum passo manual entre execuções.

**No Android**: rode num emulador API ≤ 32 (ou dê `adb shell pm grant <package> android.permission.POST_NOTIFICATIONS` antes) pra evitar o diálogo nativo de notificação interrompendo o teste — o app pede essa permissão assim que loga.

**Web e `patrol test`**: `flutter test` não roda integration_test em Chrome (não suportado pelo Flutter). `patrol test` também não roda em Linux — o automator nativo do Patrol só suporta Android/iOS/macOS, por isso este teste usa `patrolWidgetTest` (não `patrolTest`), que funciona em qualquer plataforma.