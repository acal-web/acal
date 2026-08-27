require "net/http"

module Devices
  # Sends a push notification to every device registered to an owner (User or
  # Customer) via Firebase Cloud Messaging's HTTP v1 API. Best-effort: any
  # failure (missing credentials, FCM error, network issue) is logged and
  # swallowed so it never interrupts the caller's flow (e.g. invoice generation).
  class SendPushService
    FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging"
    TOKEN_URL = "https://oauth2.googleapis.com/token"

    def self.call(owner:, title:, body:)
      new(owner:, title:, body:).call
    end

    def initialize(owner:, title:, body:)
      @owner = owner
      @title = title
      @body = body
    end

    def call
      return unless credentials
      return unless (token = access_token)

      Device.where(owner: @owner).where.not(push_token: [ nil, "" ]).find_each do |device|
        deliver(device, token)
      end
    rescue StandardError => e
      Rails.logger.error("[Devices::SendPushService] #{e.class}: #{e.message}")
    end

    private

    def deliver(device, token)
      uri = URI("https://fcm.googleapis.com/v1/projects/#{credentials[:project_id]}/messages:send")
      request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json", "Authorization" => "Bearer #{token}")
      request.body = { message: { token: device.push_token, notification: { title: @title, body: @body } } }.to_json

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
      Rails.logger.error("[Devices::SendPushService] FCM error for device #{device.id}: #{response.body}") unless response.is_a?(Net::HTTPSuccess)
    rescue StandardError => e
      Rails.logger.error("[Devices::SendPushService] #{e.class}: #{e.message}")
    end

    def access_token
      now = Time.current.to_i
      payload = {
        iss: credentials[:client_email],
        scope: FCM_SCOPE,
        aud: TOKEN_URL,
        iat: now,
        exp: now + 3600
      }
      assertion = JWT.encode(payload, OpenSSL::PKey::RSA.new(credentials[:private_key]), "RS256")

      response = Net::HTTP.post_form(URI(TOKEN_URL), grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion: assertion)
      JSON.parse(response.body)["access_token"]
    end

    # Rails credentials, added via `bin/rails credentials:edit`:
    #   firebase:
    #     project_id: acal-ff937
    #     client_email: firebase-adminsdk-xxxxx@acal-ff937.iam.gserviceaccount.com
    #     private_key: |
    #       -----BEGIN PRIVATE KEY-----
    #       ...
    #       -----END PRIVATE KEY-----
    # (from a Firebase service account: Project Settings > Service accounts > Generate new private key)
    def credentials
      Rails.application.credentials.firebase
    end
  end
end
