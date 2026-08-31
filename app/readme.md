flutter clean 
flutter pub get



flutter build appbundle --release
flutter build apk --release

## Testes E2E (integration_test + Patrol)

1. Subir a API apontando pro banco de teste (`api_test`), com um admin fixo:
   ```bash
   cd ../api
   docker compose up -d db
   RAILS_ENV=test bin/rails db:prepare
   RAILS_ENV=test ACAL_ADMIN_USERNAME=e2e_admin ACAL_ADMIN_PASSWORD=e2e_password123 bin/rails users:create_admin
   RAILS_ENV=test PORT=3000 bin/rails server
   ```
   (rode `RAILS_ENV=test bin/rails test:reset_db` antes do `create_admin` se quiser começar do zero — atenção: apaga tudo no `api_test`, inclusive o admin.)

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

Cada teste gera um usuário com nome único e remove ele no final (`DELETE /users/:id`), então dá pra rodar várias vezes seguidas sem resetar o banco.

**No Android**: rode num emulador API ≤ 32 (ou dê `adb shell pm grant <package> android.permission.POST_NOTIFICATIONS` antes) pra evitar o diálogo nativo de notificação interrompendo o teste — o app pede essa permissão assim que loga.

**Web e `patrol test`**: `flutter test` não roda integration_test em Chrome (não suportado pelo Flutter). `patrol test` também não roda em Linux — o automator nativo do Patrol só suporta Android/iOS/macOS, por isso este teste usa `patrolWidgetTest` (não `patrolTest`), que funciona em qualquer plataforma.