flutter clean 
flutter pub get


flutter build appbundle --release
flutter build apk --release
flutter build linux --release
./scripts/build_linux_appimage.sh


# Como rodar os testes
1. Testes da API (rspec) — não precisa de nada rodando, ele mesmo sobe o banco:

cd api
RAILS_ENV=test bin/rails db:prepare      # só na primeira vez
bundle exec rspec                        # 408 exemplos, ~22s
bundle exec rspec spec/requests/categories   # só um diretório
2. Testes de widget do app — rápidos, sem backend:


cd app
flutter test          # 73 testes, ~4s
flutter analyze
3. E2E (Patrol) — precisa da API de teste no ar. Dois terminais:


# terminal 1 — API
cd api
RAILS_ENV=test bin/rails db:prepare
RAILS_ENV=test ACAL_ADMIN_USERNAME=e2e_admin ACAL_ADMIN_PASSWORD=e2e_password123 bin/rails users:create_admin
RAILS_ENV=test PORT=3000 bin/rails server

# terminal 2 — suíte
cd app
xvfb-run -a ./scripts/run_e2e.sh    # ~1min25s