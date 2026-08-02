# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Style: Ruby", "bin/rubocop"

  step "Security: Gem audit", "bin/bundler-audit"
  # Uses `bundle exec brakeman` instead of `bin/brakeman` because the binstub forces
  # `--ensure-latest`, which fails CI whenever a newer Brakeman gem is published,
  # regardless of whether the app code changed.
  step "Security: Brakeman code analysis", "bundle exec brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  step "Tests: RSpec", "bin/rails db:test:prepare && bundle exec rspec"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
