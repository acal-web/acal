---
name: rspec
description: Use when writing or reviewing RSpec specs in api/ (Rails). Conventions for structuring specs by success/error context and for asserting HTTP/JSON responses.
---

Conventions for RSpec specs in this repo's Rails API (`api/`). Follow these when writing new specs or reviewing existing ones.

## 1. Separate success and error cases into their own `context`

Every `describe` for an endpoint or method must split examples into a success context and an error (failure) context — never interleave them as flat `it` blocks. This keeps the happy path scannable and makes it obvious how many failure modes are covered.

```ruby
describe "POST /addresses" do
  context "when successful" do
    it "creates an address" do
      # ...
    end
  end

  context "when it fails" do
    it "rejects a request without a kind" do
      # ...
    end

    it "rejects a duplicate address" do
      # ...
    end
  end
end
```

Use `context "when successful"` / `context "when it fails"` as the default pair of names unless the domain suggests clearer ones (e.g. `context "when the address already exists"`). If there are multiple distinct failure reasons, each gets its own `it` inside the single error context — don't create one context per validation.

## 2. Assert HTTP responses with `eq` against the full body

Never spot-check individual keys with `response.parsed_body["field"]` plus `include`. Assert the *entire* parsed body with `eq`, so any unexpected/missing/extra field is caught immediately. For dynamic values (`id`, timestamps), pull them from the persisted record instead of hardcoding.

```ruby
it "creates an address" do
  expect {
    post "/addresses", params: valid_params
  }.to change(Address, :count).by(1)

  address = Address.last

  expect(response).to have_http_status(:created)
  expect(response.parsed_body).to eq(
    "id" => address.id,
    "kind" => "home",
    "name" => "Main Street",
    "created_at" => address.created_at.as_json,
    "updated_at" => address.updated_at.as_json,
    "deleted_at" => nil
  )
end
```

Same rule for error bodies — assert the full errors hash, not just `include` on one message:

```ruby
it "rejects a request without a kind" do
  post "/addresses", params: { address: valid_params[:address].except(:kind) }

  expect(response).to have_http_status(:unprocessable_content)
  expect(response.parsed_body).to eq("kind" => [ "can't be blank" ])
end
```

Watch out for validations that stack multiple messages on one field (e.g. presence + length both firing on a blank string) — run the request once and inspect `response.parsed_body` to get the exact array before hardcoding it, don't guess.

## Reference example

`api/spec/requests/addresses_spec.rb` is the canonical example of both rules applied together — use it as the template for new request specs.
